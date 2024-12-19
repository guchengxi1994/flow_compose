import 'dart:math';

import 'package:example/style.dart';
import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';

import 'show_node_config_dialog.dart';

class SimpleQAConfigWidget extends StatefulWidget {
  const SimpleQAConfigWidget({super.key, this.data});
  final Map<String, Object>? data;

  @override
  State<SimpleQAConfigWidget> createState() => _SimpleQAConfigWidgetState();
}

class _SimpleQAConfigWidgetState extends State<SimpleQAConfigWidget> {
  late final TextEditingController _inputController = TextEditingController()
    ..text = widget.data?["input"]?.toString() ?? "";
  late final TextEditingController _outputController = TextEditingController()
    ..text = widget.data?["output"]?.toString() ?? "";
  late final TextEditingController _promptController = TextEditingController()
    ..text = widget.data?["prompt"]?.toString() ?? "";

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Spacer(),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        "input": _inputController.text,
                        "output": _outputController.text,
                        "prompt": _promptController.text,
                      });
                    },
                    child: Text("确定"))
              ],
            ),
          )
        ],
      ),
    );
  }
}

class SimpleQAWidget extends StatefulWidget {
  const SimpleQAWidget({super.key, required this.node});
  final SimpleQaNode node;

  @override
  State<SimpleQAWidget> createState() => _SimpleQAWidgetState();
}

class _SimpleQAWidgetState extends State<SimpleQAWidget> {
  String input = "";
  String output = "";
  String prompt = "";

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () async {
        debugPrint("double tap");
        await showNodeConfigDialog(context, widget.node, data: {
          "input": input,
          "output": output,
          "prompt": prompt,
        }).then((v) {
          // print(v);
          if (v != null) {
            setState(() {
              input = v["input"]?.toString() ?? "";
              output = v["output"]?.toString() ?? "";
              prompt = v["prompt"]?.toString() ?? "";
            });
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        width: widget.node.width,
        height: widget.node.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            SizedBox(
              height: 30,
              child: Row(
                spacing: 10,
                children: [
                  Text("输入: "),
                  if (input.isNotEmpty)
                    Container(
                      color: Colors.lightBlue,
                      padding: EdgeInsets.all(5),
                      child: Text(
                        input,
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                ],
              ),
            ),
            SizedBox(
              height: 30,
              child: Row(
                spacing: 10,
                children: [
                  Text("输出: "),
                  if (output.isNotEmpty)
                    Container(
                      color: Colors.lightBlue,
                      padding: EdgeInsets.all(5),
                      child: Text(
                        output,
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                ],
              ),
            ),
            SizedBox(
              height: 30,
              child: Row(
                spacing: 10,
                children: [
                  Text("prompt: "),
                  if (prompt.isNotEmpty)
                    Container(
                      color: Colors.lightBlue,
                      padding: EdgeInsets.all(5),
                      child: Text(
                        "${prompt.substring(0, min(4, prompt.length))}...",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (prompt.isNotEmpty && input.isNotEmpty)
                    promptValidator(input, prompt)
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : Tooltip(
                            message: "prompt 中没有包含输入变量",
                            child: Icon(
                              Icons.close,
                              color: Colors.red,
                            ),
                          )
                ],
              ),
            ),
          ],
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
    super.height = 200,
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
