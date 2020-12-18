import 'package:flutter/material.dart';

import './global.dart' as global;
import './models/record.dart';
import 'package:provider/provider.dart';

void saveVideoAndShowInfo(BuildContext context) {
  var r = global.oneBuffer.record;
  global.oneBuffer.yuvImages.writeCameraImages().then((String videoPath) {
    r.videoPath = videoPath;
    context.read<Records>().add(r);
    Scaffold.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text('Saved successfully'),
      ),
    );
  }, onError: (e) {
    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        duration: const Duration(seconds: 1),
      ),
    );
  });
}
