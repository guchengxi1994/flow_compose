class BoardStyle {
  final double sidebarMaxWidth;
  final double sidebarMinWidth;
  final double sidebarMaxHeight;
  final double sidebarMinHeight;

  const BoardStyle({
    this.sidebarMaxWidth = 240,
    this.sidebarMinWidth = 30,
    this.sidebarMaxHeight = 600,
    this.sidebarMinHeight = 30,
  });

  BoardStyle copyWith({
    double? sidebarMaxWidth,
    double? sidebarMinWidth,
    double? sidebarMaxHeight,
    double? sidebarMinHeight,
  }) {
    return BoardStyle(
      sidebarMaxWidth: sidebarMaxWidth ?? this.sidebarMaxWidth,
      sidebarMinWidth: sidebarMinWidth ?? this.sidebarMinWidth,
      sidebarMaxHeight: sidebarMaxHeight ?? this.sidebarMaxHeight,
      sidebarMinHeight: sidebarMinHeight ?? this.sidebarMinHeight,
    );
  }
}
