import 'package:flow_compose/src/nodes/edge.dart';
import 'package:flow_compose/src/nodes/node_model.dart';
import 'package:flutter/material.dart';

class BoardState {
  final double scaleFactor;
  final Offset dragOffset;
  final Set<Edge> edges;
  final List<NodeModel> data;
  String? focused;
  Edge? edgeFocused;
  Size? paintSize;
  final bool editable;

  BoardState({
    this.scaleFactor = 1.0,
    this.dragOffset = Offset.zero,
    this.edges = const {},
    this.data = const [],
    this.focused,
    this.edgeFocused,
    this.paintSize,
    this.editable = true,
  });

  BoardState copyWith({
    double? scaleFactor,
    Offset? dragOffset,
    List<NodeModel>? data,
    Set<Edge>? edges,
    String? focused,
    Edge? edgeFocused,
    Size? paintSize,
    bool? editable,
  }) {
    return BoardState(
      scaleFactor: scaleFactor ?? this.scaleFactor,
      dragOffset: dragOffset ?? this.dragOffset,
      data: data ?? this.data,
      edges: edges ?? this.edges,
      focused: focused,
      edgeFocused: edgeFocused,
      paintSize: paintSize ?? this.paintSize,
      editable: editable ?? this.editable,
    );
  }

  @override
  String toString() {
    return 'BoardState{scaleFactor: $scaleFactor, dragOffset: $dragOffset}';
  }
}
