import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';

import 'dart:developer' as developer;

import 'model.dart';
import 'camera_main.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIOverlays([]);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
  ]);
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    // TODO:
    developer.log('nunabdiu $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => CurrentSpeed(),
        ),
        ChangeNotifierProvider(
          create: (context) => Records(10),
        ),
      ],
      child: MaterialApp(
        title: 'velo demo',
        // TODO: 不确定 0 是不是都是后置主摄像头
        home: CameraMain(cameras[0]),
      ),
    );
  }
}
