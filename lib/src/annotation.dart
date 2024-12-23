class NotReady {
  final String info;

  const NotReady({this.info = "This feature is not ready yet!"});
}

/// 有些状态修改可能还没办法做到自适应；
/// 比如画板拖拽/缩放等，可能导致多个状态
/// 修改，可能存在遗漏的情况
enum FeaturesType {
  // 自适应节点状态
  adaptiveNodeState,
  // 自适应画板状态
  adaptiveBoardState,
  // 自适应边状态
  adaptiveEdgeState,
  all,
}

class Features {
  final List<FeaturesType> features;

  const Features({required this.features});
}
