import 'package:example/workflow/workflow_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HammerAnimation extends ConsumerStatefulWidget {
  const HammerAnimation({
    super.key,
    this.size = 30,
    required this.child,
    required this.uuid,
  });
  final double size;
  final Widget child;
  final String uuid;

  @override
  ConsumerState<HammerAnimation> createState() => _HammerAnimationState();
}

class _HammerAnimationState extends ConsumerState<HammerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 1), // 敲打一次的时间
      vsync: this,
    );

    // 缩放动画
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 旋转动画
    _rotationAnimation = Tween<double>(begin: 0.0, end: -0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 位移动画
    _positionAnimation = Tween<Offset>(begin: Offset(0, 0), end: Offset(0, 0.2))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // 循环播放动画
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workflowProvider);
    return Stack(
      children: [
        widget.child,
        if (state?.uuid == widget.uuid)
          Positioned(
              bottom: 5,
              right: 5,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: SlideTransition(
                  position: _positionAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: RotationTransition(
                      turns: _rotationAnimation,
                      child: Image.asset('assets/hammer.png',
                          width: widget.size, height: widget.size),
                    ),
                  ),
                ),
              ))
      ],
    );
  }
}
