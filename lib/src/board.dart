import 'package:collection/collection.dart';
import 'package:flow_compose/flow_compose.dart';
import 'package:flow_compose/src/annotation.dart';
import 'package:flow_compose/src/confirm_dialog.dart';
import 'package:flow_compose/src/nodes/edge_list.dart';
import 'package:flow_compose/src/nodes/node_list_widget.dart';
import 'package:flow_compose/src/nodes/nodes.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'nodes/expanable_widget.dart';
import 'paints/paints.dart';

class InfiniteDrawingBoard extends StatefulWidget {
  const InfiniteDrawingBoard({super.key, required this.controller});
  final BoardController controller;

  @override
  State<InfiniteDrawingBoard> createState() => _InfiniteDrawingBoardState();
}

class _InfiniteDrawingBoardState extends State<InfiniteDrawingBoard> {
  late ValueNotifier<BoardState> boardNotifier = widget.controller.state;

  @Features(features: [
    FeaturesType.adaptiveBoardState,
    FeaturesType.adaptiveEdgeState
  ])
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

  // left +
  // right -
  // top +
  // bottom -
  @Features(features: [FeaturesType.all])
  void _handleDragUpdate(Offset offset) {
    boardNotifier.value = boardNotifier.value
        .copyWith(dragOffset: boardNotifier.value.dragOffset + offset);
    // debugPrint("${boardNotifier.value.dragOffset}");
  }

  @Features(features: [FeaturesType.all])
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
      Set<Edge> edges = boardNotifier.value.edges;
      edges.add(edge);
      boardNotifier.value = boardNotifier.value.copyWith(edges: edges.toSet());
      if (widget.controller.onEdgeCreated != null) {
        widget.controller.onEdgeCreated!(edge);
      }
    }
  }

  // ignore: avoid_init_to_null
  String? currentUuid = null;
  var uuid = Uuid();

  @Features(features: [FeaturesType.all])
  void _modifyFakeEdge(INode start, Offset offset) {
    currentUuid ??= uuid.v4();
    // print("start.outputPoint ${start.outputPoint}");

    Edge? fakeEdge = (boardNotifier.value.edges)
        .where(
          (element) => element.uuid == currentUuid,
        )
        .firstOrNull;
    if (fakeEdge != null) {
      fakeEdge = fakeEdge.copyWith(
          end: fakeEdge.end + offset * 1 / boardNotifier.value.scaleFactor);
      boardNotifier.value = boardNotifier.value.copyWith(
        edges: (boardNotifier.value.edges).map((e) {
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
      Set<Edge> edges = boardNotifier.value.edges;
      edges.add(fakeEdge);
      boardNotifier.value = boardNotifier.value.copyWith(
        edges: edges.toSet(),
      );
    }
  }

  @Features(features: [FeaturesType.all])
  void _handleNodeEdgeCancel() {
    Set<Edge> edges = boardNotifier.value.edges;
    edges.removeWhere((element) => element.uuid == currentUuid);
    boardNotifier.value = boardNotifier.value.copyWith(
      edges: edges.toSet(),
    );
    currentUuid = null;
  }

  @Features(features: [FeaturesType.all])
  void _handleNodeDelete(String uuid) async {
    bool? delete = false;
    if (widget.controller.confirmBeforeDelete) {
      delete = await showGeneralDialog(
          barrierDismissible: true,
          barrierColor: Colors.transparent,
          barrierLabel: 'ConfirmDialog',
          context: context,
          pageBuilder: (c, _, __) {
            return Center(
              child: ConfirmDialog(
                content: "确定删除吗？",
                height: 80,
              ),
            );
          }) as bool?;
    }

    if (delete == true) {
      Set<Edge> edges = boardNotifier.value.edges;
      List<INode> nodes = boardNotifier.value.data;
      nodes.removeWhere((element) => element.uuid == uuid);
      edges.removeWhere(
          (element) => element.source == uuid || element.target == uuid);
      boardNotifier.value = boardNotifier.value.copyWith(
        edges: edges.toSet(),
        data: nodes,
      );
    }
  }

  @Features(features: [FeaturesType.all])
  void _addNewNode(INode node) {
    boardNotifier.value = boardNotifier.value.copyWith(
      data: boardNotifier.value.data.toList()..add(node),
    );
    node.onStatusChanged!(node, EventType.nodeCreated);
  }

  @Features(features: [FeaturesType.all])
  void _handleNodeDrag(String uuid, Offset offset, double factor) {
    var data = boardNotifier.value.data;
    data = data.map((e) {
      if (e.getUuid() == uuid) {
        return e.copyWith(offset: e.offset + offset * 1 / factor);
      }
      return e;
    }).toList();

    var edges = boardNotifier.value.edges;
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

  @Features(features: [FeaturesType.all])
  _handleNotFocus(INode? node) {
    boardNotifier.value = boardNotifier.value.copyWith(
      focus: node,
    );
  }

  @override
  void dispose() {
    boardNotifier.dispose();
    super.dispose();
  }

  final eq = const DeepCollectionEquality().equals;

  void _populatePrevData(List<INode> data, Set<Edge> edges) {
    // 创建 uuid -> INode 的快速索引
    final Map<String, INode> nodeMap = {
      for (var node in data) node.uuid: node,
    };

    for (var edge in edges) {
      final sourceNode = nodeMap[edge.source];
      final targetNode = nodeMap[edge.target];

      // 安全性检查
      if (sourceNode == null || targetNode == null) continue;

      targetNode.prevData ??= targetNode.prevData ?? {};

      // final map = (sourceNode.data ?? {})..addAll(sourceNode.prevData);
      Map<String, Map<String, dynamic>?> map = {};
      if (sourceNode.prevData != null) {
        map.addAll(sourceNode.prevData!);
      }
      map[sourceNode.uuid] = sourceNode.data;

      if (!eq(targetNode.prevData, map)) {
        targetNode.onStatusChanged!(
            targetNode, EventType.nodePrevStatusChanged);
      }

      targetNode.prevData = map;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.white,
        child: ClipRect(
          child: ValueListenableBuilder(
            valueListenable: boardNotifier,
            builder: (context, state, child) {
              Widget child = DragTarget<INode>(
                builder: (c, _, __) {
                  // debugPrint("repaint edge");
                  _populatePrevData(state.data, state.edges);
                  return Stack(
                    children: [
                      GestureDetector(
                          onTap: () {
                            _handleNotFocus(null);
                          },
                          behavior: HitTestBehavior.deferToChild,
                          onPanUpdate: (details) {
                            _handleDragUpdate(details.delta);
                          },
                          child: Listener(
                              onPointerSignal: (pointerSignal) {
                                if (pointerSignal is PointerScrollEvent) {
                                  _handleScaleUpdate(
                                      pointerSignal.scrollDelta.dy);
                                }
                              },
                              child: Container(
                                color: Colors.transparent,
                                width: double.infinity,
                                height: double.infinity,
                              ))),
                      ...state.data.map((e) {
                        print("e.uuid  ${e.uuid}");

                        return NodeWidget<INode>(
                          hasPrev: e.prevData != null && e.prevData!.isNotEmpty,
                          isEditable: state.editable,
                          node: e,
                          dragOffset: state.dragOffset,
                          factor: state.scaleFactor,
                          isFocused: e.getUuid() == state.focus?.getUuid(),
                          onNodeDelete: (u) {
                            _handleNodeDelete(u);
                          },
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
                          onNodeFocus: (node) {
                            _handleNotFocus(node);
                          },
                        );
                      }),
                      if (state.editable)
                        Positioned(
                            left: 20,
                            top: 20,
                            child: ExpanableWidget(
                              maxWidth: widget.controller.style.sidebarMaxWidth,
                              maxHeight:
                                  widget.controller.style.sidebarMaxHeight,
                              child1: NodeListWidget(
                                nodes: widget.controller.nodes,
                              ),
                              child2:
                                  EdgeListWidget(controller: widget.controller),
                            ))
                    ],
                  );
                },
                onAcceptWithDetails: (details) {
                  debugPrint(
                      "drag offset ${state.dragOffset}  accept details ${details.offset}  abslute ${details.offset - state.dragOffset}");
                  RenderBox box = context.findRenderObject() as RenderBox;
                  Offset localOffset = box.globalToLocal(details.offset);

                  // final node = details.data.copyWith(
                  //     uuid: uuid.v4(),
                  //     offset: (details.offset - state.dragOffset) *
                  //         1 /
                  //         state.scaleFactor);
                  final node = details.data.copyWith(
                    uuid: uuid.v4(),
                    offset: (localOffset - state.dragOffset) *
                        (1 / state.scaleFactor),
                  );
                  node.onStatusChanged ??= (n, e) {
                    widget.controller.streamController
                        .add((NodeData(n.uuid), e));
                  };
                  _addNewNode(node);
                },
              );

              return CustomPaint(
                painter: InfiniteCanvasPainter(
                    offset: state.dragOffset,
                    scale: state.scaleFactor,
                    data: state.data,
                    edges: state.edges,
                    focusedEdge: state.edgeFocused,
                    controller: widget.controller),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

const double _boldGap = 200;

class InfiniteCanvasPainter extends CustomPainter {
  final Offset offset;
  final double scale;
  final List<INode> data;
  final Set<Edge> edges;
  final Edge? focusedEdge;
  final BoardController controller;

  InfiniteCanvasPainter(
      {required this.offset,
      required this.scale,
      required this.data,
      required this.edges,
      this.focusedEdge,
      required this.controller});

  @override
  void paint(Canvas canvas, Size size) {
    controller.setSize(size);
    final Paint paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;

    final Paint paintBold = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 应用缩放和偏移
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // 绘制网格
    final double gridSize = 50.0;
    for (double i = -2000; i <= 2000; i += gridSize) {
      // 垂直线
      if (i % _boldGap == 0) {
        canvas.drawLine(
          Offset(i, -2000),
          Offset(i, 2000),
          paintBold,
        );
      } else {
        canvas.drawLine(
          Offset(i, -2000),
          Offset(i, 2000),
          paint,
        );
      }
      // 水平线
      if (i % _boldGap == 0) {
        canvas.drawLine(
          Offset(-2000, i),
          Offset(2000, i),
          paintBold,
        );
      } else {
        canvas.drawLine(
          Offset(-2000, i),
          Offset(2000, i),
          paint,
        );
      }
    }

    canvas.restore();

    // if (data.isNotEmpty) {
    //   if (data[0] is FishboneNode) {
    //     paintFishbone(canvas, size, data as List<FishboneNode>);
    //   }
    // }

    if (edges.isNotEmpty) {
      for (Edge e in edges) {
        if (e == focusedEdge) {
          dynamicEdgePaint(canvas, scale, e.start, e.end, offset,
              color: Colors.red);
        } else {
          dynamicEdgePaint(canvas, scale, e.start, e.end, offset);
        }
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
