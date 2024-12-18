import 'dart:ui';

abstract class INode {
  final double width;
  final double height;
  final String label;
  final String uuid;
  final int depth;
  final Offset offset;
  final List<INode> children;

  INode({
    this.width = 300,
    this.height = 400,
    required this.label,
    required this.uuid,
    required this.depth,
    required this.offset,
    this.children = const [],
  });

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
