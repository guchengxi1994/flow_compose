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
}
