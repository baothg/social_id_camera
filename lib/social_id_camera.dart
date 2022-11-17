import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:social_id_camera/loading_widget.dart';

import 'social_id_cropper.dart';

enum SocialIdCameraSide { front, back }

class SocialIdCameraWidget extends StatefulWidget {
  final SocialIdCameraSide side;
  final Function(Uint8List image) onContinue;

  const SocialIdCameraWidget(
      {super.key, required this.side, required this.onContinue});

  @override
  State<StatefulWidget> createState() => SocialIdCameraState();
}

class SocialIdCameraState extends State<SocialIdCameraWidget>
    with AutomaticKeepAliveClientMixin {
  final CropController _cropper = CropController();
  CameraReadyNotifier? _cameraReady;
  LoadingChangeNotifier? _loader;
  FileChangedNotifier? _file;
  CroppedFileChangeNotifier? _croppedFile;
  CameraController? _camera;
  bool cropped = false;
  Rect rect = Rect.fromLTWH(0, 0, 315, 198);
  final double cropHeight = 199;
  final double cropRadius = 10;
  final EdgeInsets cropPadding =
      const EdgeInsets.only(left: 30, right: 30, top: 227, bottom: 0);

  String get title => widget.side == SocialIdCameraSide.front
      ? "Ảnh mặt trước CCCD/CMND"
      : "Ảnh mặt sau CCCD/CMND";

  String get message =>
      "Chú ý đặt hình ảnh chứng từ vừa vào khung, có thể đọc được chữ, không bị chói sáng";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
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
    super.build(context);
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
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              floatingActionButton: _buildBottomButtons(),
              body: Stack(
                children: [
                  _buildCropCamera(),
                  _buildCropWidget(),
                  _buildCropImage(),
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
                radius: cropRadius,
                height: cropHeight,
                padding: cropPadding,
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
              child: FutureBuilder<Uint8List>(
                future: file.value!.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Crop(
                      image: snapshot.data!,
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
                    );
                  } else {
                    return const SizedBox();
                  }
                },
              ),
            );
    });
  }

  Widget _buildCropImage() {
    return Consumer<CroppedFileChangeNotifier>(builder: (context, file, _) {
      return file.value == null
          ? const SizedBox()
          : Container(
              height: cropHeight,
              margin: cropPadding,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(cropRadius)),
                  image: DecorationImage(
                      image: MemoryImage(file.value!), fit: BoxFit.contain)),
            );
    });
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 227,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: _showPicker,
                child: FutureBuilder<AssetEntity?>(
                  future: _getCurrentImage(),
                  builder: (context, snapshot) {
                    return Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4)),
                          color: Theme.of(context).primaryColor,
                          image: snapshot.data == null
                              ? null
                              : DecorationImage(
                                  fit: BoxFit.cover,
                                  image: AssetEntityImageProvider(
                                    snapshot.data!,
                                    isOriginal: false,
                                    thumbnailSize:
                                        const ThumbnailSize.square(200),
                                  ))),
                    );
                  },
                ),
              ),
            ),
            Center(
              child: FloatingActionButton(
                onPressed: _takePicture,
                child: const Icon(Icons.camera_alt_rounded),
              ),
            ),
          ],
        )
      ],
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
          onPressed: () => widget.onContinue(_croppedFile!.value!),
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
    final firstCamera = cameras.first;
    _camera = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );
    await _camera?.initialize();
    _cameraReady?.ready();
  }

  void _onCropped(Uint8List value) {
    _loader?.hideLoading();
    _croppedFile?.setValue(value);
  }

  void _takePicture() async {
    _loader?.showLoading();
    await _camera?.takePicture().then((v) => _file?.setValue(v));
  }

  void _reTake() {
    _file?.clear();
    _croppedFile?.clear();
    cropped = false;
  }

  Future<AssetEntity?> _getCurrentImage() async {
    List<AssetPathEntity> list = await PhotoManager.getAssetPathList(
            type: RequestType.image, onlyAll: true)
        .catchError((e) {
      print(e);
    });
    if (list.isEmpty) {
      return null;
    } else {
      var items = await list.first.getAssetListRange(start: 0, end: 1);
      if (items.isNotEmpty) {
        return items.first;
      } else {
        null;
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _showPicker() async {
    _loader?.showLoading();
    await ImagePicker()
        .pickImage(source: ImageSource.gallery)
        .then((image) async {
      await image?.readAsBytes().then((bytes) async {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => SocialIdCropperPage(
                  rect: rect,
                  bytes: bytes,
                  onCropped: _onCropped,
                )));
      });
    });
    _loader?.hideLoading();
  }
}

class FileChangedNotifier extends ChangeNotifier {
  XFile? _value;

  XFile? get value => _value;

  void setValue(XFile value) {
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
