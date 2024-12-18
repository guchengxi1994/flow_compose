import 'dart:math';

import 'package:flutter/material.dart';

void paintBezierEdge(
    Canvas canvas, double scale, Offset start, Offset end, Offset offset) {
  var s = (start * scale + offset);
  var e = (end * scale + offset);

  var controlPoint = Offset(s.dx + (e.dx - s.dx) / 2, s.dy);
  final paint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0;

  final path = Path()
    ..moveTo(s.dx, s.dy)
    ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, e.dx, e.dy);

  canvas.drawPath(path, paint);
}

void paintBezierEdgeWithArrow(
    Canvas canvas, double scale, Offset start, Offset end, Offset offset) {
  var s = (start * scale + offset);
  var e = (end * scale + offset);

  // var controlPoint = Offset(s.dx + (e.dx - s.dx) / 2, s.dy);
  // 计算控制点位置（动态生成控制点）
  final controlPoint = Offset(
    (s.dx + e.dx) / 2, // 控制点 x 为起点和终点的中点
    min(s.dy, e.dy) - 50, // 控制点 y 位于两点之上，使曲线弯曲
  );

  final paint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0;

  final arrowPaint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.fill;

  final path = Path();
  path.moveTo(s.dx, s.dy);
  path.quadraticBezierTo(
    controlPoint.dx,
    controlPoint.dy,
    e.dx,
    e.dy,
  );
  canvas.drawPath(path, paint);

  // 计算箭头的方向
  final arrowAngle = pi / 6; // 箭头的开口角度
  final arrowLength = 12.0; // 箭头的长度

  // 曲线的切线方向（根据终点和控制点计算）
  final tangent = Offset(
    e.dx - controlPoint.dx,
    e.dy - controlPoint.dy,
  ).direction;

  // 箭头的两个点
  final arrowPoint1 = Offset(
    e.dx - arrowLength * cos(tangent - arrowAngle),
    e.dy - arrowLength * sin(tangent - arrowAngle),
  );
  final arrowPoint2 = Offset(
    e.dx - arrowLength * cos(tangent + arrowAngle),
    e.dy - arrowLength * sin(tangent + arrowAngle),
  );

  // 绘制箭头
  final arrowPath = Path()
    ..moveTo(e.dx, e.dy)
    ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
    ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
    ..close();

  canvas.drawPath(arrowPath, arrowPaint);
}
