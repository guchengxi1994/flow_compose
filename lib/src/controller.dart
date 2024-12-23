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

  void reCenter() {
    state.value = state.value.copyWith(
      dragOffset: Offset.zero,
    );
  }

  void dispose() {
    state.dispose();
  }

  List<String> getPath(INode node) {
    Map<String, String> m = _buildReverseMap();
    return _findPathToRoot(node.uuid, m);
  }

  Map<String, String> _buildReverseMap() {
    final edges = state.value.edges.toList();

    final reverseMap = <String, String>{};
    for (var edge in edges) {
      if (edge.target != null) {
        reverseMap[edge.target!] = edge.source;
      }
    }
    return reverseMap;
  }

  List<String> _findPathToRoot(String uuid, Map<String, String> reverseMap) {
    final path = <String>[];
    var current = uuid;
    while (reverseMap.containsKey(current)) {
      path.add(current);
      current = reverseMap[current]!;
    }
    path.add(current); // 最后添加根节点
    return path.reversed.toList(); // 返回从根节点到指定子节点的路径
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

  @Deprecated("has some bug, use `reCreate` instead")
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
