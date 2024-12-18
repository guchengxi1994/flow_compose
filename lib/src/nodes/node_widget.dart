import 'package:flow_compose/src/nodes/base_node.dart';
import 'package:flutter/material.dart';

class NodeWidget<T extends BaseNode> extends StatefulWidget {
  const NodeWidget(
      {super.key,
      required this.node,
      required this.dragOffset,
      required this.factor,
      required this.onNodeDrag,
      required this.onNodeEdgeCreateOrModify,
      required this.onNodeEdgeCancel,
      required this.onEdgeAccept});
  final T node;
  final Offset dragOffset;
  final double factor;
  final OnNodeDrag onNodeDrag;
  final OnNodeEdgeCreateOrModify onNodeEdgeCreateOrModify;
  final VoidCallback onNodeEdgeCancel;
  final OnEdgeAccept onEdgeAccept;

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState<T extends BaseNode> extends State<NodeWidget> {
  bool willAccept = false;

  @override
  Widget build(BuildContext context) {
    late T node = widget.node as T;
    late Offset offset = node.offset;
    late double factor = widget.factor;
    late Offset dragOffset = widget.dragOffset;

    return Positioned(
      left: offset.dx * factor + dragOffset.dx,
      top: offset.dy * factor + dragOffset.dy,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            GestureDetector(
                onPanUpdate: (details) {
                  // print(details);
                  widget.onNodeDrag(details.delta);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  width: node.width * factor,
                  height: node.height * factor,
                  alignment: Alignment.center,
                  child: Text(node.label),
                )),
            Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                    onTap: () {
                      debugPrint("delete ${node.uuid}");
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                    ))),
            Positioned(
                right: 0,
                top: 0.5 * node.height * factor,
                child: Draggable(
                    data: node.uuid,
                    onDragUpdate: (details) {
                      // print(details);
                      widget.onNodeEdgeCreateOrModify(details.delta);
                    },
                    onDragEnd: (details) {
                      widget.onNodeEdgeCancel();
                    },
                    feedback: Container(
                      width: 5,
                      height: 5,
                      color: Colors.red,
                    ),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.output),
                    ))),
            Positioned(
                left: 0,
                top: 0.5 * node.height * factor,
                child: DragTarget<String>(
                  builder: (c, _, __) {
                    return Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.input,
                        color: willAccept ? Colors.green : Colors.black,
                      ),
                    );
                  },
                  onWillAcceptWithDetails: (details) {
                    if (details.data == node.uuid) {
                      return false;
                    }

                    setState(() {
                      willAccept = true;
                    });
                    return true;
                  },
                  onLeave: (details) {
                    setState(() {
                      willAccept = false;
                    });
                  },
                  onAcceptWithDetails: (data) {
                    debugPrint("accept ${data.data} this is ${node.uuid}");
                    widget.onEdgeAccept(data.data, node.uuid);
                    setState(() {
                      willAccept = false;
                    });
                  },
                ))
          ],
        ),
      ),
    );
  }
}
