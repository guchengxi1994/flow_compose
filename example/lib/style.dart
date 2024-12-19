import 'package:flutter/material.dart';

const appColor = Color.fromARGB(255, 132, 142, 209);

const InputDecoration inputDecoration = InputDecoration(
    errorStyle: TextStyle(height: 0),
    hintStyle:
        TextStyle(color: Color.fromARGB(255, 159, 159, 159), fontSize: 12),
    contentPadding: EdgeInsets.only(left: 10, bottom: 15),
    border: InputBorder.none,
    // focusedErrorBorder:
    //     OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
    focusedErrorBorder:
        OutlineInputBorder(borderSide: BorderSide(color: appColor)),
    errorBorder:
        OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: appColor)),
    enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(255, 159, 159, 159))));
