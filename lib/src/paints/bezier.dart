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
