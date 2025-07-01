import 'package:example/toast_utils.dart';
import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension Excuter on NodeModel {
  Future<void> execute(WidgetRef ref) async {
    // 执行节点逻辑
    debugPrint('Executing node: $label ===> $data');
    // ref.read(workflowProvider.notifier).changeCurrentNode(this);
    await Future.delayed(Duration(seconds: 3));
  }
}

class WorkflowGraph {
  final List<NodeModel> nodes;
  final List<Edge> edges;

  final Map<String, List<String>> adjList = {};
  final Map<String, int> inDegree = {};

  WorkflowGraph(this.nodes, this.edges) {
    // 初始化图
    for (var node in nodes) {
      adjList[node.uuid] = [];
      inDegree[node.uuid] = 0;
    }

    // 添加边关系
    for (var edge in edges) {
      if (edge.target != null) {
        adjList[edge.source]?.add(edge.target!);
        inDegree[edge.target!] = (inDegree[edge.target] ?? 0) + 1;
      }
    }
  }

  void executeWorkflow(WidgetRef ref) async {
    // 拓扑排序
    final executionOrder = _topologicalSort();
    debugPrint('Execution order: $executionOrder');
    if (executionOrder == null) {
      throw Exception('Workflow is not a DAG!');
    }

    ToastUtils.sucess(null, title: "workflow started ...");
    // 按顺序执行节点
    for (var nodeId in executionOrder) {
      final node = nodes.firstWhere((n) => n.uuid == nodeId);
      await node.execute(ref);
    }
    // ref.read(workflowProvider.notifier).changeCurrentNode(null);
    ToastUtils.sucess(null, title: "workflow done ...");
  }

  List<String>? _topologicalSort() {
    final queue = <String>[];
    final result = <String>[];

    // 入度为0的节点入队
    inDegree.forEach((node, degree) {
      if (degree == 0) queue.add(node);
    });

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      result.add(current);

      for (var neighbor in adjList[current] ?? []) {
        inDegree[neighbor] = (inDegree[neighbor] ?? 0) - 1;
        if (inDegree[neighbor] == 0) queue.add(neighbor);
      }
    }

    // 如果结果数量和节点数量不一致，说明有环
    return result.length == nodes.length ? result : null;
  }
}
