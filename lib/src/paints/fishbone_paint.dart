import 'package:flutter/material.dart';
// ignore: library_prefixes
import 'dart:math' as Math;
import '../nodes/fishbone.dart';
import 'arrow.dart';

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
  paintArrow(canvas, end, scale);

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
    paintArrow(canvas, end, scale,
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
    paintArrow(canvas, end, scale,
        arrowSize: 40 / (node.depth + 1), rotation: rotation);
  }
}
