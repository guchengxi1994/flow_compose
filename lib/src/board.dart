import 'package:flow_compose/flow_compose.dart';
import 'package:flow_compose/src/annotation.dart';
import 'package:flow_compose/src/nodes/nodes.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'paints/paints.dart';

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
    boardNotifier.value = boardNotifier.value
        .copyWith(dragOffset: boardNotifier.value.dragOffset + offset);
  }

  void _paintEdgeFromAToB(String a, String b) {
    INode? aNode = boardNotifier.value.data
        .where((element) => element.getUuid() == a)
        .firstOrNull;

    INode? bNode = boardNotifier.value.data
        .where((element) => element.getUuid() == b)
        .firstOrNull;

    if (aNode != null && bNode != null) {
      Edge edge = Edge(
          uuid: uuid.v4(),
          source: aNode.getUuid(),
          target: bNode.getUuid(),
          start: aNode.outputPoint,
          end: bNode.inputPoint);
      Set<Edge> edges = boardNotifier.value.edges as Set<Edge>;
      edges.add(edge);
      boardNotifier.value = boardNotifier.value.copyWith(edges: edges.toSet());
    }
  }

  // ignore: avoid_init_to_null
  String? currentUuid = null;
  var uuid = Uuid();

  @Features(features: [FeaturesType.all])
  void _modifyFakeEdge(INode start, Offset offset) {
    currentUuid ??= uuid.v4();
    // print("start.outputPoint ${start.outputPoint}");

    Edge? fakeEdge = (boardNotifier.value.edges as Set<Edge>)
        .where(
          (element) => element.uuid == currentUuid,
        )
        .firstOrNull;
    if (fakeEdge != null) {
      fakeEdge = fakeEdge.copyWith(
          end: fakeEdge.end + offset * 1 / boardNotifier.value.scaleFactor);
      boardNotifier.value = boardNotifier.value.copyWith(
        edges: (boardNotifier.value.edges as Set<Edge>).map((e) {
          if (e.uuid == fakeEdge!.uuid) {
            return fakeEdge;
          }
          return e;
        }).toSet(),
      );
    } else {
      fakeEdge = Edge(
        source: start.getUuid(),
        end: start.outputPoint,
        uuid: currentUuid!,
        start: start.outputPoint,
      );
      Set<Edge> edges = boardNotifier.value.edges as Set<Edge>;
      edges.add(fakeEdge);
      boardNotifier.value = boardNotifier.value.copyWith(
        edges: edges.toSet(),
      );
    }
  }

  void _handleNodeEdgeCancel() {
    Set<Edge> edges = boardNotifier.value.edges as Set<Edge>;
    edges.removeWhere((element) => element.uuid == currentUuid);
    boardNotifier.value = boardNotifier.value.copyWith(
      edges: edges.toSet(),
    );
    currentUuid = null;
  }

  void _handleNodeDrag(String uuid, Offset offset, double factor) {
    var data = boardNotifier.value.data;
    data = data.map((e) {
      if (e.getUuid() == uuid) {
        return e.copyWith(offset: e.offset + offset * 1 / factor);
      }
      return e;
    }).toList();

    var edges = boardNotifier.value.edges as Set<Edge>;
    if (edges.isNotEmpty) {
      edges = edges.map((e) {
        if (e.source == uuid) {
          return e.copyWith(start: e.start + offset * 1 / factor);
        }
        if (e.target == uuid) {
          return e.copyWith(end: e.end + offset * 1 / factor);
        }
        return e;
      }).toSet();
    }

    boardNotifier.value =
        boardNotifier.value.copyWith(data: data, edges: edges.toSet());
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
                  child = Stack(
                    children: [
                      Container(
                        color: Colors.transparent,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      ...state.data.map((e) {
                        return NodeWidget<INode>(
                          node: e,
                          dragOffset: state.dragOffset,
                          factor: state.scaleFactor,
                          onNodeDrag: (offset) {
                            _handleNodeDrag(
                                e.getUuid(), offset, state.scaleFactor);
                          },
                          onNodeEdgeCreateOrModify: (offset) {
                            _modifyFakeEdge(e, offset);
                          },
                          onNodeEdgeCancel: () {
                            _handleNodeEdgeCancel();
                          },
                          onEdgeAccept: (from, to) {
                            _paintEdgeFromAToB(from, to);
                          },
                        );
                      })
                    ],
                  );
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
  final Set<E> edges;

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

    // if (data.isNotEmpty) {
    //   if (data[0] is FishboneNode) {
    //     paintFishbone(canvas, size, data as List<FishboneNode>);
    //   }
    // }

    if (edges.isNotEmpty) {
      for (Edge e in edges as Set<Edge>) {
        paintBezierEdgeWithArrow(canvas, scale, e.start, e.end, offset);
      }
    }
  }

  @Deprecated("for test")
  void paintFishbone(Canvas canvas, Size size, List<FishboneNode> data) {
    paintMain(canvas, size, data, offset, scale);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // 每次更新需要重新绘制
  }
}
