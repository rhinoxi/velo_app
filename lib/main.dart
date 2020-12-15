import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:developer' as developer;

import 'models/record.dart';
import 'models/custom_settings.dart';
import 'screens/camera_main.dart';
import 'global.dart' as global;

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIOverlays([]);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
  ]);
  try {
    cameras = await availableCameras();
    global.prefs = await SharedPreferences.getInstance();
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
          create: (context) => CustomSettings.load(),
        ),
        ChangeNotifierProvider(
          create: (context) => CurrentSpeed(),
        ),
        ChangeNotifierProvider(
          create: (context) => Records.load(),
        ),
      ],
      child: MaterialApp(
        title: 'velo demo',
        theme: ThemeData.dark(),
        // TODO: 不确定 0 是不是都是后置主摄像头
        home: CameraMain(cameras[0]),
      ),
    );
  }
}
