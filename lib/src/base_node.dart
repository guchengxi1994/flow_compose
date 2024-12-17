import 'package:flutter/material.dart';

typedef OnNodeDrag = void Function(Offset offset);
// typedef OnBoardSizeChange = void Function(double factor);

class BaseNode {
  final double width;
  final double height;
  final String label;
  final String uuid;
  final int depth;
  final Offset offset;
  final List<BaseNode> children;

  BaseNode(
      {this.width = 300,
      this.height = 400,
      required this.label,
      required this.uuid,
      required this.depth,
      required this.offset,
      this.children = const []});

  @override
  String toString() {
    return 'BaseNode{width: $width, height: $height, label: $label, uuid: $uuid, depth: $depth, offset: $offset, children: $children}';
  }

  static List<BaseNode> fake() {
    return [
      BaseNode(
          width: 300,
          height: 400,
          label: "1-1",
          uuid: "1-1",
          depth: 1,
          offset: Offset(500, 500),
          children: [])
    ];
  }

  Widget build(
      {required Offset dragOffset,
      required double factor,
      required OnNodeDrag onNodeDrag}) {
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
                      print("delete $uuid");
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
                    onDragUpdate: (details) {
                      // print(details);
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
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.input),
                ))
          ],
        ),
      ),
    );
  }

  BaseNode copyWith({
    double? width,
    double? height,
    String? label,
    String? uuid,
    int? depth,
    Offset? offset,
    List<BaseNode>? children,
  }) {
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
