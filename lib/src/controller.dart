import 'dart:async';
import 'dart:convert';

import 'package:flow_compose/src/board_style.dart';
import 'package:flow_compose/src/nodes/nodes.dart';
import 'package:flow_compose/src/state.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

typedef OnEdgeCreated = void Function(Edge edge);

class BoardController {
  final ValueNotifier<BoardState> state;
  final Map<String, NodeWidgetBuilder> nodeRenderRegistry = {};
  final Map<String, ExtraNodeConfig?> _nodeConfigRegistry = {};

  ExtraNodeConfig getExtraNodeConfig(String nodeType) {
    return _nodeConfigRegistry[nodeType] ?? ExtraNodeConfig();
  }

  void setConfig(String nodeType, ExtraNodeConfig config) {
    if (!nodeRenderRegistry.containsKey(nodeType)) {
      return;
    }
    _nodeConfigRegistry[nodeType] = config;
  }

  final bool confirmBeforeDelete;

  final BoardStyle style;

  final OnEdgeCreated? onEdgeCreated;

  final StreamController<(EventData, EventType)> streamController =
      StreamController.broadcast();

  Stream<(EventData, EventType)> get stream => streamController.stream;

  BoardController({
    BoardState? initialState,
    this.confirmBeforeDelete = false,
    this.style = const BoardStyle(),
    this.onEdgeCreated,
  }) : state = ValueNotifier(initialState ?? BoardState());

  BoardState get value => state.value;

  set value(BoardState newValue) {
    state.value = newValue;
  }

  void setSize(Size size) {
    state.value.paintSize = size;
  }

  void clear() {
    state.value = BoardState();
  }

  void reCenter() {
    state.value = state.value.copyWith(
      dragOffset: Offset.zero,
    );
  }

  removeEdge(Edge edge) {
    state.value = state.value.copyWith(
      edges: state.value.edges.where((element) => element != edge).toSet(),
    );
  }

  setEdgeFocused(Edge edge) {
    state.value = state.value.copyWith(
      edgeFocused: edge,
    );
  }

  changeEditableStatus(bool editable) {
    if (state.value.editable == editable) {
      return;
    }

    state.value = state.value.copyWith(
      editable: editable,
    );
  }

  /// move board to offset
  moveToOffset(Offset offset) {
    reCenter();
    if (state.value.paintSize == null) {
      return;
    }

    final center = Offset(
        state.value.paintSize!.width / 2, state.value.paintSize!.height / 2);

    state.value = state.value.copyWith(
      dragOffset: center - offset,
    );
  }

  void dispose() {
    state.dispose();
    streamController.close();
  }

  List<List<String>> getPath(NodeModel node) {
    Map<String, List<String>> m = _buildReverseMap();
    return _findPathsToRoot(node.uuid, m);
  }

  Map<String, List<String>> _buildReverseMap() {
    final edges = state.value.edges;
    final reverseMap = <String, List<String>>{};
    for (var edge in edges) {
      if (edge.target != null) {
        reverseMap.putIfAbsent(edge.target!, () => []).add(edge.source);
      }
    }
    return reverseMap;
  }

  List<List<String>> _findPathsToRoot(
    String targetUuid,
    Map<String, List<String>> reverseMap,
  ) {
    // 如果节点没有父节点，说明它是根节点
    if (!reverseMap.containsKey(targetUuid)) {
      return [
        [targetUuid]
      ];
    }

    final paths = <List<String>>[];
    for (var parent in reverseMap[targetUuid]!) {
      // 递归获取父节点到根节点的所有路径
      final parentPaths = _findPathsToRoot(parent, reverseMap);
      for (var path in parentPaths) {
        paths.add([...path, targetUuid]);
      }
    }
    return paths;
  }

  setCurrentFocus(NodeModel? node) {
    if (node?.uuid == value.focused) {
      return;
    }
    state.value = state.value.copyWith(focused: node?.uuid);
  }

  String dumpToString() {
    List<Edge> edges = state.value.edges.toList();
    List<NodeModel> nodes = state.value.data;

    return """
      {
        "nodes": [
          ${nodes.map((e) => jsonEncode(e.toJson())).join(",")}
        ],
        "edges": [
          ${edges.map((e) => jsonEncode(e.toJson())).join(",")}
        ]
      }
    """;
  }

  void reCreate(List<NodeModel> nodes, List<Edge> edges) {
    state.value = BoardState(
        data: nodes, edges: edges.toSet(), editable: state.value.editable);
  }

  NodeModel? getNodeData(String uuid) {
    return state.value.data.firstWhereOrNull((element) => element.uuid == uuid);
  }

  void updateNode(NodeModel node) {
    List<NodeModel> nodes = state.value.data.map((e) {
      if (e.uuid == node.uuid) {
        return node;
      }
      return e;
    }).toList();

    state.value = state.value.copyWith(data: nodes);
  }
}
