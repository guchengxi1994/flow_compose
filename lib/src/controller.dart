import 'package:flow_compose/src/state.dart';
import 'package:flutter/material.dart';

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
