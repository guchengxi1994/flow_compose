import 'package:flow_compose/src/nodes/edge.dart';
import 'package:flow_compose/src/nodes/inode.dart';
import 'package:flutter/material.dart';

class BoardState {
  final double scaleFactor;
  final Offset dragOffset;
  final List<INode> data;
  final Set<Edge> edges;
  INode? focus;
  Edge? edgeFocused;
  Size? paintSize;

  BoardState({
    this.scaleFactor = 1.0,
    this.dragOffset = Offset.zero,
    this.data = const [],
    this.edges = const {},
    this.focus,
    this.edgeFocused,
    this.paintSize,
  });

  BoardState copyWith({
    double? scaleFactor,
    Offset? dragOffset,
    List<INode>? data,
    Set<Edge>? edges,
    INode? focus,
    Edge? edgeFocused,
    Size? paintSize,
  }) {
    return BoardState(
      scaleFactor: scaleFactor ?? this.scaleFactor,
      dragOffset: dragOffset ?? this.dragOffset,
      data: data ?? this.data,
      edges: edges ?? this.edges,
      focus: focus,
      edgeFocused: edgeFocused,
      paintSize: paintSize ?? this.paintSize,
    );
  }

  @override
  String toString() {
    return 'BoardState{scaleFactor: $scaleFactor, dragOffset: $dragOffset}';
  }
}
