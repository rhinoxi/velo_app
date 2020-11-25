import 'dart:collection';

import 'package:camera/camera.dart';

Queue<CameraImage> imageBuffer = Queue();
final int imageBufferSize = 60;
