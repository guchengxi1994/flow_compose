import 'package:example/style.dart';
import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';

class SimpleQAWidget extends StatefulWidget {
  const SimpleQAWidget({super.key, required this.node});
  final SimpleQaNode node;

  @override
  State<SimpleQAWidget> createState() => _SimpleQAWidgetState();
}

class _SimpleQAWidgetState extends State<SimpleQAWidget> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        debugPrint("double tap");
      },
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        width: widget.node.width,
        height: widget.node.height,
        child: SingleChildScrollView(
          child: Column(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("输入"),
              TextField(
                controller: _inputController,
                decoration: inputDecoration,
              ),
              Text("输出"),
              TextField(
                controller: _outputController,
                decoration: inputDecoration,
              ),
              Text("提示词"),
              TextField(
                controller: _promptController,
                decoration: inputDecoration,
                maxLines: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SimpleQaNode extends INode {
  SimpleQaNode({
    required super.label,
    required super.uuid,
    required super.depth,
    required super.offset,
    super.children,
    super.height = 400,
    super.width = 300,
    super.nodeName = "单输入输出问答节点",
    super.description = "仅支持一个输入和一个输出的节点",
    super.builder,
  }) {
    builder = (context) => SimpleQAWidget(
          node: this,
        );
  }

  @override
  INode copyWith(
      {double? width,
      double? height,
      String? label,
      String? uuid,
      int? depth,
      Offset? offset,
      List<INode>? children,
      Map<String, dynamic>? data}) {
    return SimpleQaNode(
        width: width ?? this.width,
        height: height ?? this.height,
        label: label ?? this.label,
        uuid: uuid ?? this.uuid,
        depth: depth ?? this.depth,
        offset: offset ?? this.offset,
        children: children ?? this.children);
  }
}
