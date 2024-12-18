class NotReady {
  final String info;

  const NotReady({this.info = "This feature is not ready yet!"});
}

enum FeaturesType {
  boardDrag,
  boardScaleChange,
  nodeDrag,
  nodeDelete,
  all,
}

class Features {
  final List<FeaturesType> features;

  const Features({required this.features});
}
