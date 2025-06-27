import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';

typedef OnNodeStatusChanged = void Function(INode node, EventType eventType);
typedef NodeBuilder = Widget Function(BuildContext context);

class INode {
  final double width;
  final double height;
  final String label;
  final String uuid;
  final Offset offset;
  String nodeName;
  String description;
  NodeBuilder? builder;
  final String builderName;
  Map<String, dynamic>? data;
  Map<String, Map<String, dynamic>?>? prevData;

  OnNodeStatusChanged? onStatusChanged; // 👈 添加监听器

  void updateData(String key, dynamic value) {
    data ??= {};
    data![key] = value;

    if (onStatusChanged != null) {
      // 👇 主动触发回调
      onStatusChanged!(this, EventType.nodeDataChanged);
    }
  }

  void replaceAndUpdateData(Map<String, dynamic> map) {
    data = map;
    if (onStatusChanged != null) {
      // 👇 主动触发回调
      onStatusChanged!(this, EventType.nodeDataChanged);
    }
  }

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
      "offset": {"dx": offset.dx, "dy": offset.dy},
      "width": width,
      "height": height,
      "nodeName": nodeName,
      "description": description,
      "builderName": builderName,
      "data": data ?? {},
      "prevData": prevData ?? {}
    };
  }

  factory INode.fromJson(Map<String, dynamic> json) {
    String uuid = json["uuid"] ?? "";
    String label = json["label"] ?? "";
    Offset offset = Offset(json["offset"]["dx"], json["offset"]["dy"]);
    double width = json["width"] ?? 300;
    double height = json["height"] ?? 400;
    String nodeName = json["nodeName"] ?? "base";
    String description =
        json["description"] ?? "Base node, just for testing purposes";
    String builderName = json["builderName"] ?? "base";
    Map<String, dynamic>? data = json["data"];
    Map<String, Map<String, dynamic>> prevData = json['prevData'] ?? {};

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
        prevData: prevData);
  }

  INode(
      {this.width = 300,
      this.height = 400,
      required this.label,
      required this.uuid,
      required this.offset,
      this.nodeName = "base",
      this.description = "Base node, just for testing purposes",
      this.builder,
      this.data,
      this.prevData = const {},
      required this.builderName});

  Offset get outputPoint => Offset(offset.dx + width, offset.dy + 0.5 * height);

  Offset get inputPoint => Offset(offset.dx, offset.dy + 0.5 * height);

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

  INode copyWith({
    double? width,
    double? height,
    String? label,
    String? uuid,
    Offset? offset,
    List<INode>? children,
  }) {
    return INode(
        width: width ?? this.width,
        height: height ?? this.height,
        label: label ?? this.label,
        uuid: uuid ?? this.uuid,
        offset: offset ?? this.offset,
        builderName: builderName);
  }
}
