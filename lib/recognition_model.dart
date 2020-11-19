import 'package:flutter/material.dart';

class Recognitions with ChangeNotifier {
  List<dynamic> results;
  int previewH;
  int previewW;

  void update(List<dynamic> _results, int _previewH, int _previewW) {
    results = _results;
    previewH = _previewH;
    previewW = _previewW;

    notifyListeners();
  }
}
