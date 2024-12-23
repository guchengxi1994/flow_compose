import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: HammerAnimation()));

class HammerAnimation extends StatefulWidget {
  const HammerAnimation({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HammerAnimationState createState() => _HammerAnimationState();
}

class _HammerAnimationState extends State<HammerAnimation>
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
    return Scaffold(
      appBar: AppBar(title: Text('Hammer Animation')),
      body: Center(
        child: SlideTransition(
          position: _positionAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: RotationTransition(
              turns: _rotationAnimation,
              child: Image.asset('assets/hammer.png', width: 100, height: 100),
            ),
          ),
        ),
      ),
    );
  }
}
