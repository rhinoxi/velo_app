import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'global.dart' as global;

class CurrentSpeed with ChangeNotifier {
  double value = 0;

  void update(double newValue) {
    value = newValue;
    notifyListeners();
  }
}

class Record {
  DateTime createdAt;
  double speed;
  String videoPath;

  Record(
      {@required this.speed,
      @required this.createdAt,
      @required this.videoPath});

  Record.fromJson(Map<String, dynamic> _json)
      : speed = _json['speed'],
        createdAt = DateTime.parse(_json['createdAt']),
        videoPath = _json['videoPath'];

  Map<String, dynamic> toJson() => {
        'speed': speed,
        'createdAt': createdAt.toIso8601String(),
        'videoPath': videoPath,
      };
}

class Records with ChangeNotifier {
  List<Record> records = [];
  final int limit;

  Records(this.limit, {this.records});

  Future<void> persist() async {
    String recordListStr = json.encode(records);
    await global.prefs.setString(global.recordListKey, recordListStr);
  }

  void add(Record r) {
    records.add(r);
    if (records.length > limit) {
      // TODO: warning
      records.removeAt(0);
    }
    persist().then((_) {
      notifyListeners();
    });
  }

  void removeAt(int index) {
    Record r = records[index];
    records.removeAt(index);
    File videoFile = File(r.videoPath);
    videoFile.delete();
    persist().then((_) {
      notifyListeners();
    });
  }

  Record operator [](int i) => records[i];

  int get length => records.length;

  void sortByDate({reverse: false}) {
    if (reverse) {
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      records.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    notifyListeners();
  }

  void sortBySpeed({reverse: false}) {
    if (reverse) {
      records.sort((a, b) => b.speed.compareTo(a.speed));
    } else {
      records.sort((a, b) => a.speed.compareTo(b.speed));
    }
    notifyListeners();
  }
}
