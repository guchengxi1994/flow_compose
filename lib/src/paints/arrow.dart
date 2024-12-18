import 'package:flutter/material.dart';

void paintArrow(Canvas canvas, Offset end, double scale,
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
