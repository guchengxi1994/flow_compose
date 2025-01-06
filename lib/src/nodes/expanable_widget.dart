import 'package:flutter/material.dart';

class ExpanableWidget extends StatefulWidget {
  const ExpanableWidget(
      {super.key, required this.child1, required this.child2});
  final Widget child1;
  final Widget child2;

  @override
  State<ExpanableWidget> createState() => _ExpanableWidgetState();
}

class _ExpanableWidgetState extends State<ExpanableWidget> {
  bool isExpanded = false;

  PageController pageController = PageController();

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      borderRadius:
          isExpanded ? BorderRadius.circular(20) : BorderRadius.circular(10),
      child: Padding(
        padding: isExpanded ? EdgeInsets.all(20) : EdgeInsets.all(5),
        child: AnimatedContainer(
          width: isExpanded ? 240 : 30,
          height: isExpanded ? MediaQuery.of(context).size.height - 100 : 30,
          decoration: BoxDecoration(
            borderRadius: isExpanded
                ? BorderRadius.circular(20)
                : BorderRadius.circular(10),
            color: Colors.transparent,
          ),
          duration: Duration(milliseconds: 500),
          child: isExpanded
              ? Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: PageView(
                              controller: pageController,
                              children: [widget.child1, widget.child2]),
                        ),
                        SizedBox(
                          height: 30,
                          child: Row(
                            spacing: 10,
                            children: [
                              Spacer(),
                              SizedBox(
                                width: 30,
                                child: InkWell(
                                    onTap: () {
                                      if (pageController.page == 0) {
                                        return;
                                      }
                                      pageController.animateToPage(0,
                                          duration: Duration(milliseconds: 500),
                                          curve: Curves.easeInOut);
                                    },
                                    child: Icon(Icons.class_)),
                              ),
                              SizedBox(
                                width: 30,
                                child: InkWell(
                                    onTap: () {
                                      if (pageController.page == 1) {
                                        return;
                                      }
                                      pageController.animateToPage(1,
                                          duration: Duration(milliseconds: 500),
                                          curve: Curves.easeInOut);
                                    },
                                    child: Icon(Icons.line_axis)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                        top: 10,
                        left: 10,
                        child: SizedBox(
                          height: 30,
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    isExpanded = false;
                                  });
                                },
                                child: Transform.flip(
                                  flipY: true,
                                  child: Icon(Icons.expand_more),
                                ),
                              )
                            ],
                          ),
                        ))
                  ],
                )
              : InkWell(
                  onTap: () {
                    setState(() {
                      isExpanded = true;
                    });
                  },
                  child: Icon(Icons.expand_more),
                ),
        ),
      ),
    );
  }
}
