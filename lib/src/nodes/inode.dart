import 'package:flutter/material.dart';

typedef NodeBuilder = Widget Function(BuildContext context);

class INode {
  final double width;
  final double height;
  final String label;
  final String uuid;
  @Deprecated("maybe will be removed in future")
  final int depth;
  final Offset offset;
  @Deprecated("maybe will be removed in future")
  final List<INode> children;
  final String nodeName;
  final String description;
  NodeBuilder? builder;
  final String builderName;
  Map<String, dynamic>? data;

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

  Map<String, Object> toJson() {
    return {
      "uuid": uuid,
      "label": label,
      "depth": depth,
      "offset": {"dx": offset.dx, "dy": offset.dy},
      "width": width,
      "height": height,
      "nodeName": nodeName,
      "description": description,
      "builderName": builderName,
      "data": data ?? {},
    };
  }

  factory INode.fromJson(Map<String, dynamic> json) {
    String uuid = json["uuid"] ?? "";
    String label = json["label"] ?? "";
    int depth = json["depth"] ?? 0;
    Offset offset = Offset(json["offset"]["dx"], json["offset"]["dy"]);
    double width = json["width"] ?? 300;
    double height = json["height"] ?? 400;
    String nodeName = json["nodeName"] ?? "base";
    String description =
        json["description"] ?? "Base node, just for testing purposes";
    String builderName = json["builderName"] ?? "base";
    Map<String, dynamic>? data = json["data"];

    return INode(
        offset: offset,
        width: width,
        height: height,
        nodeName: nodeName,
        description: description,
        builderName: builderName,
        data: data,
        label: label,
        uuid: uuid,
        depth: depth);
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
      this.description = "Base node, just for testing purposes",
      this.builder,
      this.data,
      required this.builderName});

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
      Map<String, dynamic>? data}) {
    return INode(
        width: width ?? this.width,
        height: height ?? this.height,
        label: label ?? this.label,
        uuid: uuid ?? this.uuid,
        depth: depth ?? this.depth,
        offset: offset ?? this.offset,
        children: children ?? this.children,
        builderName: builderName);
  }
}
