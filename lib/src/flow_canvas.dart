import 'dart:math' as math;
import 'dart:ui' show Tangent;

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'flow_controller.dart';
import 'flow_models.dart';

class FlowCanvas extends StatefulWidget {
  const FlowCanvas({
    super.key,
    required this.controller,
    this.showPalette = true,
    this.showInspector = true,
    this.minScale = 0.35,
    this.maxScale = 2.5,
  });

  final FlowController controller;
  final bool showPalette;
  final bool showInspector;
  final double minScale;
  final double maxScale;

  @override
  State<FlowCanvas> createState() => _FlowCanvasState();
}

class _FlowCanvasState extends State<FlowCanvas> {
  Offset _pan = const Offset(80, 80);
  double _scale = 1;
  bool _paletteOpen = false;
  final _surfaceKey = GlobalKey();
  final _draggedNode = ValueNotifier<_DraggedNode?>(null);
  final _edgeDrag = ValueNotifier<_EdgeDragSession?>(null);

  FlowController get controller => widget.controller;

  Offset _toScene(Offset screen) => (screen - _pan) / _scale;

  Offset? _portPosition(
    FlowPortRef ref, {
    _DraggedNode? draggedNode,
  }) {
    final node = controller.nodeById(ref.nodeId);
    final definition =
        node == null ? null : controller.definitionFor(node.type);
    final port = definition?.port(ref.portId);
    if (node == null || definition == null || port == null) return null;

    final ports = [...definition.inputs, ...definition.outputs]
        .where((candidate) => candidate.side == port.side)
        .toList();
    final index = ports.indexWhere((candidate) => candidate.id == port.id);
    final fraction = (index + 1) / (ports.length + 1);
    final position =
        draggedNode?.nodeId == node.id ? draggedNode!.position : node.position;
    return _nodePortPosition(node, port.side, fraction, position: position);
  }

  void _onScroll(PointerScrollEvent event) {
    final oldScale = _scale;
    final nextScale = (_scale * math.exp(-event.scrollDelta.dy * 0.0015))
        .clamp(widget.minScale, widget.maxScale);
    if (oldScale == nextScale) return;
    setState(() {
      _scale = nextScale;
      _pan = event.localPosition -
          (event.localPosition - _pan) * (nextScale / oldScale);
    });
  }

  void _resetViewport() => setState(() {
        _pan = const Offset(80, 80);
        _scale = 1;
      });

  @override
  void dispose() {
    _draggedNode.dispose();
    _edgeDrag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final showDockedPalette =
                widget.showPalette && availableWidth >= 720;
            final showDockedInspector =
                widget.showInspector && availableWidth >= 1120;
            return Stack(
              children: [
                Positioned.fill(
                  left: showDockedPalette ? 252 : 0,
                  right: showDockedInspector ? 308 : 0,
                  child: _buildSurface(
                    showPaletteOverlay:
                        widget.showPalette && !showDockedPalette,
                    showInspectorOverlay:
                        widget.showInspector && !showDockedInspector,
                  ),
                ),
                if (showDockedInspector)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 308,
                    child: _InspectorPanel(controller: controller),
                  ),
                if (showDockedPalette)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 252,
                    child: _PalettePanel(controller: controller),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSurface({
    required bool showPaletteOverlay,
    required bool showInspectorOverlay,
  }) {
    return DragTarget<String>(
      key: _surfaceKey,
      onAcceptWithDetails: (details) {
        final box = _surfaceKey.currentContext!.findRenderObject() as RenderBox;
        controller.addNode(
            details.data, _toScene(box.globalToLocal(details.offset)));
      },
      builder: (context, _, __) {
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) _onScroll(event);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => controller.selectNode(null),
                onPanUpdate: (details) => setState(() => _pan += details.delta),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _GridPainter(pan: _pan, scale: _scale),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: ValueListenableBuilder<_DraggedNode?>(
                    valueListenable: _draggedNode,
                    builder: (context, draggedNode, _) {
                      return ValueListenableBuilder<_EdgeDragSession?>(
                        valueListenable: _edgeDrag,
                        builder: (context, edgeDrag, _) {
                          return CustomPaint(
                            painter: _EdgePainter(
                              graph: controller.graph,
                              definitions: controller.definitions,
                              pan: _pan,
                              scale: _scale,
                              draggedNode: draggedNode,
                              hiddenEdgeId: edgeDrag?.replacingEdgeId,
                              connectingStart: edgeDrag == null
                                  ? null
                                  : _portPosition(edgeDrag.source,
                                      draggedNode: draggedNode),
                              connectingEnd: edgeDrag?.end,
                              showConnectingArrow:
                                  edgeDrag?.replacingEdgeId == null,
                            ),
                            child: const SizedBox.expand(),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            for (final node in controller.graph.nodes)
              _NodeCard(
                key: ValueKey(node.id),
                node: node,
                definition: controller.definitionFor(node.type),
                selected: node.id == controller.selectedNodeId,
                scale: _scale,
                pan: _pan,
                onMove: (position) =>
                    _draggedNode.value = _DraggedNode(node.id, position),
                onMoveEnd: (position) {
                  _draggedNode.value = null;
                  controller.moveNode(node.id, position);
                },
                onSelect: () => controller.selectNode(node.id),
                onDelete: () => controller.removeNode(node.id),
                onStartConnection: _startNewEdge,
                onConnectionMove: (globalPosition) {
                  final box = _surfaceKey.currentContext!.findRenderObject()
                      as RenderBox;
                  final edgeDrag = _edgeDrag.value;
                  if (edgeDrag != null) {
                    _edgeDrag.value = edgeDrag.copyWith(
                      end: _toScene(box.globalToLocal(globalPosition)),
                    );
                  }
                },
                onEndConnection: _completeConnection,
                onCancelConnection: () => _edgeDrag.value = null,
              ),
            for (final edge in controller.graph.edges)
              ValueListenableBuilder<_DraggedNode?>(
                valueListenable: _draggedNode,
                builder: (context, draggedNode, _) {
                  return ValueListenableBuilder<_EdgeDragSession?>(
                    valueListenable: _edgeDrag,
                    builder: (context, edgeDrag, _) {
                      final endpoint = edgeDrag?.replacingEdgeId == edge.id
                          ? _reconnectingEndpoint(edge, edgeDrag!, draggedNode)
                          : _edgeEndpoint(edge, draggedNode);
                      if (endpoint == null) return const SizedBox.shrink();
                      return _EdgeReconnectHandle(
                        key: ValueKey('flow-edge-target-${edge.id}'),
                        position: endpoint.position,
                        angle: endpoint.angle,
                        onStart: () => _startReconnect(edge),
                        onMove: _updateEdgeDrag,
                        onEnd: _completeConnection,
                        onCancel: () => _edgeDrag.value = null,
                      );
                    },
                  );
                },
              ),
            Positioned(
              right: 16,
              bottom: 16,
              child: _CanvasToolbar(
                scale: _scale,
                onZoomIn: () => _zoomAtCenter(1.15),
                onZoomOut: () => _zoomAtCenter(1 / 1.15),
                onReset: _resetViewport,
              ),
            ),
            if (showPaletteOverlay)
              Positioned(
                left: 16,
                top: 16,
                child: Tooltip(
                  message: 'Components',
                  child: IconButton.filledTonal(
                    onPressed: () => setState(() => _paletteOpen = true),
                    icon: const Icon(Icons.account_tree_outlined),
                  ),
                ),
              ),
            if (showInspectorOverlay && controller.selectedNode != null)
              Positioned(
                left: 16,
                top: 64,
                child: Tooltip(
                  message: 'Configure selected node',
                  child: IconButton.filledTonal(
                    onPressed: () => _showInspectorSheet(context),
                    icon: const Icon(Icons.tune_outlined),
                  ),
                ),
              ),
            if (showPaletteOverlay && _paletteOpen)
              Positioned.fill(
                child: Material(
                  color: const Color(0xDDF7FAFC),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: 'Close components',
                            onPressed: () =>
                                setState(() => _paletteOpen = false),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                        Expanded(child: _PalettePanel(controller: controller)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _startNewEdge(FlowPortRef source) {
    _edgeDrag.value = _EdgeDragSession(
      source: source,
      end: _portPosition(source) ?? Offset.zero,
    );
  }

  void _startReconnect(FlowEdge edge) {
    _edgeDrag.value = _EdgeDragSession(
      source: edge.source,
      end: _portPosition(edge.target) ?? Offset.zero,
      replacingEdgeId: edge.id,
    );
  }

  void _updateEdgeDrag(Offset globalPosition) {
    final edgeDrag = _edgeDrag.value;
    if (edgeDrag == null) return;
    final box = _surfaceKey.currentContext!.findRenderObject() as RenderBox;
    _edgeDrag.value = edgeDrag.copyWith(
      end: _toScene(box.globalToLocal(globalPosition)),
    );
  }

  void _completeConnection(Offset globalPosition) {
    final edgeDrag = _edgeDrag.value;
    if (edgeDrag == null) return;

    final box = _surfaceKey.currentContext!.findRenderObject() as RenderBox;
    final target = _inputPortAt(
      _toScene(box.globalToLocal(globalPosition)),
    );
    _edgeDrag.value = null;
    if (target == null) {
      _showConnectionIssue('Drop the edge on an input port.');
      return;
    }

    final validation = controller.validateConnection(
      edgeDrag.source,
      target,
      replacingEdgeId: edgeDrag.replacingEdgeId,
    );
    if (!validation.isValid) {
      _showConnectionIssue(validation.issue!.message);
      return;
    }

    if (edgeDrag.replacingEdgeId != null) {
      controller.reconnectEdgeTarget(edgeDrag.replacingEdgeId!, target);
    } else {
      controller.connect(edgeDrag.source, target);
    }
  }

  void _showConnectionIssue(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  FlowPortRef? _inputPortAt(Offset scenePosition) {
    final hitRadius = 18 / _scale;
    for (final node in controller.graph.nodes.reversed) {
      final definition = controller.definitionFor(node.type);
      if (definition == null) continue;
      final allPorts = [...definition.inputs, ...definition.outputs];
      for (final input in definition.inputs) {
        final sidePorts =
            allPorts.where((port) => port.side == input.side).toList();
        final index = sidePorts.indexWhere((port) => port.id == input.id);
        final portPosition = _nodePortPosition(
          node,
          input.side,
          (index + 1) / (sidePorts.length + 1),
        );
        final target = FlowPortRef(node.id, input.id);
        if ((portPosition - scenePosition).distance <= hitRadius) {
          return target;
        }
      }
    }
    return null;
  }

  _EdgeEndpoint? _edgeEndpoint(FlowEdge edge, _DraggedNode? draggedNode) {
    final target = _portPosition(edge.target, draggedNode: draggedNode);
    final source = _portPosition(edge.source, draggedNode: draggedNode);
    final sourcePort = controller.portFor(edge.source);
    final targetPort = controller.portFor(edge.target);
    if (target == null ||
        source == null ||
        sourcePort == null ||
        targetPort == null) {
      return null;
    }

    final path = _connectionPath(
      source * _scale + _pan,
      target * _scale + _pan,
      sourcePort.side,
      targetPort.side,
    );
    final metric = path.computeMetrics().first;
    final tangent =
        metric.getTangentForOffset(math.max(0, metric.length - 0.5));
    if (tangent == null) return null;
    return _EdgeEndpoint(target * _scale + _pan, tangent.vector.direction);
  }

  _EdgeEndpoint? _reconnectingEndpoint(
    FlowEdge edge,
    _EdgeDragSession session,
    _DraggedNode? draggedNode,
  ) {
    final source = _portPosition(session.source, draggedNode: draggedNode);
    final sourcePort = controller.portFor(edge.source);
    if (source == null || sourcePort == null) return null;

    final start = source * _scale + _pan;
    final end = session.end * _scale + _pan;
    final path = _connectionPath(
      start,
      end,
      sourcePort.side,
      FlowPortSide.left,
    );
    final metric = path.computeMetrics().first;
    final tangent =
        metric.getTangentForOffset(math.max(0, metric.length - 0.5));
    return _EdgeEndpoint(end, tangent?.vector.direction ?? 0);
  }

  void _zoomAtCenter(double multiplier) {
    final oldScale = _scale;
    final newScale =
        (_scale * multiplier).clamp(widget.minScale, widget.maxScale);
    final center = const Offset(400, 300);
    setState(() {
      _scale = newScale;
      _pan = center - (center - _pan) * (newScale / oldScale);
    });
  }

  void _showInspectorSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: _InspectorPanel(controller: controller),
        ),
      ),
    );
  }
}

class _PalettePanel extends StatelessWidget {
  const _PalettePanel({required this.controller});

  final FlowController controller;

  @override
  Widget build(BuildContext context) {
    final definitions = controller.definitions.toList(growable: false);
    return SizedBox(
      width: 252,
      child: Material(
        color: const Color(0xFFF7FAFC),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 22, 8, 12),
              child: Text(
                'COMPONENTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Color(0xFF52616B),
                ),
              ),
            ),
            for (final definition in definitions)
              _PaletteItem(definition: definition),
            if (definitions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No components are registered.',
                    style: TextStyle(color: Color(0xFF71808A))),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaletteItem extends StatelessWidget {
  const _PaletteItem({required this.definition});

  final FlowNodeDefinition definition;

  @override
  Widget build(BuildContext context) {
    final preview = Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD9E1E7)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: definition.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: definition.palettePreviewBuilder?.call(context) ??
                  Icon(definition.icon,
                      color: definition.accentColor, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(definition.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15232C))),
                  const SizedBox(height: 2),
                  Text(definition.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF667985))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Draggable<String>(
        data: definition.type,
        feedback:
            SizedBox(width: 228, child: Opacity(opacity: 0.86, child: preview)),
        childWhenDragging: Opacity(opacity: 0.35, child: preview),
        child: preview,
      ),
    );
  }
}

class _InspectorPanel extends StatelessWidget {
  const _InspectorPanel({required this.controller});

  final FlowController controller;

  @override
  Widget build(BuildContext context) {
    final node = controller.selectedNode;
    final definition =
        node == null ? null : controller.definitionFor(node.type);
    final configuration = node == null || definition == null
        ? null
        : definition.configurationBuilder?.call(
            context,
            node,
            (data) => controller.updateNodeData(node.id, data),
          );
    return Container(
      width: 308,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(left: BorderSide(color: Color(0xFFD9E1E7))),
      ),
      child: node == null || definition == null
          ? const Center(
              child: Text('Select a component to configure it',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF71808A))),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 14, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(definition.title,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15232C))),
                            const SizedBox(height: 3),
                            Text(definition.description,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF667985))),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete node',
                        onPressed: () => controller.removeNode(node.id),
                        icon: const Icon(Icons.delete_outline,
                            color: Color(0xFFC9414A)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: KeyedSubtree(
                      key: ValueKey(node.id),
                      child: configuration ??
                          const Text('This component has no configuration.',
                              style: TextStyle(color: Color(0xFF71808A))),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _NodeCard extends StatefulWidget {
  const _NodeCard({
    super.key,
    required this.node,
    required this.definition,
    required this.selected,
    required this.scale,
    required this.pan,
    required this.onMove,
    required this.onMoveEnd,
    required this.onSelect,
    required this.onDelete,
    required this.onStartConnection,
    required this.onConnectionMove,
    required this.onEndConnection,
    required this.onCancelConnection,
  });

  final FlowNode node;
  final FlowNodeDefinition? definition;
  final bool selected;
  final double scale;
  final Offset pan;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Offset> onMoveEnd;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final ValueChanged<FlowPortRef> onStartConnection;
  final ValueChanged<Offset> onConnectionMove;
  final ValueChanged<Offset> onEndConnection;
  final VoidCallback onCancelConnection;

  @override
  State<_NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends State<_NodeCard> {
  late Offset _position;

  FlowNode get node => widget.node;
  FlowNodeDefinition? get definition => widget.definition;
  bool get selected => widget.selected;
  double get scale => widget.scale;
  Offset get pan => widget.pan;
  ValueChanged<Offset> get onMove => widget.onMove;
  ValueChanged<Offset> get onMoveEnd => widget.onMoveEnd;
  VoidCallback get onSelect => widget.onSelect;
  VoidCallback get onDelete => widget.onDelete;
  ValueChanged<FlowPortRef> get onStartConnection => widget.onStartConnection;
  ValueChanged<Offset> get onConnectionMove => widget.onConnectionMove;
  ValueChanged<Offset> get onEndConnection => widget.onEndConnection;
  VoidCallback get onCancelConnection => widget.onCancelConnection;

  @override
  void initState() {
    super.initState();
    _position = node.position;
  }

  @override
  void didUpdateWidget(covariant _NodeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.position != node.position) {
      _position = node.position;
    }
  }

  @override
  Widget build(BuildContext context) {
    final definition = this.definition;
    if (definition == null) return const SizedBox.shrink();
    final showInputLabels = scale >= 0.65 &&
        definition.inputs.any((port) => port.side == FlowPortSide.left);
    final contentLeftInset = showInputLabels ? 68 * scale : 12 * scale;
    return Positioned(
      left: _position.dx * scale + pan.dx,
      top: _position.dy * scale + pan.dy,
      child: RepaintBoundary(
        child: SizedBox(
          width: node.size.width * scale,
          height: node.size.height * scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.white,
                elevation: selected ? 8 : 2,
                shadowColor: const Color(0x3315232C),
                borderRadius: BorderRadius.circular(6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected
                          ? definition.accentColor
                          : const Color(0xFFD5DEE5),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        key: ValueKey('flow-node-drag-${node.id}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: onSelect,
                        onPanStart: (_) => onSelect(),
                        onPanUpdate: (details) {
                          setState(() {
                            _position += details.delta / scale;
                          });
                          onMove(_position);
                        },
                        onPanEnd: (_) => onMoveEnd(_position),
                        onPanCancel: () => onMoveEnd(_position),
                        child: Container(
                          height: 39 * scale,
                          padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                          decoration: BoxDecoration(
                            color:
                                definition.accentColor.withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(5)),
                          ),
                          child: Row(
                            children: [
                              Icon(definition.icon,
                                  size: 16 * scale,
                                  color: definition.accentColor),
                              SizedBox(width: 7 * scale),
                              Expanded(
                                child: Text(definition.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 13 * scale,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF15232C))),
                              ),
                              if (selected)
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints.tightFor(
                                      width: 24 * scale, height: 24 * scale),
                                  tooltip: 'Delete node',
                                  onPressed: onDelete,
                                  icon: Icon(Icons.close,
                                      size: 16 * scale,
                                      color: const Color(0xFF8A3E45)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: onSelect,
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(5)),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              contentLeftInset,
                              12 * scale,
                              12 * scale,
                              12 * scale,
                            ),
                            child: DefaultTextStyle.merge(
                              style: TextStyle(fontSize: 12 * scale),
                              child: definition.canvasBuilder
                                      ?.call(context, node) ??
                                  Text(definition.description,
                                      style: const TextStyle(
                                          color: Color(0xFF60737E))),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showInputLabels)
                for (final port in definition.inputs
                    .where((port) => port.side == FlowPortSide.left))
                  _buildInputPortLabel(port, definition),
              for (final port in [...definition.inputs, ...definition.outputs])
                _buildPort(port, definition),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputPortLabel(
    FlowPort port,
    FlowNodeDefinition definition,
  ) {
    final sidePorts = [...definition.inputs, ...definition.outputs]
        .where((candidate) => candidate.side == port.side)
        .toList();
    final index = sidePorts.indexWhere((candidate) => candidate.id == port.id);
    final fraction = (index + 1) / (sidePorts.length + 1);
    return Positioned(
      left: 12 * scale,
      top: node.size.height * scale * fraction - 7 * scale,
      child: IgnorePointer(
        child: SizedBox(
          width: 50 * scale,
          child: Text(
            port.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9 * scale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF60737E),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPort(FlowPort port, FlowNodeDefinition definition) {
    final all = [...definition.inputs, ...definition.outputs]
        .where((candidate) => candidate.side == port.side)
        .toList();
    final index = all.indexWhere((candidate) => candidate.id == port.id);
    final fraction = (index + 1) / (all.length + 1);
    final handle = 16.0 * scale;
    const hitPadding = 6.0;
    final width = node.size.width * scale;
    final height = node.size.height * scale;
    final color = port.color ?? definition.accentColor;
    final ref = FlowPortRef(node.id, port.id);

    final left = switch (port.side) {
      FlowPortSide.left => -handle / 2,
      FlowPortSide.right => width - handle / 2,
      FlowPortSide.top || FlowPortSide.bottom => width * fraction - handle / 2,
    };
    final top = switch (port.side) {
      FlowPortSide.top => -handle / 2,
      FlowPortSide.bottom => height - handle / 2,
      FlowPortSide.left || FlowPortSide.right => height * fraction - handle / 2,
    };
    return Positioned(
      left: left - hitPadding,
      top: top - hitPadding,
      child: _PortHandle(
        key: ValueKey('flow-port-${node.id}-${port.id}'),
        ref: ref,
        port: port,
        color: color,
        size: handle,
        onStartConnection: onStartConnection,
        onConnectionMove: onConnectionMove,
        onEndConnection: onEndConnection,
        onCancelConnection: onCancelConnection,
      ),
    );
  }
}

class _PortHandle extends StatefulWidget {
  const _PortHandle({
    super.key,
    required this.ref,
    required this.port,
    required this.color,
    required this.size,
    required this.onStartConnection,
    required this.onConnectionMove,
    required this.onEndConnection,
    required this.onCancelConnection,
  });

  final FlowPortRef ref;
  final FlowPort port;
  final Color color;
  final double size;
  final ValueChanged<FlowPortRef> onStartConnection;
  final ValueChanged<Offset> onConnectionMove;
  final ValueChanged<Offset> onEndConnection;
  final VoidCallback onCancelConnection;

  @override
  State<_PortHandle> createState() => _PortHandleState();
}

class _PortHandleState extends State<_PortHandle> {
  Offset? _lastPointerPosition;

  @override
  Widget build(BuildContext context) {
    final dot = Tooltip(
      message: '${widget.port.label} (${widget.port.dataType.name})',
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.port.kind == FlowPortKind.output
              ? widget.color
              : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: widget.color, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x220A2735), blurRadius: 3)],
        ),
      ),
    );
    if (widget.port.kind == FlowPortKind.output) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          _lastPointerPosition = details.globalPosition;
          widget.onStartConnection(widget.ref);
        },
        onPanUpdate: (details) {
          _lastPointerPosition = details.globalPosition;
          widget.onConnectionMove(details.globalPosition);
        },
        onPanEnd: (_) {
          final position = _lastPointerPosition;
          _lastPointerPosition = null;
          if (position == null) {
            widget.onCancelConnection();
          } else {
            widget.onEndConnection(position);
          }
        },
        onPanCancel: () {
          _lastPointerPosition = null;
          widget.onCancelConnection();
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: dot,
          ),
        ),
      );
    }
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: dot,
      ),
    );
  }
}

class _CanvasToolbar extends StatelessWidget {
  const _CanvasToolbar({
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 38,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                tooltip: 'Zoom out',
                onPressed: onZoomOut,
                icon: const Icon(Icons.remove)),
            SizedBox(
              width: 44,
              child: Text('${(scale * 100).round()}%',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF52616B))),
            ),
            IconButton(
                tooltip: 'Zoom in',
                onPressed: onZoomIn,
                icon: const Icon(Icons.add)),
            const VerticalDivider(width: 1),
            IconButton(
              tooltip: 'Reset view',
              onPressed: onReset,
              icon: const Icon(Icons.center_focus_strong_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _EdgeReconnectHandle extends StatefulWidget {
  const _EdgeReconnectHandle({
    super.key,
    required this.position,
    required this.angle,
    required this.onStart,
    required this.onMove,
    required this.onEnd,
    required this.onCancel,
  });

  final Offset position;
  final double angle;
  final VoidCallback onStart;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Offset> onEnd;
  final VoidCallback onCancel;

  @override
  State<_EdgeReconnectHandle> createState() => _EdgeReconnectHandleState();
}

class _EdgeReconnectHandleState extends State<_EdgeReconnectHandle> {
  Offset? _lastPointerPosition;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 14,
      top: widget.position.dy - 14,
      child: Tooltip(
        message: 'Drag to reconnect edge',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _lastPointerPosition = details.globalPosition;
            widget.onStart();
          },
          onPanUpdate: (details) {
            _lastPointerPosition = details.globalPosition;
            widget.onMove(details.globalPosition);
          },
          onPanEnd: (_) {
            final position = _lastPointerPosition;
            _lastPointerPosition = null;
            if (position == null) {
              widget.onCancel();
            } else {
              widget.onEnd(position);
            }
          },
          onPanCancel: () {
            _lastPointerPosition = null;
            widget.onCancel();
          },
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: Transform.rotate(
                angle: widget.angle,
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 17, color: Color(0xFF406477)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.pan, required this.scale});

  final Offset pan;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFFDFEFE), BlendMode.src);
    final grid = 24.0;
    final minor = Paint()
      ..color = const Color(0xFFECF1F4)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = const Color(0xFFDCE5EA)
      ..strokeWidth = 1;
    final minX = -pan.dx / scale;
    final maxX = (size.width - pan.dx) / scale;
    final minY = -pan.dy / scale;
    final maxY = (size.height - pan.dy) / scale;
    final startX = (minX / grid).floor() * grid;
    final startY = (minY / grid).floor() * grid;
    for (var x = startX; x <= maxX; x += grid) {
      final sx = x * scale + pan.dx;
      canvas.drawLine(Offset(sx, 0), Offset(sx, size.height),
          ((x / grid).round() % 5 == 0) ? major : minor);
    }
    for (var y = startY; y <= maxY; y += grid) {
      final sy = y * scale + pan.dy;
      canvas.drawLine(Offset(0, sy), Offset(size.width, sy),
          ((y / grid).round() % 5 == 0) ? major : minor);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.pan != pan || oldDelegate.scale != scale;
}

class _EdgePainter extends CustomPainter {
  const _EdgePainter({
    required this.graph,
    required this.definitions,
    required this.pan,
    required this.scale,
    this.draggedNode,
    this.hiddenEdgeId,
    this.connectingStart,
    this.connectingEnd,
    this.showConnectingArrow = true,
  });

  final FlowGraph graph;
  final Iterable<FlowNodeDefinition> definitions;
  final Offset pan;
  final double scale;
  final _DraggedNode? draggedNode;
  final String? hiddenEdgeId;
  final Offset? connectingStart;
  final Offset? connectingEnd;
  final bool showConnectingArrow;

  FlowNodeDefinition? _definition(String type) {
    for (final definition in definitions) {
      if (definition.type == type) return definition;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in graph.edges) {
      if (edge.id == hiddenEdgeId) continue;
      final source = _endpoint(edge.source);
      final target = _endpoint(edge.target);
      if (source != null && target != null) {
        _drawEdge(canvas, source.$1, target.$1, source.$2, target.$2);
      }
    }
    if (connectingStart != null && connectingEnd != null) {
      _drawEdge(canvas, connectingStart!, connectingEnd!, FlowPortSide.right,
          FlowPortSide.left,
          dashed: true,
          color: const Color(0xFF4F7CAC),
          drawArrow: showConnectingArrow);
    }
  }

  (Offset, FlowPortSide)? _endpoint(FlowPortRef ref) {
    final node = graph.nodes.where((node) => node.id == ref.nodeId).firstOrNull;
    final definition = node == null ? null : _definition(node.type);
    final port = definition?.port(ref.portId);
    if (node == null || definition == null || port == null) return null;
    final ports = [...definition.inputs, ...definition.outputs]
        .where((candidate) => candidate.side == port.side)
        .toList();
    final index = ports.indexWhere((candidate) => candidate.id == port.id);
    final fraction = (index + 1) / (ports.length + 1);
    final position =
        draggedNode?.nodeId == node.id ? draggedNode!.position : node.position;
    return (
      _nodePortPosition(node, port.side, fraction, position: position),
      port.side,
    );
  }

  void _drawEdge(
    Canvas canvas,
    Offset source,
    Offset target,
    FlowPortSide sourceSide,
    FlowPortSide targetSide, {
    bool dashed = false,
    Color color = const Color(0xFF406477),
    bool drawArrow = true,
  }) {
    final start = source * scale + pan;
    final end = target * scale + pan;
    final path = _connectionPath(start, end, sourceSide, targetSide);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = dashed ? 1.6 : 2.2
      ..strokeCap = StrokeCap.round;
    if (dashed) {
      for (final metric in path.computeMetrics()) {
        for (var distance = 0.0; distance < metric.length; distance += 9) {
          canvas.drawPath(
              metric.extractPath(
                  distance, math.min(distance + 5, metric.length)),
              paint);
        }
      }
      final metric = path.computeMetrics().first;
      final tangent =
          metric.getTangentForOffset(math.max(0, metric.length - 1));
      if (drawArrow && tangent != null) _drawArrow(canvas, tangent, color);
    } else {
      canvas.drawPath(path, paint);
      final metric = path.computeMetrics().first;
      final tangent =
          metric.getTangentForOffset(math.max(0, metric.length - 1));
      if (drawArrow && tangent != null) _drawArrow(canvas, tangent, color);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) =>
      oldDelegate.graph != graph ||
      oldDelegate.pan != pan ||
      oldDelegate.scale != scale ||
      oldDelegate.draggedNode != draggedNode ||
      oldDelegate.hiddenEdgeId != hiddenEdgeId ||
      oldDelegate.connectingStart != connectingStart ||
      oldDelegate.connectingEnd != connectingEnd ||
      oldDelegate.showConnectingArrow != showConnectingArrow;
}

class _DraggedNode {
  const _DraggedNode(this.nodeId, this.position);

  final String nodeId;
  final Offset position;
}

class _EdgeDragSession {
  const _EdgeDragSession({
    required this.source,
    required this.end,
    this.replacingEdgeId,
  });

  final FlowPortRef source;
  final Offset end;
  final String? replacingEdgeId;

  _EdgeDragSession copyWith({Offset? end}) => _EdgeDragSession(
        source: source,
        end: end ?? this.end,
        replacingEdgeId: replacingEdgeId,
      );
}

class _EdgeEndpoint {
  const _EdgeEndpoint(this.position, this.angle);

  final Offset position;
  final double angle;
}

Offset _nodePortPosition(
  FlowNode node,
  FlowPortSide side,
  double fraction, {
  Offset? position,
}) {
  final nodePosition = position ?? node.position;
  return switch (side) {
    FlowPortSide.left =>
      Offset(nodePosition.dx, nodePosition.dy + node.size.height * fraction),
    FlowPortSide.right => Offset(nodePosition.dx + node.size.width,
        nodePosition.dy + node.size.height * fraction),
    FlowPortSide.top =>
      Offset(nodePosition.dx + node.size.width * fraction, nodePosition.dy),
    FlowPortSide.bottom => Offset(nodePosition.dx + node.size.width * fraction,
        nodePosition.dy + node.size.height),
  };
}

Path _connectionPath(
  Offset start,
  Offset end,
  FlowPortSide startSide,
  FlowPortSide endSide,
) {
  final distance = (end - start).distance;
  final handleLength = math.max(38.0, math.min(170.0, distance * 0.48));
  final startControl = start + _sideVector(startSide) * handleLength;
  final endControl = end + _sideVector(endSide) * handleLength;
  return Path()
    ..moveTo(start.dx, start.dy)
    ..cubicTo(
      startControl.dx,
      startControl.dy,
      endControl.dx,
      endControl.dy,
      end.dx,
      end.dy,
    );
}

Offset _sideVector(FlowPortSide side) => switch (side) {
      FlowPortSide.left => const Offset(-1, 0),
      FlowPortSide.right => const Offset(1, 0),
      FlowPortSide.top => const Offset(0, -1),
      FlowPortSide.bottom => const Offset(0, 1),
    };

void _drawArrow(Canvas canvas, Tangent tangent, Color color) {
  final direction = tangent.vector.direction;
  const length = 8.0;
  final point = tangent.position;
  final left = point -
      Offset(math.cos(direction - 0.46), math.sin(direction - 0.46)) * length;
  final right = point -
      Offset(math.cos(direction + 0.46), math.sin(direction + 0.46)) * length;
  canvas.drawPath(
    Path()
      ..moveTo(point.dx, point.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close(),
    Paint()..color = color,
  );
}
