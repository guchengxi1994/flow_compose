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
    return Material(
      color: Colors.white,
      elevation: 10,
      borderRadius:
          isExpanded ? BorderRadius.circular(20) : BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: AnimatedContainer(
          width: isExpanded ? 300 : 50,
          height: isExpanded ? 800 : 50,
          decoration: BoxDecoration(
            borderRadius: isExpanded
                ? BorderRadius.circular(20)
                : BorderRadius.circular(10),
            color: Colors.transparent,
          ),
          duration: Duration(milliseconds: 500),
          child: isExpanded
              ? Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 30,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          ...widget.nodes.map((e) => Draggable(
                              data: e,
                              feedback: e.fakeWidget(),
                              child: _buildNode(e)))
                        ],
                      ),
                    ),
                    Positioned(
                        top: 10,
                        left: 10,
                        child: SizedBox(
                          height: 30,
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    isExpanded = false;
                                  });
                                },
                                child: Transform.flip(
                                  flipY: true,
                                  child: Icon(Icons.expand_more),
                                ),
                              )
                            ],
                          ),
                        ))
                  ],
                )
              : InkWell(
                  onTap: () {
                    setState(() {
                      isExpanded = true;
                    });
                  },
                  child: Icon(Icons.expand_more),
                ),
        ),
      ),
    );
  }

  Widget _buildNode(INode node) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
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
              Text(
                node.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              )
            ],
          ))
        ],
      ),
    );
  }
}
