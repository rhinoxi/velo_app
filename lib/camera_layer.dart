import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:wakelock/wakelock.dart';
import 'package:tflite/tflite.dart';

import 'dart:developer' as developer;

typedef void Callback(List<dynamic> list, int h, int w);

class CameraLayer extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  CameraLayer(this.cameras, this.setRecognitions);

  @override
  _CameraLayerState createState() => _CameraLayerState();
}

class _CameraLayerState extends State<CameraLayer> with WidgetsBindingObserver {
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

    // // If the controller is updated then update the UI.
    // controller.addListener(() {
    //   if (mounted) setState(() {});
    //   if (controller.value.hasError) {
    //     developer.log('lozsowac:' + controller.value.errorDescription);
    //   }
    // });

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
    developer.log('image height: ${img.height}, width: ${img.width}');
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

      widget.setRecognitions(recognitions, img.height, img.width);

      isDetecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    // landscape
    final xScale = 1.0;
    final yScale = controller.value.aspectRatio / deviceRatio;
    return AspectRatio(
      aspectRatio: deviceRatio,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(xScale, yScale, 1),
        child: CameraPreview(controller),
      ),
    );
    // final xScale = 1.0;
    // final yScale = controller.value.aspectRatio / deviceRatio;
    // return AspectRatio(
    //   aspectRatio: deviceRatio,
    //   child: Transform(
    //     alignment: Alignment.center,
    //     transform: Matrix4.diagonal3Values(xScale, yScale, 1),
    //     child: CameraPreview(controller),
    //   ),
    // );
  }

  void logError(String code, String message) =>
      developer.log('Error: $code\nError Message: $message');
}
