import 'dart:ui';

import 'package:flow_compose/flow_compose.dart';

class StartNode extends INode {
  StartNode(
      {required super.label,
      required super.uuid,
      required super.offset,
      super.width = 100,
      super.height = 50,
      super.nodeName = "开始",
      super.description = "启动节点，用于流程的开始",
      super.builderName = "StartNode"});

  factory StartNode.fromJson(Map<String, dynamic> json) {
    String uuid = json["uuid"] ?? "";
    String label = json["label"] ?? "";
    Offset offset = Offset(json["offset"]["dx"], json["offset"]["dy"]);
    double width = json["width"] ?? 300;
    double height = json["height"] ?? 400;
    String nodeName = json["nodeName"] ?? "base";
    String description =
        json["description"] ?? "Base node, just for testing purposes";
    String builderName = json["builderName"] ?? "base";
    // Map<String, dynamic>? data = json["data"];

    return StartNode(
      offset: offset,
      width: width,
      height: height,
      nodeName: nodeName,
      description: description,
      builderName: builderName,
      label: label,
      uuid: uuid,
    );
  }

  @override
  INode copyWith(
      {double? width,
      double? height,
      String? label,
      String? uuid,
      Offset? offset,
      List<INode>? children,
      Map<String, dynamic>? data}) {
    return StartNode(
      width: width ?? this.width,
      height: height ?? this.height,
      label: label ?? this.label,
      uuid: uuid ?? this.uuid,
      offset: offset ?? this.offset,
    );
  }
}
