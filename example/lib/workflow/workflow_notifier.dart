import 'package:example/nodes/login_node.dart';
import 'package:example/nodes/simple_qa_node.dart';
import 'package:example/nodes/sql_node.dart';
import 'package:example/nodes/start_node.dart';
import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkflowNotifier extends Notifier<NodeModel?> {
  final controller = BoardController(
    confirmBeforeDelete: true,
    initialState: BoardState(editable: true, data: [], edges: {}),
  );

  @override
  NodeModel? build() {
    controller.nodeRenderRegistry["LoginNode"] = (ctx, node) {
      return LoginNodeWidget(node: node);
    };
    controller.setConfig("LoginNode", ExtraNodeConfig(width: 120, height: 60));
    controller.nodeRenderRegistry["SimpleQaNode"] = (ctx, node) {
      return SimpleQAWidget(node: node);
    };
    controller.setConfig("SimpleQaNode",
        ExtraNodeConfig(width: 400, height: 300, description: "Balabla"));
    controller.nodeRenderRegistry["SqlNode"] = (ctx, node) {
      return SqlNodeWidget(node: node);
    };
    controller.setConfig(
        "SqlNode",
        ExtraNodeConfig(
            width: 200, height: 150, description: "SqlNode description"));
    controller.nodeRenderRegistry["StartNode"] = (ctx, node) {
      return StartNodeWidget(node: node);
    };

    controller.stream.listen((v) {
      bool isNode = v.$1 is NodeData;
      debugPrint("${isNode ? "node" : "edge"} ${v.$1.uuid}  ${v.$2.name}");
    });

    return null;
  }
}

final workflowProvider =
    NotifierProvider<WorkflowNotifier, NodeModel?>(() => WorkflowNotifier());
