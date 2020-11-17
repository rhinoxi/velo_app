import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

import 'dart:developer' as developer;
import 'dart:math' as math;

import 'camera_layer.dart';
import 'ui_layer.dart';
import 'bondbox_layer.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIOverlays([]);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    // TODO:
    developer.log('nunabdiu $e');
  }
  await loadModel();
  runApp(MyApp());
}

loadModel() async {
  Tflite.close();
  try {
    String res;
    res = await Tflite.loadModel(
      model: "assets/yolov2_tiny.tflite",
      labels: "assets/yolov2_tiny.txt",
      // useGpuDelegate: true,
    );
    developer.log('gukogkuh $res');
  } on PlatformException catch (e) {
    developer.log('lauznuot Failed to load model.');
    developer.log(e.toString());
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'velo demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: FractionalOffset.center,
      children: [
        Positioned.fill(
          child: CameraBondBox(),
        ),
        Positioned.fill(
          child: UILayer(),
        ),
      ],
    );
  }
}

class CameraBondBox extends StatefulWidget {
  @override
  _CameraBondBoxState createState() => _CameraBondBoxState();
}

class _CameraBondBoxState extends State<CameraBondBox> {
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;

  setRecognitions(recognitions, imageHeight, imageWidth) {
    // rotate recognitions
    // for (var i = 0; i < recognitions.length; i++) {
    //   var tmp = recognitions[i];
    //   tmp['rect']['w'] = recognitions[i]['rect']['h'];
    //   tmp['rect']['h'] = recognitions[i]['rect']['w'];
    //   tmp['rect']['x'] = recognitions[i]['rect']['y'];
    //   tmp['rect']['y'] = 1 - recognitions[i]['rect']['x'];
    //   recognitions[i] = tmp;
    // }
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Stack(
      children: [
        Positioned.fill(
          child: CameraLayer(cameras, setRecognitions),
        ),
        Positioned.fill(
          child: BndBox(
            _recognitions == null ? [] : _recognitions,
            math.max(_imageHeight, _imageWidth),
            math.min(_imageHeight, _imageWidth),
            screen.height,
            screen.width,
          ),
        ),
      ],
    );
  }
}
