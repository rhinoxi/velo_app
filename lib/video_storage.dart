import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';

import 'dart:developer' as developer;

import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

saveVideo(File iFile, String oFilename, int width, int height, int fps) async {
  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

  await _flutterFFmpeg
      .execute(
          "-f rawvideo -vcodec rawvideo -s ${width}x$height -r $fps -pix_fmt yuv420p -i ${iFile.path} -c:v mpeg4 -q:v 5 $oFilename")
      .then((rc) {
    developer.log("bfff45 FFmpeg process exited with rc $rc");
    iFile.delete();
  });
}

Future<File> getVideoFile(String filename) async {
  final directory = await getExternalStorageDirectory();
  return File('${directory.path}/videos/$filename.mp4');
}

Future<String> writeCameraImages(String filename, int width, int height,
    int fps, List<CameraImage> imageList) async {
  developer.log(
      '9ec7e7 video info: width: $width, height: $height, fps: $fps, frames: ${imageList.length}');
  final appDir = await getApplicationSupportDirectory();
  final tf = File('${appDir.path}/$filename');
  final extDir = await getExternalStorageDirectory();
  final vfDir = '${extDir.path}/videos';
  Directory(vfDir).createSync();
  final vfname = '$vfDir/$filename.mp4';
  var sink = tf.openWrite();
  for (var img in imageList) {
    sink.add(img.planes[0].bytes);
    var uv = convertUVPlane(img);
    sink.add(uv);
  }
  sink.close();
  await sink.done;
  saveVideo(tf, vfname, width, height, fps);
  developer.log('b9cd59 save path: ${tf.path}');
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
  for (int x = 0; x < width; x += 2) {
    for (int y = 0; y < height; y += 2) {
      final int uvIndex =
          uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
      ret[count] = img.planes[1].bytes[uvIndex];
      ret[count + l] = img.planes[2].bytes[uvIndex];
      count++;
    }
  }
  return ret;
}
