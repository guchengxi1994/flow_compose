enum EventType {
  nodePrevStatusChanged,
  nodeDataChanged,
  edgeCreated,
  edgeRemoved,
  nodeCreated,
  nodeRemoved
}

sealed class EventData {
  final String uuid;
  EventData(this.uuid);
}

class NodeData extends EventData {
  NodeData(super.uuid);
}

class EdgeData extends EventData {
  EdgeData(super.uuid);
}
