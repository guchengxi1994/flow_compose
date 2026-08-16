import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'flow_models.dart';

class FlowController extends ChangeNotifier {
  FlowController({FlowGraph graph = const FlowGraph()}) : _graph = graph;

  final _uuid = const Uuid();
  final Map<String, FlowNodeDefinition> _definitions = {};
  FlowGraph _graph;
  String? _selectedNodeId;

  FlowGraph get graph => _graph;
  String? get selectedNodeId => _selectedNodeId;
  FlowNode? get selectedNode => nodeById(_selectedNodeId ?? '');
  Iterable<FlowNodeDefinition> get definitions => _definitions.values;

  FlowNodeDefinition? definitionFor(String type) => _definitions[type];

  void registerNode(FlowNodeDefinition definition) {
    _definitions[definition.type] = definition;
    notifyListeners();
  }

  void registerNodes(Iterable<FlowNodeDefinition> definitions) {
    for (final definition in definitions) {
      _definitions[definition.type] = definition;
    }
    notifyListeners();
  }

  FlowNode addNode(String type, Offset position, {Map<String, dynamic>? data}) {
    final definition = _definitions[type];
    if (definition == null) {
      throw ArgumentError.value(
          type, 'type', 'No node definition is registered');
    }
    final node = FlowNode(
      id: _uuid.v4(),
      type: type,
      position: position,
      size: definition.size,
      data: {...definition.initialData, ...?data},
    );
    _graph = _graph.copyWith(nodes: [..._graph.nodes, node]);
    selectNode(node.id);
    return node;
  }

  void updateNode(FlowNode node) {
    _graph = _graph.copyWith(
      nodes: [
        for (final current in _graph.nodes)
          if (current.id == node.id) node else current,
      ],
    );
    notifyListeners();
  }

  void moveNode(String nodeId, Offset position) {
    final node = nodeById(nodeId);
    if (node != null) updateNode(node.copyWith(position: position));
  }

  void updateNodeData(String nodeId, Map<String, dynamic> data) {
    final node = nodeById(nodeId);
    if (node != null) updateNode(node.copyWith(data: Map.unmodifiable(data)));
  }

  void removeNode(String nodeId) {
    _graph = _graph.copyWith(
      nodes: _graph.nodes.where((node) => node.id != nodeId).toList(),
      edges: _graph.edges
          .where((edge) =>
              edge.source.nodeId != nodeId && edge.target.nodeId != nodeId)
          .toList(),
    );
    if (_selectedNodeId == nodeId) _selectedNodeId = null;
    notifyListeners();
  }

  bool canConnect(
    FlowPortRef source,
    FlowPortRef target, {
    String? replacingEdgeId,
  }) =>
      validateConnection(
        source,
        target,
        replacingEdgeId: replacingEdgeId,
      ).isValid;

  /// Checks whether an edge can be created without changing the graph.
  ///
  /// The returned issue is suitable for both a UI message and programmatic
  /// handling. Use [connectOrThrow] when invalid connections should surface as
  /// an exception instead.
  FlowConnectionValidation validateConnection(
    FlowPortRef source,
    FlowPortRef target, {
    String? replacingEdgeId,
  }) {
    final sourceNode = nodeById(source.nodeId);
    if (sourceNode == null) {
      return const FlowConnectionValidation.invalid(FlowValidationIssue(
        code: FlowValidationCode.sourceNodeNotFound,
        message: 'The source node no longer exists.',
      ));
    }
    final targetNode = nodeById(target.nodeId);
    if (targetNode == null) {
      return const FlowConnectionValidation.invalid(FlowValidationIssue(
        code: FlowValidationCode.targetNodeNotFound,
        message: 'The target node no longer exists.',
      ));
    }
    if (source.nodeId == target.nodeId) {
      return FlowConnectionValidation.invalid(FlowValidationIssue(
        code: FlowValidationCode.selfConnection,
        message: 'A node cannot connect to itself.',
        source: source,
        target: target,
        edgeId: replacingEdgeId,
      ));
    }

    final sourcePort = portFor(source);
    final targetPort = portFor(target);
    if (sourcePort == null) {
      return FlowConnectionValidation.invalid(FlowValidationIssue(
        code: FlowValidationCode.sourcePortNotFound,
        message: 'The source port no longer exists.',
        source: source,
        target: target,
        edgeId: replacingEdgeId,
      ));
    }
    if (targetPort == null) {
      return FlowConnectionValidation.invalid(FlowValidationIssue(
        code: FlowValidationCode.targetPortNotFound,
        message: 'The target port no longer exists.',
        source: source,
        target: target,
        edgeId: replacingEdgeId,
      ));
    }
    if (sourcePort.kind != FlowPortKind.output) {
      return FlowConnectionValidation.invalid(FlowValidationIssue(
        code: FlowValidationCode.sourceMustBeOutput,
        message: 'Connections must start from an output port.',
        source: source,
        target: target,
        edgeId: replacingEdgeId,
      ));
    }
    if (targetPort.kind != FlowPortKind.input) {
      return FlowConnectionValidation.invalid(FlowValidationIssue(
        code: FlowValidationCode.targetMustBeInput,
        message: 'Connections must end on an input port.',
        source: source,
        target: target,
        edgeId: replacingEdgeId,
      ));
    }
    if (!isFlowDataTypeCompatible(
      source: sourcePort.dataType,
      target: targetPort.dataType,
    )) {
      return FlowConnectionValidation.invalid(FlowValidationIssue(
        code: FlowValidationCode.incompatibleDataTypes,
        message: 'Cannot connect ${sourcePort.dataType.name} data to a '
            '${targetPort.dataType.name} input.',
        source: source,
        target: target,
        edgeId: replacingEdgeId,
      ));
    }

    final otherEdges = _graph.edges.where(
      (edge) => edge.id != replacingEdgeId,
    );
    if (otherEdges.any(
      (edge) => edge.source == source && edge.target == target,
    )) {
      return FlowConnectionValidation.invalid(FlowValidationIssue(
        code: FlowValidationCode.duplicateConnection,
        message: 'These ports are already connected.',
        source: source,
        target: target,
        edgeId: replacingEdgeId,
      ));
    }
    if (!targetPort.allowMultipleConnections &&
        otherEdges.any((edge) => edge.target == target)) {
      return FlowConnectionValidation.invalid(FlowValidationIssue(
        code: FlowValidationCode.inputAlreadyConnected,
        message: 'This input already has a connection. Reconnect its arrow '
            'instead of adding another edge.',
        source: source,
        target: target,
        edgeId: replacingEdgeId,
      ));
    }
    return const FlowConnectionValidation.valid();
  }

  bool connect(FlowPortRef source, FlowPortRef target) {
    if (!validateConnection(source, target).isValid) return false;
    _graph = _graph.copyWith(
      edges: [
        ..._graph.edges,
        FlowEdge(id: _uuid.v4(), source: source, target: target),
      ],
    );
    notifyListeners();
    return true;
  }

  void connectOrThrow(FlowPortRef source, FlowPortRef target) {
    final validation = validateConnection(source, target);
    if (!validation.isValid) {
      throw FlowConnectionException(validation.issue!);
    }
    _graph = _graph.copyWith(
      edges: [
        ..._graph.edges,
        FlowEdge(id: _uuid.v4(), source: source, target: target),
      ],
    );
    notifyListeners();
  }

  bool reconnectEdgeTarget(String edgeId, FlowPortRef target) {
    final edge = _graph.edges.firstWhereOrNull((edge) => edge.id == edgeId);
    if (edge == null ||
        !validateConnection(
          edge.source,
          target,
          replacingEdgeId: edgeId,
        ).isValid) {
      return false;
    }

    _graph = _graph.copyWith(
      edges: [
        for (final current in _graph.edges)
          if (current.id == edgeId) edge.copyWith(target: target) else current,
      ],
    );
    notifyListeners();
    return true;
  }

  void removeEdge(String edgeId) {
    _graph = _graph.copyWith(
      edges: _graph.edges.where((edge) => edge.id != edgeId).toList(),
    );
    notifyListeners();
  }

  void selectNode(String? nodeId) {
    if (_selectedNodeId == nodeId) return;
    _selectedNodeId = nodeId;
    notifyListeners();
  }

  void replaceGraph(FlowGraph graph) {
    final nodeIds = graph.nodes.map((node) => node.id).toSet();
    _graph = graph.copyWith(
      edges: graph.edges.where((edge) {
        final sourceNode = graph.nodes
            .where((node) => node.id == edge.source.nodeId)
            .firstOrNull;
        final targetNode = graph.nodes
            .where((node) => node.id == edge.target.nodeId)
            .firstOrNull;
        final sourceDefinition =
            sourceNode == null ? null : _definitions[sourceNode.type];
        final targetDefinition =
            targetNode == null ? null : _definitions[targetNode.type];
        final sourcePort = sourceDefinition?.port(edge.source.portId);
        final targetPort = targetDefinition?.port(edge.target.portId);
        return nodeIds.contains(edge.source.nodeId) &&
            nodeIds.contains(edge.target.nodeId) &&
            edge.source.nodeId != edge.target.nodeId &&
            sourcePort?.kind == FlowPortKind.output &&
            targetPort?.kind == FlowPortKind.input;
      }).toList(),
    );
    _selectedNodeId = null;
    notifyListeners();
  }

  void clear() {
    _graph = const FlowGraph();
    _selectedNodeId = null;
    notifyListeners();
  }

  /// Validates persisted or user-built graphs before a workflow is executed.
  List<FlowValidationIssue> validateGraph() {
    final issues = <FlowValidationIssue>[];
    for (final edge in _graph.edges) {
      final validation = validateConnection(
        edge.source,
        edge.target,
        replacingEdgeId: edge.id,
      );
      if (validation.issue case final issue?) issues.add(issue);
    }

    for (final node in _graph.nodes) {
      final definition = definitionFor(node.type);
      if (definition == null) continue;
      for (final input in definition.inputs.where((port) => port.isRequired)) {
        final ref = FlowPortRef(node.id, input.id);
        if (_graph.edges.any((edge) => edge.target == ref)) continue;
        issues.add(FlowValidationIssue(
          code: FlowValidationCode.missingRequiredInput,
          message: 'Required input "${input.label}" is not connected.',
          target: ref,
        ));
      }
    }
    return List.unmodifiable(issues);
  }

  String exportJson() => jsonEncode(_graph.toJson());

  void importJson(String source) {
    replaceGraph(
        FlowGraph.fromJson(Map<String, dynamic>.from(jsonDecode(source))));
  }

  FlowNode? nodeById(String nodeId) {
    for (final node in _graph.nodes) {
      if (node.id == nodeId) return node;
    }
    return null;
  }

  FlowPort? portFor(FlowPortRef ref) {
    final node = nodeById(ref.nodeId);
    return node == null ? null : definitionFor(node.type)?.port(ref.portId);
  }

  bool canResolvePort(FlowPortRef ref) => portFor(ref) != null;
}
