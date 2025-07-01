import 'package:flow_compose/src/nodes/nodes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef OnNodeDrag = void Function(Offset offset);

typedef OnNodeEdgeCreateOrModify = void Function(Offset offset);

typedef OnEdgeAccept = void Function(String from, String to);

typedef OnNodeDelete = void Function(String uuid);

typedef OnNodeFocus = void Function(NodeModel node);

class NodeWidget extends StatefulWidget {
  final NodeModel node;
  final Offset dragOffset;
  final double factor;
  final OnNodeDrag onNodeDrag;
  final OnNodeEdgeCreateOrModify onNodeEdgeCreateOrModify;
  final VoidCallback onNodeEdgeCancel;
  final OnEdgeAccept onEdgeAccept;
  final OnNodeDelete onNodeDelete;
  final OnNodeFocus? onNodeFocus;
  final bool isFocused;
  final bool isEditable;
  final bool hasPrev;
  final Map<String, NodeWidgetBuilder> nodeRenderRegistry;

  const NodeWidget({
    super.key,
    required this.node,
    required this.dragOffset,
    required this.factor,
    required this.onNodeDrag,
    required this.onNodeEdgeCreateOrModify,
    required this.onNodeEdgeCancel,
    required this.onEdgeAccept,
    required this.onNodeDelete,
    this.onNodeFocus,
    this.isFocused = false,
    required this.isEditable,
    required this.hasPrev,
    required this.nodeRenderRegistry,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  bool willAccept = false;

  @override
  Widget build(BuildContext context) {
    final builder = widget.nodeRenderRegistry[widget.node.type];
    final offset = widget.node.offset;
    final width = widget.node.width;
    final height = widget.node.height;

    return Positioned(
      left: offset.dx * widget.factor + widget.dragOffset.dx,
      top: offset.dy * widget.factor + widget.dragOffset.dy,
      child: Material(
        elevation: widget.isFocused ? 10 : 4,
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => widget.onNodeFocus?.call(widget.node),
              onPanUpdate: (details) => widget.onNodeDrag(details.delta),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blueAccent),
                  color: Colors.white,
                ),
                width: width * widget.factor,
                height: height * widget.factor,
                alignment: Alignment.center,
                child: builder != null
                    ? builder(
                        context,
                        widget.node,
                      )
                    : Center(
                        child: Text(
                          widget.node.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: InkWell(
                onTap: () => widget.onNodeDelete(widget.node.uuid),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: Icon(
                    Icons.delete,
                    color: Color.fromARGB(255, 237, 118, 118),
                    size: 16,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0.2 * height * widget.factor,
              child: MouseRegion(
                cursor: widget.isEditable
                    ? SystemMouseCursors.grab
                    : SystemMouseCursors.forbidden,
                child: Draggable<NodeModel>(
                  data: widget.node,
                  onDragUpdate: widget.isEditable
                      ? (details) =>
                          widget.onNodeEdgeCreateOrModify(details.delta)
                      : null,
                  onDragEnd: (_) => widget.onNodeEdgeCancel(),
                  feedback: Container(
                    width: 5,
                    height: 5,
                    color: Colors.transparent,
                  ),
                  dragAnchorStrategy: (draggable, context, position) {
                    return Offset(0, 0.3 * height * widget.factor);
                  },
                  child: Container(
                    width: 5,
                    height: 0.6 * height * widget.factor,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 1,
              top: 0.2 * height * widget.factor,
              child: DragTarget<NodeModel>(
                builder: (context, _, __) {
                  return Container(
                    width: 5,
                    height: 0.6 * height * widget.factor,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: willAccept
                          ? Colors.greenAccent
                          : widget.hasPrev
                              ? Colors.blueAccent
                              : Colors.grey[100],
                    ),
                  );
                },
                onWillAcceptWithDetails: (details) {
                  if (details.data.uuid == widget.node.uuid) {
                    return false;
                  }
                  setState(() => willAccept = true);
                  return true;
                },
                onLeave: (_) => setState(() => willAccept = false),
                onAcceptWithDetails: (details) {
                  widget.onEdgeAccept(details.data.uuid, widget.node.uuid);
                  setState(() => willAccept = false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
