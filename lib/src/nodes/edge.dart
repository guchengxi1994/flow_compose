import 'package:flutter/material.dart';

typedef OnNodeDrag = void Function(Offset offset);
// typedef OnBoardSizeChange = void Function(double factor);
typedef OnNodeEdgeCreateOrModify = void Function(Offset offset);

typedef OnEdgeAccept = void Function(String from, String to);

typedef OnNodeDelete = void Function(String uuid);

class Edge {
  final String uuid;
  final String source;
  final String? target;

  final Offset start;
  final Offset end;

  factory Edge.fromJson(Map<String, dynamic> json) {
    return Edge(
      uuid: json['uuid'] as String,
      source: json['source'] as String,
      target: json['target'] as String?,
      start: Offset(json["start"]["dx"], json["start"]["dy"]),
      end: Offset(json["end"]["dx"], json["end"]["dy"]),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uuid': uuid,
        'source': source,
        'target': target,
        'start': {'dx': start.dx, 'dy': start.dy},
        'end': {'dx': end.dx, 'dy': end.dy},
      };

  @override
  bool operator ==(Object other) {
    return other is Edge && other.source == source && other.target == target;
  }

  Edge(
      {required this.uuid,
      required this.source,
      this.target,
      required this.start,
      required this.end});

  @override
  String toString() {
    return 'Edge{uuid: $uuid, source: $source, target: $target, start: $start, end: $end}';
  }

  Edge copyWith({
    String? uuid,
    String? source,
    String? target,
    Offset? start,
    Offset? end,
  }) {
    return Edge(
      uuid: uuid ?? this.uuid,
      source: source ?? this.source,
      target: target ?? this.target,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  @override
  int get hashCode =>
      uuid.hashCode ^
      source.hashCode ^
      target.hashCode ^
      start.hashCode ^
      end.hashCode;
}
