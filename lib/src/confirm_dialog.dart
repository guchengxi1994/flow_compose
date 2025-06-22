import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({super.key, required this.content, this.height = 150});
  final String content;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: EdgeInsets.all(10),
        width: 300,
        height: height,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
        child: Column(
          children: [
            Expanded(child: Text(content)),
            SizedBox(
              height: 30,
              child: Row(
                spacing: 10,
                children: [
                  Spacer(),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop(false);
                    },
                    child: Icon(
                      Icons.cancel_rounded,
                      color: Colors.red,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop(true);
                    },
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
