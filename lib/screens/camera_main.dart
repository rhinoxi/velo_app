import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:wakelock/wakelock.dart';
import 'package:provider/provider.dart';

import 'dart:developer' as developer;

import 'ui_layer.dart';
import 'ball.dart';
import '../models/custom_settings.dart';
import '../models/image_buffer.dart';
import '../models/record.dart';
import '../models/ball.dart';
import '../constants.dart' as constants;
import '../global.dart' as global;
import '../utils.dart';

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
    developer.log('9410f4 camera init');
    super.initState();
    onNewCameraSelected(widget.camera);
    WidgetsBinding.instance.addObserver(this);
    Wakelock.enable();
  }

  @override
  void dispose() {
    developer.log('9cb024 camera dispose');
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
      global.imageBuffer?.clear();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(controller.description);
    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    developer.log('910a07 new camera selected');
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
      developer.log('2f3f36 mounted: $mounted');

      final screen = MediaQuery.of(context).size;
      developer.log("screen width: ${screen.width}, height: ${screen.height}");
      await controller.startImageStream((CameraImage img) {
        if (global.imageBuffer == null) {
          developer.log("image width: ${img.width}, height: ${img.height}");
          global.imageBuffer = ImageBuffer(img.width, img.height);
        }
        global.imageBuffer.add(img);

        BallLocation bl;
        if (img.ball != null) {
          context
              .read<Ball>()
              .update(img.ball[0] * screen.width, img.ball[1] * screen.height);
          bl = BallLocation(_rel2absDistance(img.ball[0]), img.timeInMs);
        }
        double speed = global.track.add(bl);

        if (speed != null) {
          DateTime now = DateTime.now();
          context.read<CurrentSpeed>().update(speed);
          global.oneBuffer.update(
            Record(speed: speed, createdAt: now),
            YUVImages(
              global.imageBuffer.validBuffer(),
              global.imageBuffer.width,
              global.imageBuffer.height,
              global.imageBuffer.fps,
              now,
            ),
          );

          if (context.read<CustomSettings>().autoSave) {
            saveVideoAndShowInfo(context);
          }
        }
        // TODO: detecting
        // if !isFlying && foundBall
        //   isFlying = true
        // if isFlying && (notFoundBallCount >= 5 || notProcessCount >= 10)
        //   isFlying = false
        //   saveImageBuffer to another List, ImageList
        // if saveVideo triggered, save ImageList to video
        // imageDetect(img);
      });
      setState(() {});
    }
  }

  // 把 x 方向的像素位置转换成中心为 0 一边为正一边为负的距离
  double _rel2absDistance(double x) {
    double totalDistance = double.parse(global.disTextController.text);
    return (x - (1 - constants.distLenPct) / 2) /
            constants.distLenPct *
            totalDistance -
        totalDistance / 2;
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
        BallCircle(),
      ],
    );
  }
}
