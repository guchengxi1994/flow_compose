import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';

class StartNodeWidget extends StatelessWidget {
  const StartNodeWidget({super.key, required this.node});
  final NodeModel node;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      width: node.width,
      height: node.height,
      child: Center(
        child: Text(node.label),
      ),
    );
  }
}
