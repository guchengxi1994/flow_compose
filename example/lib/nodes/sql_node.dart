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
      debugPrint("${i.uuid} ${i.type} ${i.data} ${i.prevData}");
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
  final NodeModel node;

  @override
  State<SqlNodeWidget> createState() => _SqlNodeWidgetState();
}

class _SqlNodeWidgetState extends State<SqlNodeWidget> {
  late Map<String, dynamic> data =
      widget.node.data.isEmpty ? {"sql": "", "params": []} : widget.node.data;

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
            padding: const EdgeInsets.all(10),
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
