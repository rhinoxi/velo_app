import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:wakelock/wakelock.dart';

import 'dart:developer' as developer;

import 'ui_layer.dart';
import 'image_buffer.dart';

class CameraMain extends StatefulWidget {
  final CameraDescription camera;
  CameraMain(this.camera);

  @override
  _CameraMainState createState() => _CameraMainState();
}

class _CameraMainState extends State<CameraMain> with WidgetsBindingObserver {
  // final GlobalKey<BndBoxState> _key = GlobalKey();
  CameraController controller;
  bool isDetecting = false;
  bool isFlying = false;

  @override
  void initState() {
    super.initState();
    onNewCameraSelected(widget.camera);
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
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller?.dispose();
      imageBuffer.clear();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(controller.description);
    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: false,
    );
    // controller.addListener(() {
    //   developer.log('fObIZmtH controller listenner running');
    //   if (mounted) {
    //     setState(() {});
    //   }

    //   if (controller.value.hasError) {
    //     developer.log('Camera error ${controller.value.errorDescription}');
    //   }
    // });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      developer.log('3af299 $e');
    }

    if (mounted) {
      setState(() {});
      developer.log('2f3f36 mounted: $mounted');
      developer.log('783a4f start image stream');
      controller.startImageStream((CameraImage img) {
        if (imageBuffer == null) {
          imageBuffer = ImageBuffer(img.width, img.height);
        }
        imageBuffer.add(img);
        // TODO: detecting
        // if !isFlying && foundBall
        //   isFlying = true
        // if isFlying && (notFoundBallCount >= 5 || notProcessCount >= 10)
        //   isFlying = false
        //   saveImageBuffer to another List, ImageList
        // if saveVideo triggered, save ImageList to video
        // imageDetect(img);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }
    final screen = MediaQuery.of(context).size;
    final deviceRatio = screen.height / screen.width;
    // landscape
    final xScale = controller.value.aspectRatio / deviceRatio;
    final yScale = 1.0;
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
        UILayer(),
      ],
    );
  }
}
