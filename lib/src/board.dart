import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BoardState<T, E> {
  final double scaleFactor;
  final Offset dragOffset;
  final List<T> data;
  final List<E> edges;

  BoardState({
    this.scaleFactor = 1.0,
    this.dragOffset = Offset.zero,
    this.data = const [],
    this.edges = const [],
  });

  BoardState copyWith({
    double? scaleFactor,
    Offset? dragOffset,
    List<T>? data,
    List<E>? edges,
  }) {
    return BoardState(
      scaleFactor: scaleFactor ?? this.scaleFactor,
      dragOffset: dragOffset ?? this.dragOffset,
      data: data ?? this.data,
      edges: edges ?? this.edges,
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

  // ignore: avoid_init_to_null
  String? currentUuid = null;
  var uuid = Uuid();

  void _modifyFakeEdge(BaseNode start, Offset offset) {
    currentUuid ??= uuid.v4();
    // print("start.outputPoint ${start.outputPoint}");

    Edge? fakeEdge = (boardNotifier.value.edges as List<Edge>)
        .where(
          (element) => element.uuid == currentUuid,
        )
        .firstOrNull;
    if (fakeEdge != null) {
      fakeEdge = fakeEdge.copyWith(end: fakeEdge.end + offset);
      boardNotifier.value = boardNotifier.value.copyWith(
        edges: (boardNotifier.value.edges as List<Edge>).map((e) {
          if (e.uuid == fakeEdge!.uuid) {
            return fakeEdge;
          }
          return e;
        }).toList(),
      );
    } else {
      fakeEdge = Edge(
        source: start.uuid,
        end: start.outputPoint,
        uuid: currentUuid!,
        start: start.outputPoint,
      );
      List<Edge> edges = boardNotifier.value.edges as List<Edge>;
      edges.add(fakeEdge);
      boardNotifier.value = boardNotifier.value.copyWith(
        edges: edges,
      );
    }
  }

  void _handleNodeEdgeCancel() {
    List<Edge> edges = boardNotifier.value.edges as List<Edge>;
    edges.removeWhere((element) => element.uuid == currentUuid);
    boardNotifier.value = boardNotifier.value.copyWith(
      edges: edges,
    );
    currentUuid = null;
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
                            onNodeEdgeCreate: (offset) {
                              _modifyFakeEdge(e, offset);
                            },
                            onNodeEdgeCancel: () {
                              _handleNodeEdgeCancel();
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
                      data: state.data,
                      edges: state.edges),
                  child: child,
                );
              },
            )));
  }
}

class InfiniteCanvasPainter<T, E> extends CustomPainter {
  final Offset offset;
  final double scale;
  final List<T> data;
  final List<E> edges;

  InfiniteCanvasPainter(
      {required this.offset,
      required this.scale,
      required this.data,
      required this.edges});

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

    if (edges.isNotEmpty) {
      for (Edge e in edges as List<Edge>) {
        paintBezierEdge(canvas, scale, e.start, e.end);
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
