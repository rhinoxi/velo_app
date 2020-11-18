import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:developer' as developer;

const distanceButtomHeight = 36.0;
const baseBlack = Colors.black87;
const baseYellow = Color(0xFFFBC02D);

final TextEditingController disTextController =
    TextEditingController(text: '18.44');

class UILayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    developer.log('XplEqJCU UILayer rebuild');
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
            child: Column(
              children: [
                Expanded(child: HeaderRow()),
                Expanded(flex: 3, child: DistanceRow()),
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
                  decoration: const BoxDecoration(
                    backgroundBlendMode: BlendMode.color,
                    color: baseBlack,
                  ),
                  padding: const EdgeInsets.all(10.0),
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
              child: const Text(
                'LOGO',
                style: TextStyle(
                  color: Colors.amber,
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
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    developer.log('tipecifi width: $width, height: $height');
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 10),
      child: Stack(
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: ReferenceLine(),
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
                child: DistanceField(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DistanceField extends StatefulWidget {
  _DistanceFieldState createState() => _DistanceFieldState();
}

class _DistanceFieldState extends State<DistanceField> {
  _DistanceFieldState();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

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
        controller: disTextController,
        maxLines: 1,
      ),
    );
  }

  @override
  void dispose() {
    developer.log('dispose distance field');
    super.dispose();
  }
}

class ReferenceLine extends CustomPainter {
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
  bool shouldRepaint(ReferenceLine old) => false;
}

class ObjectCounter extends InheritedWidget {
  const ObjectCounter({
    Key key,
    @required this.count,
  }) : assert(count != null);

  final int count;

  static ObjectCounter of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ObjectCounter>();
  }

  @override
  bool updateShouldNotify(ObjectCounter old) => count != old.count;
}
