import 'package:flutter/material.dart';

class Recognitions with ChangeNotifier {
  List<dynamic> values;
  int previewH;
  int previewW;

  void update(List<dynamic> _values, int _previewH, int _previewW) {
    values = _values;
    previewH = _previewH;
    previewW = _previewW;

    notifyListeners();
  }
}

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

  Record({@required this.speed, @required this.createdAt});
}

class Records with ChangeNotifier {
  List<Record> records = [];
  final int limit;

  Records(this.limit);

  void add(Record r) {
    records.add(r);
    if (records.length > limit) {
      records.removeAt(0);
    }
    notifyListeners();
  }

  void removeAt(int index) {
    records.removeAt(index);
    notifyListeners();
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
