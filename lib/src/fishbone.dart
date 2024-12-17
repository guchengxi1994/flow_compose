import 'package:flutter/material.dart';
// ignore: library_prefixes
import 'dart:math' as Math;

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

void paintMain(Canvas canvas, Size size, List<FishboneNode> nodes,
    Offset offset, double scale) {
  // print("size $size");
  final Paint paint = Paint()
    ..color = Colors.black
    ..strokeWidth = 20 * scale
    ..style = PaintingStyle.stroke;

  // 绘制主骨干
  final Offset start = Offset(-500, 500) * scale + offset;
  final Offset end = Offset(500, 500) * scale + offset;

  canvas.drawLine(start, end, paint);
  drawArrow(canvas, end, scale);

  // [for test]
  for (final node in nodes) {
    paintNode(canvas, size, node, start + Offset(node.distance, 0) * scale,
        scale, 3.14 / 180 * 45);
  }
}

void paintNode(Canvas canvas, Size _, FishboneNode node, Offset offset,
    double scale, double rotation,
    {double parentRotation = 0}) {
  // 创建画笔
  final Paint paint = Paint()
    ..color = Colors.black
    ..strokeWidth = 20 / (node.depth + 1) * scale
    ..style = PaintingStyle.stroke;

  if (node.position == NodePosition.down) {
    // 计算起点和终点的位置
    final double lineLength = 100 * scale; // 线段长度，可以根据需求调整
    final Offset start =
        offset + Offset(0, (lineLength + 20) * Math.sin(rotation));
    final Offset end = Offset(
      offset.dx + lineLength * Math.cos(-rotation),
      offset.dy + 25 * scale,
    );

    // 绘制线段
    canvas.drawLine(start, end, paint);

    // 在终点绘制箭头
    drawArrow(canvas, end, scale,
        arrowSize: 40 / (node.depth + 1), rotation: -rotation);
  } else {
    // 计算起点和终点的位置
    final double lineLength = 100 * scale; // 线段长度，可以根据需求调整
    final Offset start =
        offset - Offset(0, (lineLength + 20) * Math.sin(rotation));
    final Offset end = Offset(
      offset.dx + lineLength * Math.cos(rotation),
      offset.dy - 25 * scale,
    );

    // 绘制线段
    canvas.drawLine(start, end, paint);

    // 在终点绘制箭头
    drawArrow(canvas, end, scale,
        arrowSize: 40 / (node.depth + 1), rotation: rotation);
  }
}

void drawArrow(Canvas canvas, Offset end, double scale,
    {double arrowSize = 40, double rotation = 0}) {
  final double arrowWidth = arrowSize * scale; // 箭头宽度
  final double arrowHeight = arrowSize * scale; // 箭头高度

  // 保存画布的当前状态
  canvas.save();

  // 移动画布到箭头绘制的终点（旋转中心）
  canvas.translate(end.dx, end.dy);

  // 应用旋转变换
  canvas.rotate(rotation);

  // 计算箭头的三个顶点（相对于旋转中心）
  final Offset tip = Offset(arrowWidth, 0); // 尖端
  final Offset left = Offset(0, -arrowHeight / 2); // 左下角
  final Offset right = Offset(0, arrowHeight / 2); // 左上角

  // 使用 Path 绘制三角形
  final Path arrowPath = Path()
    ..moveTo(tip.dx, tip.dy) // 移动到尖端
    ..lineTo(left.dx, left.dy) // 画线到左下角
    ..lineTo(right.dx, right.dy) // 画线到左上角
    ..close(); // 闭合路径

  final Paint arrowPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill; // 填充三角形

  // 绘制箭头
  canvas.drawPath(arrowPath, arrowPaint);

  // 恢复画布的状态
  canvas.restore();
}
