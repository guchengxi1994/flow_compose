import 'dart:ui';

import 'package:flow_compose/flow_compose.dart';

class StartNode extends INode {
  StartNode(
      {required super.label,
      required super.uuid,
      required super.depth,
      required super.offset,
      super.width = 100,
      super.height = 50,
      super.children,
      super.nodeName = "开始",
      super.description = "启动节点，用于流程的开始",
      super.builderName = "StartNode"});

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
    return StartNode(
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
