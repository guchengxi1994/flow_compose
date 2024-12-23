import 'package:example/style.dart';
import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';

import 'show_node_config_dialog.dart';

class LoginNodeConfigWidget extends StatefulWidget {
  const LoginNodeConfigWidget({super.key, required this.data});
  final Map<String, dynamic>? data;

  @override
  State<LoginNodeConfigWidget> createState() => _LoginNodeConfigWidgetState();
}

class _LoginNodeConfigWidgetState extends State<LoginNodeConfigWidget> {
  late final TextEditingController _usernameController = TextEditingController()
    ..text = widget.data?["username"]?.toString() ?? "";
  late final TextEditingController _passwordController = TextEditingController()
    ..text = widget.data?["password"]?.toString() ?? "";
  late final TextEditingController _outputKeyController =
      TextEditingController()
        ..text = widget.data?["outputkey"]?.toString() ?? "";

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _outputKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("用户名"),
          TextField(
            controller: _usernameController,
            decoration: inputDecoration,
          ),
          Text("密码"),
          TextField(
            obscureText: true,
            controller: _passwordController,
            decoration: inputDecoration,
          ),
          Text("Ouput key"),
          TextField(
            controller: _outputKeyController,
            decoration: inputDecoration,
          ),
          SizedBox(
            height: 40,
          ),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Spacer(),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        "username": _usernameController.text,
                        "password": _passwordController.text,
                        "outputkey": _outputKeyController.text,
                      });
                    },
                    child: Text("确定"))
              ],
            ),
          )
        ],
      ),
    );
  }
}

class LoginNode extends INode {
  LoginNode(
      {required super.label,
      required super.uuid,
      required super.offset,
      super.children,
      super.description = "登录节点，获取登录身份校验信息",
      super.height = 100,
      super.width = 200,
      super.nodeName = "登录节点",
      super.builderName = "LoginNode",
      super.data}) {
    builder = (context) => GestureDetector(
          onDoubleTap: () async {
            await showNodeConfigDialog(context, this, data: data).then((v) {
              if (v != null) {
                data = v;
              }
            });
          },
          child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              width: width,
              height: height,
              child: Center(
                child: Text("登录信息"),
              )),
        );
  }

  factory LoginNode.fromJson(Map<String, dynamic> json) {
    String uuid = json["uuid"] ?? "";
    String label = json["label"] ?? "";
    Offset offset = Offset(json["offset"]["dx"], json["offset"]["dy"]);
    double width = json["width"] ?? 300;
    double height = json["height"] ?? 400;
    String nodeName = json["nodeName"] ?? "base";
    String description =
        json["description"] ?? "Base node, just for testing purposes";
    String builderName = json["builderName"] ?? "base";
    Map<String, dynamic>? data = json["data"];

    return LoginNode(
      offset: offset,
      width: width,
      height: height,
      nodeName: nodeName,
      description: description,
      builderName: builderName,
      label: label,
      uuid: uuid,
      data: data,
    );
  }

  @override
  INode copyWith(
      {double? width,
      double? height,
      String? label,
      String? uuid,
      int? depth,
      Offset? offset,
      List<INode>? children,
      Map<String, dynamic>? data}) {
    return LoginNode(
        width: width ?? this.width,
        height: height ?? this.height,
        label: label ?? this.label,
        uuid: uuid ?? this.uuid,
        offset: offset ?? this.offset,
        children: children ?? this.children);
  }
}
