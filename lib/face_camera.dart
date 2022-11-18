import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:social_id_camera/face_result.dart';
import 'package:social_id_camera/loading_widget.dart';

class FaceCameraPage extends StatefulWidget {
  const FaceCameraPage({super.key});

  @override
  State<StatefulWidget> createState() => FaceCameraState();
}

class FaceCameraState extends State<FaceCameraPage> {
  final CropController _cropper = CropController();
  CameraReadyNotifier? _cameraReady;
  LoadingChangeNotifier? _loader;
  FileChangedNotifier? _file;
  CroppedFileChangeNotifier? _croppedFile;
  CameraController? _camera;
  bool cropped = false;
  Rect rect = Rect.zero;
  double cameraHeight = 0;
  final double cameraRadius = 0;
  final EdgeInsets cameraPadding = const EdgeInsets.only(top: 135);

  String get title => "Ảnh chụp chân dung";

  String get message => "Chú ý canh khuôn mặt vừa với khung hình";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      cameraHeight = MediaQuery.of(context).size.width;
      rect = Rect.fromLTWH(0, 0, cameraHeight, cameraHeight);
      _initCamera();
    });
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoadingChangeNotifier()),
        ChangeNotifierProvider(create: (_) => CameraReadyNotifier()),
        ChangeNotifierProvider(create: (_) => FileChangedNotifier()),
        ChangeNotifierProvider(create: (_) => CroppedFileChangeNotifier())
      ],
      builder: (context, _) {
        _loader = Provider.of<LoadingChangeNotifier>(context);
        _cameraReady = Provider.of<CameraReadyNotifier>(context);
        _file = Provider.of<FileChangedNotifier>(context);
        _croppedFile = Provider.of<CroppedFileChangeNotifier>(context);
        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: Text("Ảnh chụp chân dung"),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              floatingActionButton: _buildBottomButtons(),
              body: Stack(
                children: [
                  _buildCropCamera(),
                  _buildCropWidget(),
                  _buildCropImage(),
                  _buildOvalCrop(),
                  _buildHeader(),
                ],
              ),
            ),
            _buildLoading(),
          ],
        );
      },
    );
  }

  Widget _buildCropCamera() {
    return Consumer2<CameraReadyNotifier, CroppedFileChangeNotifier>(
        builder: (context, ready, croppedFile, _) {
      return ready.isReady && croppedFile.value == null
          ? ClipPath(
              clipper: CameraViewClipper(
                radius: cameraRadius,
                height: cameraHeight,
                padding: cameraPadding,
                onReactInit: (rect) => this.rect = rect,
              ),
              child: Container(
                color: Colors.amber,
                alignment: Alignment.center,
                child: CameraPreview(_camera!),
              ),
            )
          : const SizedBox();
    });
  }

  Widget _buildCropWidget() {
    return Consumer<FileChangedNotifier>(builder: (context, file, _) {
      return file.value == null
          ? const SizedBox()
          : Opacity(
              opacity: 0,
              child: Crop(
                image: file.value!,
                controller: _cropper,
                fixArea: true,
                initialAreaBuilder: (_) => rect,
                onStatusChanged: (status) {
                  if (status == CropStatus.ready && cropped == false) {
                    _cropper.crop();
                    cropped = true;
                  }
                },
                onCropped: _onCropped,
              ),
            );
    });
  }

  Widget _buildCropImage() {
    return Consumer<CroppedFileChangeNotifier>(builder: (context, file, _) {
      return file.value == null
          ? const SizedBox()
          : Container(
              height: cameraHeight,
              margin: cameraPadding,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(cameraRadius)),
                  image: DecorationImage(
                      image: MemoryImage(file.value!), fit: BoxFit.contain)),
            );
    });
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 30),
            child: Text(message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  _buildLoading() {
    return Consumer<LoadingChangeNotifier>(
      builder: (context, loader, _) {
        return Visibility(
            visible: loader.isLoading, child: const LoadingWidget());
      },
    );
  }

  _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40),
      child: Consumer<CroppedFileChangeNotifier>(
        builder: (context, file, _) {
          return file.value == null
              ? _buildTakeButtons()
              : _buildConfirmButtons();
        },
      ),
    );
  }

  _buildTakeButtons() {
    return FloatingActionButton(
      onPressed: _takePicture,
      child: const Icon(Icons.camera_alt_rounded),
    );
  }

  _buildConfirmButtons() {
    return Row(
      children: [
        Expanded(
            child: ElevatedButton(
                onPressed: _reTake, child: const Text("Chụp lại"))),
        const SizedBox(width: 12),
        Expanded(
            child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FaceResultPage(data: _croppedFile!.value!)));
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor),
          child: const Text("Chọn ảnh này"),
        )),
      ],
    );
  }

  //method
  _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      final frontCameras =
          cameras.where((e) => e.lensDirection == CameraLensDirection.front);
      final firstCamera =
          frontCameras.isNotEmpty ? frontCameras.first : cameras.first;
      _camera = CameraController(
        firstCamera,
        ResolutionPreset.medium,
      );
      await _camera?.initialize();
      _cameraReady?.ready();
    }
  }

  void _onCropped(Uint8List value) {
    _loader?.hideLoading();
    _croppedFile?.setValue(value);
  }

  void _takePicture() async {
    _loader?.showLoading();
    await _camera?.takePicture().then((v) async {
      _camera?.pausePreview();
      final img.Image? capturedImage = img.decodeImage(await v.readAsBytes());
      if (capturedImage != null) {
        var flippedImage = img.flipHorizontal(capturedImage);
        var f = File(v.path)..writeAsBytes(img.encodeJpg(flippedImage));
        _file?.setValue(await f.readAsBytes());
      } else {
        _file?.setValue(await v.readAsBytes());
      }
    });
  }

  void _reTake() {
    _camera?.resumePreview();
    _file?.clear();
    _croppedFile?.clear();
    cropped = false;
  }

  _buildOvalCrop() {
    return Consumer<CroppedFileChangeNotifier>(builder: (context, file, _) {
      Color color = Colors.white.withOpacity(file.value == null ? 0.8 : 1);
      return ClipPath(
        clipper: OvalViewClipper(
          height: cameraHeight,
          padding: cameraPadding,
        ),
        child: Container(color: color),
      );
    });
  }
}

class FileChangedNotifier extends ChangeNotifier {
  Uint8List? _value;

  Uint8List? get value => _value;

  void setValue(Uint8List value) {
    _value = value;
    notifyListeners();
  }

  void clear() {
    _value = null;
    notifyListeners();
  }
}

class CroppedFileChangeNotifier extends ChangeNotifier {
  Uint8List? _value;

  Uint8List? get value => _value;

  void setValue(Uint8List value) {
    _value = value;
    notifyListeners();
  }

  void clear() {
    _value = null;
    notifyListeners();
  }
}

class LoadingChangeNotifier extends ChangeNotifier {
  bool _value = false;

  bool get isLoading => _value;

  void showLoading() {
    _value = true;
    notifyListeners();
  }

  void hideLoading() {
    _value = false;
    notifyListeners();
  }
}

class CameraReadyNotifier extends ChangeNotifier {
  bool _value = false;

  bool get isReady => _value;

  void ready() {
    _value = true;
    notifyListeners();
  }
}

class CameraViewClipper extends CustomClipper<Path> {
  final Function(Rect rect) onReactInit;
  final EdgeInsets padding;
  final double height;
  final double radius;

  CameraViewClipper(
      {required this.onReactInit,
      required this.radius,
      required this.padding,
      required this.height});

  @override
  Path getClip(Size size) {
    Radius radius = Radius.circular(this.radius);
    EdgeInsets pad = padding;
    double h = height;
    Path path = Path();
    path.moveTo(pad.left + radius.x, pad.top);
    path.lineTo(size.width - pad.right - radius.x, pad.top);
    path.lineTo(size.width - pad.right, pad.top + radius.y);
    path.lineTo(size.width - pad.right, pad.top + h - radius.y);
    path.lineTo(size.width - pad.right - radius.x, pad.top + h);
    path.lineTo(pad.left + radius.x, pad.top + h);
    path.lineTo(pad.left, pad.top + h - radius.y);
    path.lineTo(pad.left, pad.top + radius.y);
    path.close();

    var tlc = Offset(pad.left + radius.x, pad.top + radius.y);
    path.addArc(Rect.fromCircle(center: tlc, radius: radius.x), 0, 2 * pi);
    var trc = Offset(size.width - pad.right - radius.x, pad.top + radius.y);
    path.addArc(Rect.fromCircle(center: trc, radius: radius.x), 0, 2 * pi);
    var blc = Offset(pad.left + radius.x, pad.top + h - radius.y);
    path.addArc(Rect.fromCircle(center: blc, radius: radius.x), 0, 2 * pi);
    var brc = Offset(size.width - pad.right - radius.x, pad.top + h - radius.y);
    path.addArc(Rect.fromCircle(center: brc, radius: radius.x), 0, 2 * pi);

    onReactInit(path.getBounds());
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return true;
  }
}

class OvalViewClipper extends CustomClipper<Path> {
  final EdgeInsets padding;
  final double height;

  OvalViewClipper({required this.padding, required this.height});

  @override
  Path getClip(Size size) {
    EdgeInsets pad = padding;

    Path path = Path();
    Offset center = Offset(size.width / 2.0, pad.top + height / 2);
    double h = height * 0.7;
    double w = height * 0.6;
    var ovalCenter = center + const Offset(0, -20);
    var oval = Rect.fromCenter(center: ovalCenter, height: h, width: w);
    path.addOval(oval);
    var rect = Rect.fromCenter(center: center, width: height, height: height);
    path.addRect(rect);
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return true;
  }
}
