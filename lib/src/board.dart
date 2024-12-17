import 'package:fishbone/fishbone.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'fishbone.dart';

class BoardState<T> {
  final double scaleFactor;
  final Offset dragOffset;
  final List<T> data;

  BoardState({
    this.scaleFactor = 1.0,
    this.dragOffset = Offset.zero,
    this.data = const [],
  });

  BoardState copyWith({
    double? scaleFactor,
    Offset? dragOffset,
    List<T>? data,
  }) {
    return BoardState(
      scaleFactor: scaleFactor ?? this.scaleFactor,
      dragOffset: dragOffset ?? this.dragOffset,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return 'BoardState{scaleFactor: $scaleFactor, dragOffset: $dragOffset}';
  }
}

class BoardController {
  final ValueNotifier<BoardState> state;

  BoardController({
    BoardState? initialState,
  }) : state = ValueNotifier(initialState ?? BoardState());

  BoardState get value => state.value;

  set value(BoardState newValue) {
    state.value = newValue;
  }

  void reCenter() {
    state.value = state.value.copyWith(
      dragOffset: Offset.zero,
    );
  }

  void dispose() {
    state.dispose();
  }
}

class InfiniteDrawingBoard extends StatefulWidget {
  const InfiniteDrawingBoard({super.key, this.controller});
  final BoardController? controller;

  @override
  State<InfiniteDrawingBoard> createState() => _InfiniteDrawingBoardState();
}

class _InfiniteDrawingBoardState extends State<InfiniteDrawingBoard> {
  late ValueNotifier<BoardState> boardNotifier =
      widget.controller?.state ?? ValueNotifier(BoardState());

  void _handleScaleUpdate(double scrollDelta) {
    // 减少滚轮滚动幅度
    double zoomChange = scrollDelta * -0.002;
    // 设置最小滚动阈值，避免小幅滚动过于灵敏
    if (zoomChange.abs() < 0.01) {
      return;
    }
    double r = (boardNotifier.value.scaleFactor + zoomChange).clamp(0.5, 2);
    if (r == boardNotifier.value.scaleFactor) {
      return;
    }

    boardNotifier.value = boardNotifier.value.copyWith(scaleFactor: r);
  }

  void _handleDragUpdate(Offset offset) {
    boardNotifier.value = boardNotifier.value.copyWith(
      dragOffset: boardNotifier.value.dragOffset + offset,
    );
  }

  void _handleNodeDrag(String uuid, Offset offset, double factor) {
    boardNotifier.value = boardNotifier.value.copyWith(
      data: (boardNotifier.value.data as List<BaseNode>).map((e) {
        if (e.uuid == uuid) {
          return e.copyWith(offset: e.offset + offset * 1 / factor);
        }
        return e;
      }).toList(),
    );
  }

  @override
  void dispose() {
    boardNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onPanUpdate: (details) {
          _handleDragUpdate(details.delta);
        },
        child: Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                _handleScaleUpdate(pointerSignal.scrollDelta.dy);
              }
            },
            child: ValueListenableBuilder(
              valueListenable: boardNotifier,
              builder: (context, state, child) {
                Widget child = Container();
                if (state.data.isNotEmpty) {
                  if (state.data[0] is BaseNode) {
                    child = Stack(
                      children: [
                        Container(
                          color: Colors.transparent,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        ...state.data.map((e) {
                          return (e as BaseNode).build(
                            dragOffset: state.dragOffset,
                            factor: state.scaleFactor,
                            onNodeDrag: (offset) {
                              _handleNodeDrag(
                                  e.uuid, offset, state.scaleFactor);
                            },
                          );
                        })
                      ],
                    );
                  }
                }

                return CustomPaint(
                  painter: InfiniteCanvasPainter(
                      offset: state.dragOffset,
                      scale: state.scaleFactor,
                      data: state.data),
                  child: child,
                );
              },
            )));
  }
}

class InfiniteCanvasPainter<T> extends CustomPainter {
  final Offset offset;
  final double scale;
  final List<T> data;

  InfiniteCanvasPainter(
      {required this.offset, required this.scale, required this.data});

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
    for (double i = -2000; i <= 2000; i += gridSize) {
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

    canvas.restore();

    if (data.isNotEmpty) {
      if (data[0] is FishboneNode) {
        paintFishbone(canvas, size, data as List<FishboneNode>);
      }
    }
  }

  void paintFishbone(Canvas canvas, Size size, List<FishboneNode> data) {
    paintMain(canvas, size, data, offset, scale);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // 每次更新需要重新绘制
  }
}
