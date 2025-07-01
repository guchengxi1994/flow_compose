import 'package:example/nodes/login_node.dart';
import 'package:example/nodes/simple_qa_node.dart';
import 'package:example/nodes/sql_node.dart';
import 'package:example/nodes/start_node.dart';
import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkflowNotifier extends Notifier<INode?> {
  final controller = BoardController(
      confirmBeforeDelete: true,
      initialState: BoardState(editable: true, data: [], edges: {}),
      nodes: [
        StartNode(
          label: "开始",
          uuid: "",
          offset: Offset.zero,
        ),
        LoginNode(
          label: "Login",
          uuid: "",
          offset: Offset.zero,
        ),
        SimpleQaNode(
          label: "Simple QA",
          uuid: "",
          offset: Offset.zero,
        ),
        SqlNode(
          label: "SQL Node",
          uuid: "",
          offset: Offset.zero,
        )
      ]);

  @override
  INode? build() {
    controller.stream.listen((v) {
      bool isNode = v.$1 is NodeData;
      debugPrint("${isNode ? "node" : "edge"} ${v.$1.uuid}  ${v.$2.name}");
    });

    return null;
  }

  updateNode(INode node) {
    controller.updateNode(node);
  }

  changeCurrentNode(INode? node) {
    if (node?.getUuid() == state?.getUuid()) {
      return;
    }
    state = node;
  }

  bool isNodeSelected(INode node) {
    return state?.getUuid() == node.getUuid();
  }
}

final workflowProvider =
    NotifierProvider<WorkflowNotifier, INode?>(() => WorkflowNotifier());
