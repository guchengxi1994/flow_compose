import 'package:flow_compose/src/nodes/inode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef OnNodeDrag = void Function(Offset offset);

typedef OnNodeEdgeCreateOrModify = void Function(Offset offset);

typedef OnEdgeAccept = void Function(String from, String to);

typedef OnNodeDelete = void Function(String uuid);

typedef OnNodeFocus<T extends INode> = void Function(T node);

class NodeWidget<T extends INode> extends StatefulWidget {
  const NodeWidget(
      {super.key,
      required this.node,
      required this.dragOffset,
      required this.factor,
      required this.onNodeDrag,
      required this.onNodeEdgeCreateOrModify,
      required this.onNodeEdgeCancel,
      required this.onEdgeAccept,
      required this.onNodeDelete,
      this.onNodeFocus,
      this.isFocused = false,
      required this.isEditable,
      required this.hasPrev});
  final T node;
  final Offset dragOffset;
  final double factor;
  final OnNodeDrag onNodeDrag;
  final OnNodeEdgeCreateOrModify onNodeEdgeCreateOrModify;
  final VoidCallback onNodeEdgeCancel;
  final OnEdgeAccept onEdgeAccept;
  final OnNodeDelete onNodeDelete;
  final OnNodeFocus? onNodeFocus;
  final bool isFocused;
  final bool isEditable;
  final bool hasPrev;

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState<T extends INode> extends State<NodeWidget> {
  bool willAccept = false;

  @override
  Widget build(BuildContext context) {
    T node = widget.node as T;
    Offset offset = node.offset;
    double width = node.width;
    double height = node.height;
    String label = node.label;
    String uuid = node.uuid;
    double factor = widget.factor;
    Offset dragOffset = widget.dragOffset;
    bool isFocused = widget.isFocused;

    return Positioned(
      left: offset.dx * factor + dragOffset.dx,
      top: offset.dy * factor + dragOffset.dy,
      child: Material(
        elevation: isFocused ? 10 : 4,
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            GestureDetector(
                onTap: () {
                  widget.onNodeFocus?.call(node);
                },
                onPanUpdate: (details) {
                  // print(details);
                  widget.onNodeDrag(details.delta);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blueAccent),
                    color: Colors.white,
                  ),
                  width: width * factor,
                  height: height * factor,
                  alignment: Alignment.center,
                  child: node.builder == null
                      ? Text(
                          label,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        )
                      : node.builder!(context, node),
                )),
            Positioned(
                right: 0,
                top: 0,
                child: InkWell(
                    onTap: () {
                      debugPrint("delete $uuid");
                      widget.onNodeDelete(uuid);
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete,
                        color: const Color.fromARGB(255, 237, 118, 118),
                        size: 16,
                      ),
                    ))),
            Positioned(
                right: 0,
                top: 0.2 * height * factor,
                child: MouseRegion(
                  cursor: widget.isEditable
                      ? SystemMouseCursors.grab
                      : SystemMouseCursors.forbidden,
                  child: Draggable(
                      data: uuid,
                      onDragUpdate: (details) {
                        if (widget.isEditable) {
                          // print(details);
                          widget.onNodeEdgeCreateOrModify(details.delta);
                        }
                      },
                      onDragEnd: (details) {
                        widget.onNodeEdgeCancel();
                      },
                      feedback: Container(
                        width: 5,
                        height: 5,
                        color: kDebugMode ? Colors.red : Colors.transparent,
                      ),
                      child: Container(
                        width: 5,
                        height: 0.6 * height * factor,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          // color: Colors.white,
                          color: Colors.blueAccent,
                        ),
                        // child: Icon(
                        //   Icons.output,
                        //   color: Colors.grey[300],
                        //   size: 16,
                        // ),
                      )),
                )),
            Positioned(
                left: 1,
                top: 0.2 * height * factor,
                child: DragTarget<String>(
                  builder: (c, _, __) {
                    return Container(
                      width: 5,
                      height: 0.6 * height * factor,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          // color: Colors.blueAccent,
                          color: willAccept
                              ? Colors.greenAccent
                              : widget.hasPrev
                                  ? Colors.blueAccent
                                  : Colors.grey[100]),
                      // child: Icon(
                      //   Icons.input,
                      //   color: willAccept ? Colors.green : Colors.grey[300],
                      //   size: 16,
                      // ),
                    );
                  },
                  onWillAcceptWithDetails: (details) {
                    if (details.data == uuid) {
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
                    debugPrint("accept ${data.data} this is $uuid");
                    widget.onEdgeAccept(data.data, uuid);
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
