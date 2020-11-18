import 'package:flutter/material.dart';

import 'dart:math' as math;
import 'dart:developer' as developer;

class BndBox extends StatefulWidget {
  final double screenH;
  final double screenW;

  BndBox({Key key, this.screenH, this.screenW}) : super(key: key);

  @override
  BndBoxState createState() => BndBoxState();
}

class BndBoxState extends State<BndBox> {
  List<dynamic> _results;
  int _previewH;
  int _previewW;
  void updateBoxes(List<dynamic> recognitions, int previewH, int previewW) {
    setState(() {
      _results = recognitions;
      _previewH = previewH;
      _previewW = previewW;
    });
  }

  @override
  Widget build(BuildContext context) {
    developer.log('DBEzVSJm rebuild bndbox');
    List<Widget> _renderBoxes() {
      return _results?.map((re) {
            var _x = re["rect"]["y"];
            var _w = re["rect"]["h"];
            var _h = re["rect"]["w"];
            var _y = 1 - re["rect"]["x"] - _h;
            var scaleW, scaleH, x, y, w, h;

            if (widget.screenH / widget.screenW > _previewH / _previewW) {
              scaleW = widget.screenH / _previewH * _previewW;
              scaleH = widget.screenH;
              var difW = (scaleW - widget.screenW) / scaleW;
              x = (_x - difW / 2) * scaleW;
              w = _w * scaleW;
              if (_x < difW / 2) w -= (difW / 2 - _x) * scaleW;
              y = _y * scaleH;
              h = _h * scaleH;
            } else {
              scaleH = widget.screenW / _previewW * _previewH;
              scaleW = widget.screenW;
              var difH = (scaleH - widget.screenH) / scaleH;
              x = _x * scaleW;
              w = _w * scaleW;
              y = (_y - difH / 2) * scaleH;
              h = _h * scaleH;
              if (_y < difH / 2) h -= (difH / 2 - _y) * scaleH;
            }
            double left = math.max(0, x);
            double top = math.max(0, y);
            developer
                .log('UMxyQZTF left: $left, top: $top, width: $w, height: $h}');

            return Positioned(
              left: math.max(0, x),
              top: math.max(0, y),
              width: w,
              height: h,
              child: Container(
                padding: EdgeInsets.only(top: 5.0, left: 5.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color.fromRGBO(37, 213, 253, 1.0),
                    width: 3.0,
                  ),
                ),
                child: Text(
                  "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    color: Color.fromRGBO(37, 213, 253, 1.0),
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          })?.toList() ??
          [];
    }

    return Stack(
      children: _renderBoxes(),
    );
  }
}
