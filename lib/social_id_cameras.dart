import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_id_camera/social_id_camera.dart';
import 'package:social_id_camera/social_id_result.dart';
import 'package:path_provider/path_provider.dart';

class SocialIdCameraPage extends StatefulWidget {
  const SocialIdCameraPage({super.key});

  @override
  State<StatefulWidget> createState() => _SocialIdCameraState();
}

class _SocialIdCameraState extends State<SocialIdCameraPage> {
  final PageController controller = PageController();
  Uint8List? frontData;
  Uint8List? backData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cung cấp chứng minh nhân dân"),
      ),
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          SocialIdCameraWidget(
            side: SocialIdCameraSide.front,
            onContinue: (Uint8List bytes) {
              controller.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease);
              frontData = bytes;
            },
          ),
          SocialIdCameraWidget(
              side: SocialIdCameraSide.back,
              onContinue: (Uint8List bytes) {
                backData = bytes;
                Navigator.of(context)
                    .pushReplacement(MaterialPageRoute(builder: (_) {
                  return SocialIdResultPage(front: frontData!, back: backData!);
                }));
              }),
        ],
      ),
    );
  }

  Future<File> _saveFile(Uint8List bytes) async {
    var dir = await getTemporaryDirectory();
    String path = [dir.path, DateTime.now().toIso8601String()].join("/");
    return await File(path).writeAsBytes(bytes);
  }
}
