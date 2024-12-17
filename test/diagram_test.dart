import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: FishboneDiagram()));
}

class FishboneDiagram extends StatelessWidget {
  const FishboneDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fishbone Diagram")),
      body: Center(
        child: CustomPaint(
          size: Size(400, 300), // 设置鱼骨图的大小
          painter: FishbonePainter(),
        ),
      ),
    );
  }
}

class FishbonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 绘制主骨干
    final Offset start = Offset(50, size.height / 2);
    final Offset end = Offset(size.width - 50, size.height / 2);
    canvas.drawLine(start, end, paint);

    // 分支位置和角度
    const int numBranches = 6;
    const double branchLength = 50.0;
    const double branchAngle = 0.4; // 角度的tan值，约等于22°

    for (int i = 0; i < numBranches; i++) {
      // 上分支
      double xOffset = start.dx + (i + 1) * 60;
      Offset branchStart = Offset(xOffset, size.height / 2);
      Offset branchEnd = Offset(
        xOffset - branchLength * branchAngle,
        size.height / 2 - branchLength,
      );
      canvas.drawLine(branchStart, branchEnd, paint);

      // 下分支
      branchEnd = Offset(
        xOffset - branchLength * branchAngle,
        size.height / 2 + branchLength,
      );
      canvas.drawLine(branchStart, branchEnd, paint);
    }

    // 绘制分支文字
    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < numBranches; i++) {
      double xOffset = start.dx + (i + 1) * 60;

      // 上分支文字
      textPainter.text = TextSpan(
        text: "Cause ${i + 1}",
        style: TextStyle(color: Colors.black, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xOffset - 70, size.height / 2 - branchLength - 20),
      );

      // 下分支文字
      textPainter.text = TextSpan(
        text: "Effect ${i + 1}",
        style: TextStyle(color: Colors.black, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xOffset - 70, size.height / 2 + branchLength + 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
