import 'dart:math';
import 'dart:typed_data';
import 'dart:io';

import 'dart:developer' as developer;

import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

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

class YUVImages {
  List<CameraImage> buffer;
  int width;
  int height;
  int fps;
  DateTime createdAt;
  bool _isSaving = false;

  YUVImages.empty();

  YUVImages(this.buffer, this.width, this.height, this.fps, this.createdAt);

  Future<String> writeCameraImages() async {
    if (buffer == null || buffer.isEmpty) {
      throw ('No video to save');
    }
    if (_isSaving) {
      throw ('Video is saving');
    }
    _isSaving = true;
    var buf = List<CameraImage>.from(buffer);
    buffer.clear();
    String filename = createdAt.toIso8601String();
    final appDir = await getApplicationDocumentsDirectory();
    final tf = File('${appDir.path}/$filename');
    // TODO: switch to application documents
    final extDir = await getExternalStorageDirectory();
    final vfDir = '${extDir.path}/videos';
    Directory(vfDir).createSync();
    final vfname = '$vfDir/$filename.mp4';
    var sink = tf.openWrite();
    for (var img in buf) {
      sink.add(img.planes[0].bytes);
      var uv = convertUVPlane(img);
      sink.add(uv);
    }
    sink.close();
    await sink.done;
    await saveVideo(tf, vfname);
    developer.log('b9cd59 save path: ${tf.path}');
    // TODO:  err in the middle
    _isSaving = false;
    return vfname;
  }

  Uint8List convertUVPlane(CameraImage img) {
    final int width = img.width;
    final int height = img.height;
    final int uvRowStride = img.planes[1].bytesPerRow;
    final int uvPixelStride = img.planes[1].bytesPerPixel;
    final int l = width * height ~/ 4;
    Uint8List ret = Uint8List(l * 2);
    int count = 0;
    for (int y = 0; y < height; y += 2) {
      for (int x = 0; x < width; x += 2) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        ret[count] = img.planes[1].bytes[uvIndex];
        ret[count + l] = img.planes[2].bytes[uvIndex];
        count++;
      }
    }
    return ret;
  }

  Future<void> saveVideo(File iFile, String oFilename) async {
    final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

    await _flutterFFmpeg.execute(
        "-f rawvideo -vcodec rawvideo -s ${width}x$height -r $fps -pix_fmt yuv420p -i ${iFile.path} -c:v mpeg4 -q:v 5 $oFilename");

    await iFile.delete();
  }
}
