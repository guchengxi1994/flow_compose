import 'dart:convert';

import 'package:example/nodes/sql_node.dart';
import 'package:example/style.dart';
import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_json_view/flutter_json_view.dart';

import 'nodes/login_node.dart';
import 'nodes/simple_qa_node.dart';
import 'nodes/start_node.dart';

void main() {
  runApp(const MyApp());
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final controller =
      BoardController(initialState: BoardState(data: [], edges: {}), nodes: [
    StartNode(
      label: "开始",
      uuid: "",
      depth: -1,
      offset: Offset.zero,
    ),
    LoginNode(
      label: "Login",
      uuid: "",
      depth: -1,
      offset: Offset.zero,
    ),
    SimpleQaNode(
      label: "Simple QA",
      uuid: "",
      depth: -1,
      offset: Offset.zero,
    ),
    SqlNode(
      label: "SQL Node",
      uuid: "",
      depth: -1,
      offset: Offset.zero,
    )
  ]);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InfiniteDrawingBoard(
        controller: controller,
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
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
                  List<INode> nodes = [];
                  List<Edge> edges = [];
                  for (var node in data["nodes"]) {
                    // nodes.add(INode.fromJson(node));
                    if (node['builderName'] == "StartNode") {
                      nodes.add(StartNode.fromJson(node));
                    } else if (node['builderName'] == "SqlNode") {
                      nodes.add(SqlNode.fromJson(node));
                    } else if (node['builderName'] == "SimpleQaNode") {
                      nodes.add(SimpleQaNode.fromJson(node));
                    } else if (node['builderName'] == "LoginNode") {
                      nodes.add(LoginNode.fromJson(node));
                    } else {
                      nodes.add(INode.fromJson(node));
                    }
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
        ],
      ),
    );
  }
}
