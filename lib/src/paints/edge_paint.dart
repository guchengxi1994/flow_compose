import 'dart:math';

import 'package:flutter/material.dart';

const double gap = 5;

double sigmoid(double x) {
  return 1 / (1 + exp(-x));
}

void dynamicEdgePaint(
  Canvas canvas,
  double scale,
  Offset start,
  Offset end,
  Offset offset, {
  bool withArrow = true,
  Color color = Colors.blue,
}) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  final arrowPaint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  final s = start * scale + offset;
  final e = end * scale + offset;

  final dx = e.dx - s.dx;
  final absDx = dx.abs();

  final shortLine = () {
    if (dx < 0) return 40.0 + absDx * 0.5;
    if (absDx < 40) return 40.0;
    return 20.0;
  }();

  final path = Path();
  path.moveTo(s.dx, s.dy);

  // 拆点：起点、短线后点、中线曲线、终点前点、终点
  final p1 = Offset(s.dx + shortLine, s.dy);
  final p4 = Offset(e.dx - shortLine, e.dy);
  final cp1 = Offset((p1.dx + p4.dx) / 2, s.dy);
  final cp2 = Offset((p1.dx + p4.dx) / 2, e.dy);

  path.lineTo(p1.dx, p1.dy); // 出口短线
  path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p4.dx, p4.dy);
  path.lineTo(e.dx, e.dy); // 入口短线

  canvas.drawPath(path, paint);

  if (withArrow) {
    const arrowAngle = pi / 6;
    const arrowLength = 12.0;
    final direction = 0.0;

    final arrowPoint1 = Offset(
      e.dx - arrowLength * cos(direction - arrowAngle),
      e.dy - arrowLength * sin(direction - arrowAngle),
    );
    final arrowPoint2 = Offset(
      e.dx - arrowLength * cos(direction + arrowAngle),
      e.dy - arrowLength * sin(direction + arrowAngle),
    );

    final arrowPath = Path()
      ..moveTo(e.dx, e.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);
  }
}
