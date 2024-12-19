import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';

import 'simple_qa_node.dart';

Future<Map<String, Object>?> showNodeConfigDialog(
    BuildContext context, INode node,
    {Map<String, Object>? data, String name = "节点配置"}) async {
  debugPrint("runtimeType: ${node.runtimeType}");
  if (node is SimpleQaNode) {
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

  return null;
}
