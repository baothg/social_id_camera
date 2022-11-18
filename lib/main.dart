import 'package:flutter/material.dart';
import 'package:social_id_camera/face_camera.dart';
import 'package:social_id_camera/social_id_cameras.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Id Camera Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Social Id Camera Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) {
                    return const SocialIdCameraPage();
                  }));
                },
                child: const Text("Social Id Camera")),
            const SizedBox(height: 40),
            ElevatedButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) {
                    return const FaceCameraPage();
                  }));
                },
                child: const Text("Face Camera")),
          ],
        ),
      ),
    );
  }
}
