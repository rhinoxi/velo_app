import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:velo_app/ui_layer.dart';
import 'package:wakelock/wakelock.dart';
import 'package:tflite/tflite.dart';

import 'dart:developer' as developer;

import 'bondbox.dart';

class CameraMain extends StatefulWidget {
  final List<CameraDescription> cameras;
  CameraMain(this.cameras);

  @override
  _CameraMainState createState() => _CameraMainState();
}

class _CameraMainState extends State<CameraMain> with WidgetsBindingObserver {
  final GlobalKey<BndBoxState> _key = GlobalKey();
  CameraController controller;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();
    onNewCameraSelected(widget.cameras[0]);
    WidgetsBinding.instance.addObserver(this);
    Wakelock.enable();
  }

  @override
  void dispose() {
    controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    Wakelock.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    developer.log('zemeguga ' + state.toString());
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      controller.startImageStream((CameraImage img) {
        processImage(img);
      });
    });
  }

  processImage(CameraImage img) {
    if (isDetecting) {
      return;
    }
    isDetecting = true;
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    Tflite.detectObjectOnFrame(
      bytesList: img.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      model: "YOLO",
      imageHeight: img.height,
      imageWidth: img.width,
      imageMean: 0,
      imageStd: 255.0,
      numResultsPerClass: 1,
      threshold: 0.2,
    ).then((recognitions) {
      int endTime = DateTime.now().millisecondsSinceEpoch;
      print("Detection took ${endTime - startTime}");
      developer.log(recognitions.toString());
      developer.log('image height: ${img.height}, width: ${img.width}');
      final screen = MediaQuery.of(context).size;
      developer.log('screen height: ${screen.height}, width: ${screen.width}');
      _key.currentState.updateBoxes(
        recognitions,
        img.height,
        img.width,
      );

      isDetecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    developer.log('nCYeANtg rebuild camera');
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }
    final screen = MediaQuery.of(context).size;
    final deviceRatio = screen.height / screen.width;
    // landscape
    final xScale = controller.value.aspectRatio / deviceRatio;
    final yScale = 1.0;
    developer.log(
        'controller ratio: ${controller.value.aspectRatio}, deviceRatio: $deviceRatio ');
    return Stack(
      children: [
        RotatedBox(
          quarterTurns: -1,
          child: AspectRatio(
            aspectRatio: deviceRatio,
            child: Transform(
              child: CameraPreview(controller),
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(xScale, yScale, 1),
            ),
          ),
        ),
        BndBox(
          key: _key,
          screenH: screen.height,
          screenW: screen.width,
        ),
        UILayer(),
      ],
    );
  }
}