import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'loading_widget.dart';

class SocialIdCropperPage extends StatefulWidget {
  final Rect rect;
  final Uint8List bytes;
  final Function(Uint8List data) onCropped;

  const SocialIdCropperPage(
      {super.key,
      required this.rect,
      required this.bytes,
      required this.onCropped});

  @override
  State<StatefulWidget> createState() => SocialIdCropperState();
}

class SocialIdCropperState extends State<SocialIdCropperPage> {
  final CropController controller = CropController();
  final CropController controller2 = CropController();
  late Rect rect;
  LoadingChangeNotifier? _loader;
  FileChangedNotifier? _file;
  bool _isInitRect = false;
  bool _isCropped = false;

  @override
  void initState() {
    super.initState();
    rect = widget.rect;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _loader?.showLoading();
    });
  }

  _initRect() {
    _loader?.hideLoading();
    Size size = MediaQuery.of(context).size;
    double height = rect.height;
    double width = rect.width;
    if (size.width > rect.width) {
      double left = (size.width - rect.width) / 2;
      if (size.height > rect.height) {
        double top = (size.height - rect.height) / 2;
        rect = Rect.fromLTWH(left, top, width, height);
        controller.rect = rect;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoadingChangeNotifier()),
        ChangeNotifierProvider(create: (_) => FileChangedNotifier()),
      ],
      builder: (context, _) {
        _loader = Provider.of<LoadingChangeNotifier>(context);
        _file = Provider.of<FileChangedNotifier>(context);
        return Stack(
          children: [
            Scaffold(
              body: Stack(
                children: [
                  Crop(
                    image: widget.bytes,
                    controller: controller,
                    initialAreaBuilder: (_) => rect,
                    baseColor: Colors.white,
                    onCropped: (data) {
                      _file?.setValue(data);
                    },
                    onStatusChanged: (status) {
                      if (status == CropStatus.ready && !_isInitRect) {
                        _isInitRect = true;
                        _initRect();
                      }
                    },
                  ),
                  Consumer<FileChangedNotifier>(builder: (context, file, _) {
                    if (file.value == null) {
                      return const SizedBox();
                    } else {
                      return Opacity(
                        opacity: 0,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: rect.left),
                          child: Crop(
                            image: file.value!,
                            controller: controller2,
                            initialAreaBuilder: (_) =>
                                rect.shift(Offset(-rect.left, 0)),
                            baseColor: Colors.black,
                            onCropped: (data) {
                              _loader?.hideLoading();
                              Navigator.of(context).pop();
                              widget.onCropped(data);
                            },
                            onStatusChanged: (status) {
                              if (status == CropStatus.ready && !_isCropped) {
                                _isCropped = true;
                                controller2.crop();
                              }
                            },
                          ),
                        ),
                      );
                    }
                  })
                ],
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              floatingActionButton: Consumer<LoadingChangeNotifier>(
                builder: (context, loader, _) {
                  if (loader.isLoading) {
                    return const SizedBox();
                  } else {
                    return ElevatedButton(
                      child: const Text("Xác nhận"),
                      onPressed: () {
                        _loader?.showLoading();
                        controller.crop();
                      },
                    );
                  }
                },
              ),
            ),
            _buildLoading()
          ],
        );
      },
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
