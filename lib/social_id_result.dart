import 'dart:typed_data';

import 'package:flutter/material.dart';

class SocialIdResultPage extends StatefulWidget {
  final Uint8List front;
  final Uint8List back;

  const SocialIdResultPage(
      {super.key, required this.front, required this.back});

  @override
  State<StatefulWidget> createState() => SocialIdResultState();
}

class SocialIdResultState extends State<SocialIdResultPage> {
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
            Image.memory(widget.front,
                width: double.infinity, fit: BoxFit.contain),
            SizedBox(height: 32),
            Image.memory(widget.back,
                width: double.infinity, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}
