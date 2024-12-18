import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('工作流连接曲线')),
        body: Center(
          child: CustomPaint(
            size: Size(400, 300), // 画布大小
            painter: WorkflowConnectionPainter(),
          ),
        ),
      ),
    );
  }
}

class WorkflowConnectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final arrowPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // 起点和终点
    final start = Offset(size.width * 0.2, size.height * 0.5);
    final end = Offset(size.width * 0.8, size.height * 0.3);

    // 控制点（决定曲线形状）
    final controlPoint = Offset(size.width * 0.5, size.height * 0.1);

    // 绘制平滑曲线
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      end.dx,
      end.dy,
    );
    canvas.drawPath(path, paint);

    // 计算箭头的方向
    final arrowAngle = pi / 6; // 箭头的开口角度
    final arrowLength = 12.0; // 箭头的长度

    // 曲线的切线方向（近似通过控制点和终点计算）
    final tangent = Offset(
      end.dx - controlPoint.dx,
      end.dy - controlPoint.dy,
    ).direction;

    // 箭头的两个点
    final arrowPoint1 = Offset(
      end.dx - arrowLength * cos(tangent - arrowAngle),
      end.dy - arrowLength * sin(tangent - arrowAngle),
    );
    final arrowPoint2 = Offset(
      end.dx - arrowLength * cos(tangent + arrowAngle),
      end.dy - arrowLength * sin(tangent + arrowAngle),
    );

    // 绘制箭头
    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
