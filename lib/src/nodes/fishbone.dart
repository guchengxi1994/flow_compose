import 'package:flutter/material.dart';

typedef HiddenBuilder = Widget Function(BuildContext ctx, String uuid);

enum NodePosition { up, down }

class FishboneNode {
  final String label;
  final double angle;
  final double distance;
  final List<FishboneNode> children;
  final String uuid;
  final bool isHidden;
  final int depth;
  final NodePosition position;
  HiddenBuilder? hiddenBuilder;

  FishboneNode(
      {required this.label,
      required this.uuid,
      this.angle = 0.0,
      this.distance = 100.0,
      this.children = const [],
      this.isHidden = false,
      this.hiddenBuilder,
      required this.depth,
      this.position = NodePosition.up});

  static List<FishboneNode> fake() {
    return [
      FishboneNode(
          label: "1-1",
          uuid: "1-1",
          depth: 1,
          position: NodePosition.up,
          children: [
            FishboneNode(label: "1-1-1", uuid: "1-1-1", depth: 2, children: [])
          ]),
      FishboneNode(
          label: "2-2",
          uuid: "2-2",
          depth: 1,
          position: NodePosition.down,
          children: [
            FishboneNode(label: "2-2-1", uuid: "2-2-1", depth: 2, children: [])
          ]),
    ];
  }
}
