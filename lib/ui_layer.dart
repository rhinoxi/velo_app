import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:developer' as developer;

const distanceButtomHeight = 36.0;
const baseBlack = Colors.black87;
const baseYellow = Color(0xFFFBC02D);

class UILayer extends StatelessWidget {
  final myController = TextEditingController(text: '18.44');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
          developer.log('distance: ${myController.text}');
        },
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
            child: Column(
              children: [
                Expanded(child: HeaderRow()),
                Expanded(flex: 3, child: DistanceRow(myController)),
                Expanded(child: Container()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    backgroundBlendMode: BlendMode.color,
                    color: baseBlack,
                  ),
                  padding: EdgeInsets.all(10.0),
                  child: Center(
                    child: Text(
                      '90 KPH',
                      style: TextStyle(
                        fontSize: 16,
                        color: baseYellow,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          Container(
            child: Container(
              child: Text(
                'LOGO',
                style: TextStyle(
                  color: Colors.red[460],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DistanceRow extends StatelessWidget {
  final TextEditingController controller;
  DistanceRow(this.controller);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    developer.log('tipecifi width: $width, height: $height');
    return Container(
      padding: EdgeInsets.fromLTRB(40, 40, 40, 10),
      child: Stack(
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: Boundary(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: distanceButtomHeight,
              width: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: baseYellow,
                ),
                child: DistanceField(controller),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DistanceField extends StatefulWidget {
  final TextEditingController controller;
  DistanceField(this.controller);
  _DistanceFieldState createState() => _DistanceFieldState(controller);
}

class _DistanceFieldState extends State<DistanceField> {
  final TextEditingController controller;
  _DistanceFieldState(this.controller);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextField(
        maxLength: 6,
        buildCounter: (BuildContext context,
                {int currentLength, int maxLength, bool isFocused}) =>
            null,
        keyboardType:
            TextInputType.numberWithOptions(decimal: true, signed: false),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'\d{1,3}(\.\d{0,2})?'))
        ],
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isCollapsed: true,
        ),
        textAlign: TextAlign.center,
        controller: controller,
        maxLines: 1,
      ),
    );
  }

  @override
  void dispose() {
    developer.log('dispose distance field');
    controller.dispose();
    super.dispose();
  }
}

class Boundary extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    developer.log('gupawism paint');
    final thickLine = Paint()
      ..color = baseBlack
      ..strokeWidth = 2;

    double leftBoundary = 0;
    double rightBoundary = size.width;
    double topBoundary = 0;
    double bottomBoundary = size.height;
    canvas.drawLine(Offset(leftBoundary, topBoundary),
        Offset(leftBoundary, bottomBoundary), thickLine);
    canvas.drawLine(Offset(rightBoundary, topBoundary),
        Offset(rightBoundary, bottomBoundary), thickLine);

    double innerBottomBoundary = size.height - distanceButtomHeight / 2;
    final thinLine = Paint()
      ..color = baseBlack
      ..strokeWidth = 1;
    canvas.drawLine(Offset(leftBoundary, innerBottomBoundary),
        Offset(size.width * 0.4, innerBottomBoundary), thinLine);
    canvas.drawLine(Offset(size.width * 0.6, innerBottomBoundary),
        Offset(rightBoundary, innerBottomBoundary), thinLine);
    // TODO: draw arrow
  }

  @override
  bool shouldRepaint(Boundary old) => false;
}
