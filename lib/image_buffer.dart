import 'dart:math';

import 'package:camera/camera.dart';

ImageBuffer imageBuffer;

class ImageBuffer {
  List<CameraImage> buffer = [];
  final int width;
  final int height;
  int _validLen;

  DateTime startTime;
  DateTime endTime;
  bool updateEndTime = true;

  ImageBuffer(this.width, this.height, {int validLen = 300}) {
    _validLen = validLen;
  }

  void add(CameraImage ci) {
    DateTime now = DateTime.now();
    if (startTime == null) {
      startTime = now;
    }
    if (updateEndTime) {
      endTime = now;
    }
    if (buffer.length > _validLen * 1.5) {
      updateEndTime = false;
      buffer = buffer.sublist(_validLen);
    }
    buffer.add(ci);
  }

  // 取 5s 数据
  List<CameraImage> validBuffer() {
    return List<CameraImage>.from(
        buffer.sublist(buffer.length <= fps * 5 ? 0 : buffer.length - fps * 5));
  }

  String toString() {
    return 'width: $width, height: $height, fps: $fps';
  }

  void clear() {
    buffer.clear();
    startTime = null;
    endTime = null;
    updateEndTime = true;
  }

  int get fps {
    Duration deltaTime = endTime.difference(startTime);
    int frame = buffer.length > _validLen * 2 ? _validLen * 2 : buffer.length;
    double _fps = frame / deltaTime.inMicroseconds * pow(10, 6);
    if (_fps > 22 && _fps < 26) {
      return 24;
    } else if (_fps > 28 && _fps < 32) {
      return 30;
    } else if (_fps > 58 && _fps < 62) {
      return 60;
    }
    return _fps.round();
  }
}
