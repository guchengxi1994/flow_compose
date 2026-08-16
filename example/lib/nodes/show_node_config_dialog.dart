import 'package:example/nodes/sql_node.dart';
import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';

import 'login_node.dart';
import 'simple_qa_node.dart';

Future<Map<String, dynamic>?> showNodeConfigDialog(
    BuildContext context, NodeModel node,
    {Map<String, dynamic>? data, String name = "节点配置"}) async {
  if (node.type == "SimpleQaNode") {
    return showGeneralDialog(
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        barrierDismissible: true,
        barrierLabel: "SimpleQaNode Dialog",
        context: context,
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.all(20),
                width: 300,
                height: 800,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(name),
                    Expanded(
                        child: SimpleQAConfigWidget(
                      data: data,
                    ))
                  ],
                ),
              ),
            ),
          );
        });
  }

  if (node.type == "LoginNode") {
    return showGeneralDialog(
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        barrierDismissible: true,
        barrierLabel: "Login Dialog",
        context: context,
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.all(20),
                width: 300,
                height: 800,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(name),
                    Expanded(
                        child: LoginNodeConfigWidget(
                      data: data,
                    ))
                  ],
                ),
              ),
            ),
          );
        });
  }

  if (node.type == "SqlNode") {
    return showGeneralDialog(
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        barrierDismissible: true,
        barrierLabel: "SQL Dialog",
        context: context,
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.all(20),
                width: 300,
                height: 800,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(name),
                    Expanded(
                        child: SqlNodeConfigWidget(
                      data: data,
                    ))
                  ],
                ),
              ),
            ),
          );
        });
  }

  return null;
}
