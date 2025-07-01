import 'package:example/hammer/hammer.dart';
import 'package:example/style.dart';
import 'package:example/workflow/workflow_notifier.dart';
import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlparser/sqlparser.dart' as sql;

import 'show_node_config_dialog.dart';

class SqlNodeConfigWidget extends ConsumerStatefulWidget {
  const SqlNodeConfigWidget({super.key, this.data});
  final Map<String, dynamic>? data;

  @override
  ConsumerState<SqlNodeConfigWidget> createState() =>
      _SqlNodeConfigWidgetState();
}

class _SqlNodeConfigWidgetState extends ConsumerState<SqlNodeConfigWidget> {
  late final TextEditingController _sqlController = TextEditingController()
    ..text = widget.data?["sql"]?.toString() ?? "";
  late List<String> _params =
      (widget.data?["params"] as List?)?.map((e) => e.toString()).toList() ??
          [];

  final engine = sql.SqlEngine();

  @override
  void dispose() {
    _sqlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodeInfo =
        ref.read(workflowProvider.notifier).controller.state.value.data;

    for (final i in nodeInfo) {
      debugPrint("${i.uuid} ${i.nodeName} ${i.data} ${i.prevData}");
    }

    return SingleChildScrollView(
      child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SQL"),
            TextField(
              onChanged: (value) {
                try {
                  final parsed = engine.parse(value);
                  final selectStatement =
                      parsed.rootNode as sql.SelectStatement;
                  final columns = selectStatement.columns
                      .whereType<sql.ExpressionResultColumn>() // 确保是有效的列
                      .map((col) => col.expression.toString())
                      .toList();
                  debugPrint("字段名: $columns");
                  setState(() {
                    _params = columns;
                  });
                } catch (_) {
                  debugPrint("sql 解析错误");
                }
              },
              controller: _sqlController,
              decoration: inputDecoration,
            ),
            Text("参数"),
            Wrap(spacing: 10, runSpacing: 10, children: [
              ..._params.map((e) => Chip(
                  label: Text(e),
                  onDeleted: () {
                    setState(() {
                      _params.remove(e);
                    });
                  }))
            ]),
            SizedBox(
              height: 40,
            ),
            SizedBox(
                height: 40,
                child: Row(children: [
                  Spacer(),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context,
                            {"sql": _sqlController.text, "params": _params});
                      },
                      child: Text("确定"))
                ]))
          ]),
    );
  }
}

class SqlNodeWidget extends StatefulWidget {
  const SqlNodeWidget({super.key, required this.node});
  final INode node;

  @override
  State<SqlNodeWidget> createState() => _SqlNodeWidgetState();
}

class _SqlNodeWidgetState extends State<SqlNodeWidget> {
  late Map<String, dynamic> data =
      widget.node.data ?? {"sql": "", "params": []};

  @override
  Widget build(BuildContext context) {
    return HammerAnimation(
        uuid: widget.node.uuid,
        child: GestureDetector(
          onDoubleTap: () {
            showNodeConfigDialog(context, widget.node, data: data).then((v) {
              debugPrint("sql $v");
              if (v != null) {
                setState(() {
                  // widget.node.data = v;
                  data = v;
                });
                widget.node.data = data;
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
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("params"),
                Expanded(
                    child: Wrap(
                  children: (data['params'] as List)
                      .map((v) => Chip(label: Text(v.toString())))
                      .toList(),
                ))
              ],
            ),
          ),
        ));
  }
}

class SqlNode extends INode {
  SqlNode(
      {required super.label,
      required super.uuid,
      required super.offset,
      super.description = "SQL节点执行SQL语句",
      super.height = 150,
      super.width = 300,
      super.nodeName = "SQL节点",
      super.builderName = "SqlNode",
      super.data,
      super.builder}) {
    builder = (c, n) => SqlNodeWidget(node: n);
  }

  factory SqlNode.fromJson(Map<String, dynamic> json) {
    String uuid = json["uuid"] ?? "";
    String label = json["label"] ?? "";
    Offset offset = Offset(json["offset"]["dx"], json["offset"]["dy"]);
    double width = json["width"] ?? 300;
    double height = json["height"] ?? 400;
    String nodeName = json["nodeName"] ?? "base";
    String description =
        json["description"] ?? "Base node, just for testing purposes";
    String builderName = json["builderName"] ?? "base";
    Map<String, dynamic>? data = json["data"];

    return SqlNode(
      offset: offset,
      width: width,
      height: height,
      nodeName: nodeName,
      description: description,
      builderName: builderName,
      label: label,
      uuid: uuid,
      data: data,
    );
  }
}
