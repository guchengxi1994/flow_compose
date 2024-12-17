import 'package:flutter/gestures.dart';
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
        body: InfiniteDrawingBoard(),
      ),
    );
  }
}

class InfiniteDrawingBoard extends StatefulWidget {
  const InfiniteDrawingBoard({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _InfiniteDrawingBoardState createState() => _InfiniteDrawingBoardState();
}

class _InfiniteDrawingBoardState extends State<InfiniteDrawingBoard> {
  // ignore: unused_field
  final TransformationController _transformationController =
      TransformationController();
  double _scaleFactor = 1.0; // 初始缩放比例

  Offset _dragOffset = Offset.zero; // 当前的偏移量

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _dragOffset += details.delta;
        });
      },
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            setState(() {
              // 减少滚轮滚动幅度
              double zoomChange = pointerSignal.scrollDelta.dy * -0.002;
              // 设置最小滚动阈值，避免小幅滚动过于灵敏
              if (zoomChange.abs() < 0.01) {
                return;
              }

              _scaleFactor += zoomChange;
              // 限制缩放范围
              _scaleFactor = _scaleFactor.clamp(0.1, 10.0);
            });
          }
        },
        child: CustomPaint(
          painter: InfiniteCanvasPainter(
            offset: _dragOffset,
            scale: _scaleFactor,
          ),
          child: Container(),
        ),
      ),
    );
  }
}

class InfiniteCanvasPainter extends CustomPainter {
  final Offset offset;
  final double scale;

  InfiniteCanvasPainter({required this.offset, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 应用缩放和偏移
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // 绘制网格
    final double gridSize = 50.0;
    for (double i = -2000; i < 2000; i += gridSize) {
      // 垂直线
      canvas.drawLine(
        Offset(i, -2000),
        Offset(i, 2000),
        paint,
      );
      // 水平线
      canvas.drawLine(
        Offset(-2000, i),
        Offset(2000, i),
        paint,
      );
    }

    // 绘制额外内容（示例：一个圆）
    paint.color = Colors.red;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, 0), 100, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // 每次更新需要重新绘制
  }
}
