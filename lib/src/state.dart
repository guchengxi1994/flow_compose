import 'package:flow_compose/src/nodes/inode.dart';
import 'package:flutter/material.dart';

class BoardState<E> {
  final double scaleFactor;
  final Offset dragOffset;
  final List<INode> data;
  final Set<E> edges;

  BoardState({
    this.scaleFactor = 1.0,
    this.dragOffset = Offset.zero,
    this.data = const [],
    this.edges = const {},
  });

  BoardState copyWith({
    double? scaleFactor,
    Offset? dragOffset,
    List<INode>? data,
    Set<E>? edges,
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
