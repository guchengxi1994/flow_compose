import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';

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
  final controller = BoardController(
      initialState: BoardState<Edge>(data: [], edges: {}),
      nodes: [
        BaseNode(
          label: "fake",
          uuid: "fake",
          depth: -1,
          offset: Offset.zero,
        ),
        StartNode(
          label: "开始",
          uuid: "",
          depth: -1,
          offset: Offset.zero,
        ),
        SimpleQaNode(
          label: "Simple QA",
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.reCenter(),
        tooltip: 're center',
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }
}
