import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';

import 'dart:developer' as developer;

class YuvStorage {
  Future<String> get _localPath async {
    // TODO: 改
    final directory = await getExternalStorageDirectory();
    // final directory = await getApplicationSupportDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;

    return File('$path/temp_yuv.txt');
  }

  Future<String> writeCameraImages(List<CameraImage> imgList) async {
    final file = await _localFile;
    var sink = file.openWrite();
    for (var img in imgList) {
      sink.add(img.planes[0].bytes);
      var uv = convertUVPlane(img);
      sink.add(uv[0]);
      sink.add(uv[1]);
    }
    sink.close();
    developer.log('b9cd59 save path: ${file.path}');
    return file.path;
  }

  List<Uint8List> convertUVPlane(CameraImage img) {
    final int width = img.width;
    final int height = img.height;
    final int uvRowStride = img.planes[1].bytesPerRow;
    final int uvPixelStride = img.planes[1].bytesPerPixel;
    final int l = width * height ~/ 4;
    List<Uint8List> ret = [Uint8List(l), Uint8List(l)];
    int count = 0;
    for (int x = 0; x < width; x += 2) {
      for (int y = 0; y < height; y += 2) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        ret[0][count] = img.planes[1].bytes[uvIndex];
        ret[1][count] = img.planes[2].bytes[uvIndex];
      }
    }
    return ret;
  }
}
