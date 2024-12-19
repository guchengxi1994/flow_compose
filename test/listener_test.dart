// ignore_for_file: avoid_print

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ParentWidget(),
    );
  }
}

class ParentWidget extends StatelessWidget {
  const ParentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("事件拦截示例")),
      body: Stack(
        children: [
          Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                print("父组件捕获滚轮事件: ${event.scrollDelta}");
              }
            },
            child: Container(
              color: Colors.blue,
              child: Center(
                child: Text(
                  "父组件",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: 50,
            child: ChildWidget(),
          ),
        ],
      ),
    );
  }
}

class ChildWidget extends StatelessWidget {
  const ChildWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Listener(
      // onPointerSignal: (event) {
      //   if (event is PointerScrollEvent) {
      //     print("子组件捕获滚轮事件: ${event.scrollDelta}");
      //     // 消耗事件，阻止传递到父组件
      //   }
      // },
      behavior: HitTestBehavior.opaque, // 确保可以拦截事件
      child: GestureDetector(
        onPanUpdate: (details) {},
        child: Material(
          color: Colors.white,
          elevation: 10,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: AnimatedContainer(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.transparent,
              ),
              duration: Duration(milliseconds: 500),
              child: InkWell(
                onTap: () {},
                child: Icon(Icons.expand_more),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
