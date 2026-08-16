import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';

class NodeListWidget extends StatefulWidget {
  const NodeListWidget({super.key, required this.controller});
  // final Map<String, SidebarNodeWidgetBuilder?> sidebarNodeRenderRegistry;
  final BoardController controller;

  @override
  State<NodeListWidget> createState() => _NodeListWidgetState();
}

class _NodeListWidgetState extends State<NodeListWidget> {
  bool isExpanded = false;
  late List<String> supportedTypes =
      widget.controller.nodeRenderRegistry.keys.toList();

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
            ...supportedTypes.map((e) => Draggable(
                data: e, feedback: fakeWidget(e), child: _buildNode(e)))
          ],
        ),
      ),
    );
  }

  Widget fakeWidget(String type) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 100,
        height: 50,
        child: Center(
          child: Text(type),
        ),
      ),
    );
  }

  Widget _buildNode(String type) {
    ExtraNodeConfig config = widget.controller.getExtraNodeConfig(type);
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
                type,
                style: TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
              if (config.description != null)
                Tooltip(
                  message: config.description,
                  waitDuration: Duration(milliseconds: 500),
                  child: Text(
                    config.description!,
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
