import 'dart:math';

import 'package:flutter/material.dart';

const double gap = 5;

double sigmoid(double x) {
  return 1 / (1 + exp(-x));
}

void dynamicEdgePaint(
    Canvas canvas, double scale, Offset start, Offset end, /*偏移*/ Offset offset,
    {bool withArrow = true}) {
  final arrowPaint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.fill;
  final paint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0;

  final path = Path();

  var s = (start * scale + offset);
  var e = (end * scale + offset);
  var controlPoint = e;
  path.moveTo(s.dx, s.dy);

  if ((s.dx - e.dx).abs() > 100) {
    s = s + Offset(gap, 0);
    path.lineTo(s.dx, s.dy);
  }

  // 起始高度和终止高度差不多在同一高度，不需要绘制曲线
  if ((s.dy - e.dy).abs() <= 10) {
    path.lineTo(e.dx, e.dy);
  } else {
    var subE = Offset(e.dx - gap * 3, e.dy);
    double distance = 50;

    distance = e.dy * sigmoid((s.dy - subE.dy).abs());

    // 计算控制点位置（动态生成控制点）
    controlPoint = Offset(
      (s.dx + e.dx) * 0.5,
      (e.dy + distance) / 2,
    );

    path.conicTo(controlPoint.dx, controlPoint.dy, subE.dx, subE.dy, 1);

    path.lineTo(e.dx - gap, e.dy);
  }

  canvas.drawPath(path, paint);
  if (withArrow) {
    // 计算箭头的方向
    final arrowAngle = pi / 6; // 箭头的开口角度
    final arrowLength = 12.0; // 箭头的长度

    // 曲线的切线方向（根据终点和控制点计算）
    final tangent = 0;

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
}
