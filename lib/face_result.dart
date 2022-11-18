import 'dart:typed_data';

import 'package:flutter/material.dart';

class FaceResultPage extends StatefulWidget {
  final Uint8List data;

  const FaceResultPage({super.key, required this.data});

  @override
  State<StatefulWidget> createState() => FaceResultState();
}

class FaceResultState extends State<FaceResultPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kết quả"),
      ),
      body: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.memory(widget.data,
                width: double.infinity, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}
