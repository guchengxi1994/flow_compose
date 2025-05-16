import 'package:flutter/material.dart';

import 'inode.dart';

class NodeListWidget extends StatefulWidget {
  const NodeListWidget({super.key, required this.nodes});
  final List<INode> nodes;

  @override
  State<NodeListWidget> createState() => _NodeListWidgetState();
}

class _NodeListWidgetState extends State<NodeListWidget> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: isExpanded ? EdgeInsets.all(20) : EdgeInsets.all(5),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            ...widget.nodes.map((e) => Draggable(
                data: e, feedback: e.fakeWidget(), child: _buildNode(e)))
          ],
        ),
      ),
    );
  }

  Widget _buildNode(INode node) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: Icon(Icons.note_rounded),
          ),
          SizedBox(
            width: 20,
          ),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                node.nodeName,
                style: TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
              Tooltip(
                message: node.description,
                waitDuration: Duration(milliseconds: 500),
                child: Text(
                  node.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              )
            ],
          ))
        ],
      ),
    );
  }
}
