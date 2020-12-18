import 'package:flutter/cupertino.dart';
import 'dart:developer' as developer;

class Ball with ChangeNotifier {
  double x = 100;
  double y = 100;
  void update(double _x, double _y) {
    x = _x;
    y = _y;
    notifyListeners();
  }
}

class BallLocation {
  double x; // meter
  int t; // millisecond:w

  BallLocation(this.x, this.t);
}

class Track {
  List<BallLocation> values = [];
  double direction = 0;
  int emptyCount = 0;
  final int maxEmptyCount = 10;
  final int minFrameCount = 5; // 至少需要捕获 minFrameCount 帧才能计算速度
  final double maxSpeed = 160;
  final double minSpeed = 30;

  // 如果持续 add 进了 null，则可以考虑返回速度了
  double add(BallLocation bl) {
    if (bl != null) {
      developer.log('44a805 add x: ${bl.x}');
      if (values.length >= 2) {
        // developer.log(
        //     "a853c9 direction: $direction, last: ${values[values.length - 1].x}, current: ${bl.x}");
        if ((bl.x - values[values.length - 1].x) * direction > 0) {
          values.add(bl);
        } else {
          double speed = _computeAndClear();
          values.add(bl);
          return speed;
        }
      } else {
        values.add(bl);
        if (values.length == 2) {
          direction = values[1].x - values[0].x;
        }
      }
    } else {
      if (values.length > 0) {
        emptyCount++;
        if (emptyCount == maxEmptyCount) {
          return _computeAndClear();
        }
      }
    }
    return null;
  }

  double _computeAndClear() {
    double speed;
    int lastIdx = values.length - 1;
    // 如果捕获的帧数大于 minFrameCount 且第一帧和最后一帧的位置分处于中心的两侧，才计算
    if (values.length >= minFrameCount && values[lastIdx].x * values[0].x < 0) {
      double tmp = ((values[lastIdx].x - values[0].x) /
              (values[lastIdx].t - values[0].t) *
              1000 *
              3.6)
          .abs();
      if (tmp >= minSpeed && tmp <= maxSpeed) {
        speed = tmp;
      } else {
        developer.log('b5f025 error speed: $tmp');
      }
    }

    values.clear();
    emptyCount = 0;
    direction = 0;
    developer.log('a88d1b computing...... speed: $speed');
    return speed;
  }
}
