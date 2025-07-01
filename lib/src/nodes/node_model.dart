import 'package:flutter/material.dart';

import 'events.dart';

class ExtraNodeConfig {
  double width;
  double height;
  String? description;

  ExtraNodeConfig({this.width = 100, this.height = 80, this.description});
}

typedef OnNodeStatusChanged = void Function(
    NodeModel node, EventType eventType);

class NodeModel {
  final String uuid;
  final String type; // 节点类型，如 VisionNode
  final String label;
  final Offset offset;
  final String? description;
  final double width;
  final double height;
  Map<String, dynamic> data;
  Map<String, Map<String, dynamic>?>? prevData;
  OnNodeStatusChanged? onStatusChanged; // 👈 添加监听器

  Offset get outputPoint => Offset(offset.dx + width, offset.dy + 0.5 * height);

  Offset get inputPoint => Offset(offset.dx, offset.dy + 0.5 * height);

  NodeModel({
    required this.uuid,
    required this.type,
    required this.label,
    required this.offset,
    this.width = 125,
    this.height = 60,
    this.description,
    this.data = const {},
    this.prevData,
  });

  NodeModel copyWith({
    String? uuid,
    String? type,
    String? label,
    Offset? offset,
    double? width,
    double? height,
    Map<String, dynamic>? data,
    Map<String, Map<String, dynamic>>? prevData,
    String? description,
  }) {
    NodeModel node = NodeModel(
      uuid: uuid ?? this.uuid,
      type: type ?? this.type,
      label: label ?? this.label,
      offset: offset ?? this.offset,
      width: width ?? this.width,
      height: height ?? this.height,
      data: data ?? Map.of(this.data),
      prevData: prevData ?? Map.of(this.prevData ?? {}),
      description: description ?? this.description,
    );

    node.onStatusChanged = onStatusChanged;
    return node;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uuid': uuid,
      'label': label,
      'width': width,
      'height': height,
      'data': data,
      'prevData': prevData,
      'description': description,
    };
  }

  factory NodeModel.fromJson(Map<String, dynamic> json) {
    String uuid = json["uuid"] ?? "";
    Offset offset = Offset(json["offset"]["dx"], json["offset"]["dy"]);
    double width = json["width"] ?? 300;
    double height = json["height"] ?? 400;
    String label = json["label"] ?? "base";
    String description =
        json["description"] ?? "Base node, just for testing purposes";
    String type = json["type"] ?? "";
    Map<String, dynamic>? data = json["data"];
    Map<String, Map<String, dynamic>> prevData = json['prevData'] ?? {};

    NodeModel node = NodeModel(
        type: type,
        offset: offset,
        width: width,
        height: height,
        description: description,
        data: data ?? {},
        uuid: uuid,
        prevData: prevData,
        label: label);

    // TODO: 监听节点状态
    node.onStatusChanged = (model, type) {};

    return node;
  }
}
