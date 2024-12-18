import 'package:flow_compose/src/nodes/inode.dart';
import 'package:flutter/material.dart';

typedef OnNodeDrag = void Function(Offset offset);
// typedef OnBoardSizeChange = void Function(double factor);
typedef OnNodeEdgeCreateOrModify = void Function(Offset offset);

typedef OnEdgeAccept = void Function(String from, String to);

class BaseNode extends INode {
  BaseNode(
      {required super.label,
      required super.uuid,
      required super.depth,
      required super.offset,
      super.width,
      super.height,
      super.children,
      super.nodeName,
      super.description});

  @override
  String toString() {
    return 'BaseNode{width: $width, height: $height, label: $label, uuid: $uuid, depth: $depth, offset: $offset, children: $children}';
  }

  static List<BaseNode> fake() {
    return [
      BaseNode(
          width: 150,
          height: 150,
          label: "1-1",
          uuid: "1-1",
          depth: 1,
          offset: Offset(200, 200),
          children: []),
      BaseNode(
          width: 150,
          height: 150,
          label: "2-2",
          uuid: "2-2",
          depth: 1,
          offset: Offset(500, 500),
          children: [])
    ];
  }

  @Deprecated("use [NodeWidget] instead")
  Widget build({
    required Offset dragOffset,
    required double factor,
    required OnNodeDrag onNodeDrag,
    required OnNodeEdgeCreateOrModify onNodeEdgeCreateOrModify,
    required VoidCallback onNodeEdgeCancel,
    required OnEdgeAccept onEdgeAccept,
  }) {
    return Positioned(
      left: offset.dx * factor + dragOffset.dx,
      top: offset.dy * factor + dragOffset.dy,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            GestureDetector(
                onPanUpdate: (details) {
                  // print(details);
                  onNodeDrag(details.delta);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  width: width * factor,
                  height: height * factor,
                  alignment: Alignment.center,
                  child: Text(label),
                )),
            Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                    onTap: () {
                      debugPrint("delete $uuid");
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                    ))),
            Positioned(
                right: 0,
                top: 0.5 * height * factor,
                child: Draggable(
                    data: uuid,
                    onDragUpdate: (details) {
                      // print(details);
                      onNodeEdgeCreateOrModify(details.delta);
                    },
                    onDragEnd: (details) {
                      onNodeEdgeCancel();
                    },
                    feedback: Container(
                      width: 5,
                      height: 5,
                      color: Colors.red,
                    ),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.output),
                    ))),
            Positioned(
                left: 0,
                top: 0.5 * height * factor,
                child: DragTarget<String>(
                  builder: (c, _, __) {
                    return Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.input),
                    );
                  },
                  onAcceptWithDetails: (data) {
                    debugPrint("accept ${data.data} this is $uuid");
                    onEdgeAccept(data.data, uuid);
                  },
                ))
          ],
        ),
      ),
    );
  }

  @override
  INode copyWith(
      {double? width,
      double? height,
      String? label,
      String? uuid,
      int? depth,
      Offset? offset,
      List<INode>? children,
      Map<String, dynamic>? data}) {
    return BaseNode(
      width: width ?? this.width,
      height: height ?? this.height,
      label: label ?? this.label,
      uuid: uuid ?? this.uuid,
      depth: depth ?? this.depth,
      offset: offset ?? this.offset,
      children: children ?? this.children,
    );
  }
}

class Edge {
  final String uuid;
  final String source;
  final String? target;

  final Offset start;
  final Offset end;

  @override
  bool operator ==(Object other) {
    return other is Edge && other.source == source && other.target == target;
  }

  Edge(
      {required this.uuid,
      required this.source,
      this.target,
      required this.start,
      required this.end});

  @override
  String toString() {
    return 'Edge{uuid: $uuid, source: $source, target: $target, start: $start, end: $end}';
  }

  Edge copyWith({
    String? uuid,
    String? source,
    String? target,
    Offset? start,
    Offset? end,
  }) {
    return Edge(
      uuid: uuid ?? this.uuid,
      source: source ?? this.source,
      target: target ?? this.target,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  @override
  int get hashCode =>
      uuid.hashCode ^
      source.hashCode ^
      target.hashCode ^
      start.hashCode ^
      end.hashCode;
}
