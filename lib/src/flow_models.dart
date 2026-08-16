import 'package:flutter/material.dart';

enum FlowPortKind { input, output }

enum FlowPortSide { left, right, top, bottom }

/// The JSON value a port publishes or accepts.
///
/// `json` represents an unconstrained JSON value. It is deliberately
/// compatible with every other type so flows can model dynamic payloads while
/// still rejecting known-invalid connections such as an array into a string.
enum FlowDataType { json, string, integer, number, boolean, object, array }

bool isFlowDataTypeCompatible({
  required FlowDataType source,
  required FlowDataType target,
}) {
  if (source == FlowDataType.json || target == FlowDataType.json) return true;
  return source == target ||
      (source == FlowDataType.integer && target == FlowDataType.number);
}

/// A typed handle exposed by a [FlowNodeDefinition].
class FlowPort {
  const FlowPort({
    required this.id,
    required this.label,
    required this.kind,
    FlowPortSide? side,
    this.allowMultipleConnections = true,
    this.dataType = FlowDataType.json,
    this.isRequired = false,
    this.color,
  }) : side = side ??
            (kind == FlowPortKind.input
                ? FlowPortSide.left
                : FlowPortSide.right);

  final String id;
  final String label;
  final FlowPortKind kind;
  final FlowPortSide side;
  final bool allowMultipleConnections;
  final FlowDataType dataType;
  final bool isRequired;
  final Color? color;
}

enum FlowValidationCode {
  sourceNodeNotFound,
  targetNodeNotFound,
  sourcePortNotFound,
  targetPortNotFound,
  selfConnection,
  sourceMustBeOutput,
  targetMustBeInput,
  incompatibleDataTypes,
  duplicateConnection,
  inputAlreadyConnected,
  missingRequiredInput,
}

class FlowValidationIssue {
  const FlowValidationIssue({
    required this.code,
    required this.message,
    this.source,
    this.target,
    this.edgeId,
  });

  final FlowValidationCode code;
  final String message;
  final FlowPortRef? source;
  final FlowPortRef? target;
  final String? edgeId;
}

class FlowConnectionValidation {
  const FlowConnectionValidation.valid() : issue = null;

  const FlowConnectionValidation.invalid(FlowValidationIssue this.issue);

  final FlowValidationIssue? issue;

  bool get isValid => issue == null;
}

class FlowConnectionException implements Exception {
  const FlowConnectionException(this.issue);

  final FlowValidationIssue issue;

  @override
  String toString() => 'FlowConnectionException: ${issue.message}';
}

class FlowPortRef {
  const FlowPortRef(this.nodeId, this.portId);

  final String nodeId;
  final String portId;

  Map<String, dynamic> toJson() => {'nodeId': nodeId, 'portId': portId};

  factory FlowPortRef.fromJson(Map<String, dynamic> json) => FlowPortRef(
        json['nodeId'] as String,
        json['portId'] as String,
      );

  @override
  bool operator ==(Object other) =>
      other is FlowPortRef && other.nodeId == nodeId && other.portId == portId;

  @override
  int get hashCode => Object.hash(nodeId, portId);
}

class FlowNode {
  FlowNode({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    Map<String, dynamic> data = const {},
  }) : data = Map.unmodifiable(data);

  final String id;
  final String type;
  final Offset position;
  final Size size;
  final Map<String, dynamic> data;

  Rect get rect => position & size;

  FlowNode copyWith({
    String? id,
    String? type,
    Offset? position,
    Size? size,
    Map<String, dynamic>? data,
  }) =>
      FlowNode(
        id: id ?? this.id,
        type: type ?? this.type,
        position: position ?? this.position,
        size: size ?? this.size,
        data: data ?? this.data,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'position': {'x': position.dx, 'y': position.dy},
        'size': {'width': size.width, 'height': size.height},
        'data': data,
      };

  factory FlowNode.fromJson(Map<String, dynamic> json) {
    final position = json['position'] as Map<String, dynamic>;
    final size = json['size'] as Map<String, dynamic>;
    return FlowNode(
      id: json['id'] as String,
      type: json['type'] as String,
      position: Offset(
        (position['x'] as num).toDouble(),
        (position['y'] as num).toDouble(),
      ),
      size: Size(
        (size['width'] as num).toDouble(),
        (size['height'] as num).toDouble(),
      ),
      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
    );
  }
}

class FlowEdge {
  const FlowEdge({
    required this.id,
    required this.source,
    required this.target,
  });

  final String id;
  final FlowPortRef source;
  final FlowPortRef target;

  FlowEdge copyWith({
    String? id,
    FlowPortRef? source,
    FlowPortRef? target,
  }) =>
      FlowEdge(
        id: id ?? this.id,
        source: source ?? this.source,
        target: target ?? this.target,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source.toJson(),
        'target': target.toJson(),
      };

  factory FlowEdge.fromJson(Map<String, dynamic> json) => FlowEdge(
        id: json['id'] as String,
        source: FlowPortRef.fromJson(
          Map<String, dynamic>.from(json['source'] as Map),
        ),
        target: FlowPortRef.fromJson(
          Map<String, dynamic>.from(json['target'] as Map),
        ),
      );
}

class FlowGraph {
  const FlowGraph({this.nodes = const [], this.edges = const []});

  final List<FlowNode> nodes;
  final List<FlowEdge> edges;

  FlowGraph copyWith({List<FlowNode>? nodes, List<FlowEdge>? edges}) =>
      FlowGraph(nodes: nodes ?? this.nodes, edges: edges ?? this.edges);

  Map<String, dynamic> toJson() => {
        'version': 1,
        'nodes': nodes.map((node) => node.toJson()).toList(),
        'edges': edges.map((edge) => edge.toJson()).toList(),
      };

  factory FlowGraph.fromJson(Map<String, dynamic> json) => FlowGraph(
        nodes: (json['nodes'] as List<dynamic>? ?? const [])
            .map((node) => FlowNode.fromJson(Map<String, dynamic>.from(node)))
            .toList(),
        edges: (json['edges'] as List<dynamic>? ?? const [])
            .map((edge) => FlowEdge.fromJson(Map<String, dynamic>.from(edge)))
            .toList(),
      );
}

typedef FlowNodeCanvasBuilder = Widget Function(
  BuildContext context,
  FlowNode node,
);

typedef FlowNodeConfigBuilder = Widget Function(
  BuildContext context,
  FlowNode node,
  ValueChanged<Map<String, dynamic>> onChanged,
);

typedef FlowPalettePreviewBuilder = Widget Function(BuildContext context);

/// The complete contract for a user-defined node type.
///
/// Register one definition for each business component. The editor uses it for
/// the palette, canvas, port layout and configuration inspector.
class FlowNodeDefinition {
  const FlowNodeDefinition({
    required this.type,
    required this.title,
    required this.description,
    this.size = const Size(260, 144),
    this.inputs = const [],
    this.outputs = const [],
    this.initialData = const {},
    this.canvasBuilder,
    this.configurationBuilder,
    this.palettePreviewBuilder,
    this.icon = Icons.widgets_outlined,
    this.accentColor = const Color(0xFF226D68),
  });

  final String type;
  final String title;
  final String description;
  final Size size;
  final List<FlowPort> inputs;
  final List<FlowPort> outputs;
  final Map<String, dynamic> initialData;
  final FlowNodeCanvasBuilder? canvasBuilder;
  final FlowNodeConfigBuilder? configurationBuilder;
  final FlowPalettePreviewBuilder? palettePreviewBuilder;
  final IconData icon;
  final Color accentColor;

  FlowPort? port(String id) {
    for (final port in [...inputs, ...outputs]) {
      if (port.id == id) return port;
    }
    return null;
  }
}
