import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:wakelock/wakelock.dart';

import 'dart:developer' as developer;

List<CameraDescription> cameras;

class CameraLayer extends StatefulWidget {
  @override
  _CameraLayerState createState() => _CameraLayerState();
}

class _CameraLayerState extends State<CameraLayer> with WidgetsBindingObserver {
  CameraController controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
    // cameras = await availableCameras();
    WidgetsBinding.instance.addObserver(this);
    Wakelock.enable();
  }

  Future<void> _setupCamera() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.high);
    await controller.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      _isReady = true;
    });
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
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        developer.log('lozsowac:' + controller.value.errorDescription);
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Container();
    }
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final yScale = 1.0;
    final xScale = controller.value.aspectRatio * deviceRatio;
    return RotatedBox(
      quarterTurns: -1,
      child: AspectRatio(
        aspectRatio: deviceRatio,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(xScale, yScale, 1),
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
  }

  void logError(String code, String message) =>
      developer.log('Error: $code\nError Message: $message');
}
