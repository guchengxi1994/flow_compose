import 'package:flutter/material.dart';

abstract class INode {
  final double width;
  final double height;
  final String label;
  final String uuid;
  final int depth;
  final Offset offset;
  final List<INode> children;
  final String nodeName;
  final String description;

  Widget fakeWidget() {
    return Material(
      elevation: 10,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(label),
        ),
      ),
    );
  }

  INode(
      {this.width = 300,
      this.height = 400,
      required this.label,
      required this.uuid,
      required this.depth,
      required this.offset,
      this.children = const [],
      this.nodeName = "base",
      this.description = "Base node, just for testing purposes"});

  Offset get outputPoint => Offset(offset.dx + width, offset.dy + 0.5 * height);

  Offset get inputPoint => Offset(offset.dx, offset.dy + 0.5 * height);

  List<INode> getChildren() {
    return children;
  }

  int getDepth() {
    return depth;
  }

  double getHeight() {
    return height;
  }

  String getLabel() {
    return label;
  }

  Offset getOffset() {
    return offset;
  }

  String getUuid() {
    return uuid;
  }

  double getWidth() {
    return width;
  }

  INode copyWith(
      {double? width,
      double? height,
      String? label,
      String? uuid,
      int? depth,
      Offset? offset,
      List<INode>? children,
      Map<String, dynamic>? data});
}
