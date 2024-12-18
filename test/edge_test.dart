import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('曲线绘制示例')),
        body: Center(
          child: CustomPaint(
            size: Size(300, 200), // 画布大小
            painter: HorizontalCurvePainter(),
          ),
        ),
      ),
    );
  }
}

class HorizontalCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();

    // 起始水平线
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width * 0.2, size.height / 2);

    // 中间曲线
    path.quadraticBezierTo(
      size.width * 0.5, // 控制点 x
      size.height * 0.1, // 控制点 y
      size.width * 0.8, // 结束点 x
      size.height / 2, // 结束点 y
    );

    // 终止水平线
    path.lineTo(size.width, size.height / 2);

    // 绘制路径
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
