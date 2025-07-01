import 'dart:convert';

import 'package:example/style.dart';
import 'package:example/workflow/workflow_graph.dart';
import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import 'workflow/workflow_notifier.dart';

void main() {
  runApp(ToastificationWrapper(
    child: ProviderScope(child: MyApp()),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // final state = ref.watch(workflowProvider.notifier);
    final controller = ref.read(workflowProvider.notifier).controller;
    return Scaffold(
      body: InfiniteDrawingBoard(
        controller: controller,
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        distance: 50,
        type: ExpandableFabType.up,
        children: [
          FloatingActionButton.small(
            tooltip: "re center",
            heroTag: null,
            child: const Icon(Icons.center_focus_strong),
            onPressed: () {
              controller.reCenter();
            },
          ),
          FloatingActionButton.small(
            tooltip: "clear",
            heroTag: null,
            child: const Icon(Icons.clear_all),
            onPressed: () {
              controller.clear();
            },
          ),
          FloatingActionButton.small(
            tooltip: "excute",
            heroTag: null,
            child: const Icon(Icons.start),
            onPressed: () {
              WorkflowGraph graph = WorkflowGraph(controller.state.value.data,
                  controller.state.value.edges.toList());

              Future.microtask(() async {
                graph.executeWorkflow(ref);
              });
            },
          ),
          FloatingActionButton.small(
            tooltip: "From json",
            heroTag: null,
            child: const Icon(Icons.edit),
            onPressed: () {
              final textController = TextEditingController();
              showGeneralDialog(
                  barrierDismissible: true,
                  barrierLabel: "json",
                  context: context,
                  pageBuilder: (c, _, __) {
                    return Center(
                      child: Material(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          width: 600,
                          height: 400,
                          child: TextField(
                            controller: textController,
                            decoration: inputDecoration,
                            maxLines: 20,
                          ),
                        ),
                      ),
                    );
                  }).then((_) {
                if (textController.text.isNotEmpty) {
                  Map<String, dynamic> data = jsonDecode(textController.text);
                  List<NodeModel> nodes = [];
                  List<Edge> edges = [];
                  for (var node in data["nodes"]) {
                    // nodes.add(INode.fromJson(node));
                    nodes.add(NodeModel.fromJson(node));
                  }
                  for (var edge in data["edges"]) {
                    edges.add(Edge.fromJson(edge));
                  }

                  controller.reCreate(nodes, edges);
                }
              });
            },
          ),
          FloatingActionButton.small(
            tooltip: "To Json",
            heroTag: null,
            child: const Icon(Icons.abc),
            onPressed: () {
              debugPrint(controller.dumpToString());
              showGeneralDialog(
                  barrierDismissible: true,
                  barrierLabel: "json",
                  context: context,
                  pageBuilder: (c, _, __) {
                    return Center(
                      child: Material(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          width: 600,
                          height: 400,
                          child: JsonView.string(controller.dumpToString()),
                        ),
                      ),
                    );
                  });
            },
          ),
          FloatingActionButton.small(
            tooltip: "switch mode",
            heroTag: null,
            child: const Icon(Icons.switch_access_shortcut),
            onPressed: () {
              controller.changeEditableStatus(!controller.state.value.editable);
            },
          ),
        ],
      ),
    );
  }
}
