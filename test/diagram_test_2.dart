import 'package:flutter/material.dart';

import 'dart:math';

class FishboneNode {
  final String label; // 节点名称
  final double angle; // 相对于父节点的偏转角度 (以弧度为单位)
  final double distance; // 相对于父节点的偏移距离
  final List<FishboneNode> children; // 子节点列表

  FishboneNode({
    required this.label,
    this.angle = 0.0,
    this.distance = 100.0,
    this.children = const [],
  });
}

class FishbonePainter extends CustomPainter {
  final FishboneNode rootNode; // 鱼骨图根节点
  final Offset rootPosition; // 根节点的初始位置
  final Color lineColor; // 线条颜色
  final double lineWidth; // 线条宽度

  FishbonePainter({
    required this.rootNode,
    this.rootPosition = const Offset(200, 200),
    this.lineColor = Colors.black,
    this.lineWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    // 从根节点开始递归绘制
    _drawNode(canvas, paint, rootNode, rootPosition);
  }

  void _drawNode(
      Canvas canvas, Paint paint, FishboneNode node, Offset position) {
    // 绘制当前节点的文字
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.label,
        style: TextStyle(color: Colors.black, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(position.dx - textPainter.width / 2,
            position.dy - textPainter.height / 2));

    // 绘制子节点及连接线
    for (var child in node.children) {
      // 计算子节点位置
      final double dx = position.dx + cos(child.angle) * child.distance;
      final double dy = position.dy + sin(child.angle) * child.distance;
      final childPosition = Offset(dx, dy);

      // 绘制连接线
      canvas.drawLine(position, childPosition, paint);

      // 递归绘制子节点
      _drawNode(canvas, paint, child, childPosition);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class FishboneDiagramPage extends StatelessWidget {
  const FishboneDiagramPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 构建鱼骨图数据
    final rootNode = FishboneNode(
      label: "Main Topic",
      children: [
        FishboneNode(
          label: "Branch 1",
          angle: -pi / 4, // 偏转 45 度向上
          distance: 150,
          children: [
            FishboneNode(
                label: "Sub-Branch 1.1", angle: -pi / 6, distance: 100),
            FishboneNode(
                label: "Sub-Branch 1.2", angle: -pi / 3, distance: 100),
          ],
        ),
        FishboneNode(
          label: "Branch 2",
          angle: pi / 4, // 偏转 45 度向下
          distance: 150,
          children: [
            FishboneNode(label: "Sub-Branch 2.1", angle: pi / 6, distance: 100),
            FishboneNode(label: "Sub-Branch 2.2", angle: pi / 3, distance: 100),
          ],
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text("Fishbone Diagram")),
      body: Center(
        child: CustomPaint(
          size: Size(400, 400),
          painter: FishbonePainter(rootNode: rootNode),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(home: FishboneDiagramPage()));
}
