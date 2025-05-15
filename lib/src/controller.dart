import 'dart:convert';

import 'package:flow_compose/src/nodes/edge.dart';
import 'package:flow_compose/src/nodes/inode.dart';
import 'package:flow_compose/src/state.dart';
import 'package:flutter/material.dart';

class BoardController {
  final ValueNotifier<BoardState> state;
  // nodes which can be dragged to board
  final List<INode> nodes;

  BoardController({
    BoardState? initialState,
    required this.nodes,
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
  }

  List<List<String>> getPath(INode node) {
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

  setCurrentFocus(INode? node) {
    if (node == value.focus) {
      return;
    }
    state.value = state.value.copyWith(focus: node);
  }

  String dumpToString() {
    List<Edge> edges = state.value.edges.toList();
    List<INode> nodes = state.value.data;
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

  @Deprecated(
      "has some bug, use `reCreate` instead, will be removed in the future")
  void loadFromString(String json) {
    Map<String, dynamic> data = jsonDecode(json);
    List<INode> nodes = [];
    List<Edge> edges = [];
    for (var node in data["nodes"]) {
      nodes.add(INode.fromJson(node));
    }
    for (var edge in data["edges"]) {
      edges.add(Edge.fromJson(edge));
    }

    state.value = BoardState(data: nodes, edges: edges.toSet());
  }

  void reCreate(List<INode> nodes, List<Edge> edges) {
    state.value = BoardState(data: nodes, edges: edges.toSet());
  }
}
