import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';

class EdgeListWidget extends StatefulWidget {
  const EdgeListWidget({super.key, required this.controller});
  final BoardController controller;

  @override
  State<EdgeListWidget> createState() => _EdgeListWidgetState();
}

class _EdgeListWidgetState extends State<EdgeListWidget> {
  @override
  Widget build(BuildContext context) {
    final edges = widget.controller.state.value.edges.toList();
    return ListView.builder(
      padding: EdgeInsets.only(top: 50),
      itemBuilder: (context, index) {
        return _EdgeBuilder(
          edge: edges[index],
          onRemove: (Edge e) {
            setState(() {
              widget.controller.removeEdge(e);
            });
          },
          onFocus: (Edge e) {
            if (e.uuid != "fake") {
              widget.controller.moveToOffset((e.start + e.end) / 2);
            }
            widget.controller.setEdgeFocused(e);
          },
        );
      },
      itemCount: edges.length,
    );
  }
}

class _EdgeBuilder extends StatefulWidget {
  const _EdgeBuilder(
      {required this.edge,
      required this.onRemove,
      // ignore: unused_element
      this.onFocus});
  final Edge edge;
  final void Function(Edge) onRemove;
  final void Function(Edge)? onFocus;

  @override
  State<_EdgeBuilder> createState() => __EdgeBuilderState();
}

class __EdgeBuilderState extends State<_EdgeBuilder> {
  bool onHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onEnter: (event) {
          setState(() {
            onHover = true;
          });
          if (widget.onFocus != null) {
            widget.onFocus!(widget.edge);
          }
        },
        onExit: (event) {
          setState(() {
            onHover = false;
          });
          if (widget.onFocus != null) {
            widget.onFocus!(Edge(
                uuid: "fake",
                source: "fake",
                start: Offset(0, 0),
                end: Offset(0, 0)));
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: onHover ? Colors.lightBlueAccent : Colors.transparent,
          ),
          height: 30,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  child: Text(
                "${widget.edge.source} ----> ${widget.edge.target}",
                maxLines: 1,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, color: onHover ? Colors.white : Colors.black),
              )),
              InkWell(
                  onTap: () {
                    widget.onRemove(widget.edge);
                  },
                  child: const Icon(Icons.delete))
            ],
          ),
        ));
  }
}
