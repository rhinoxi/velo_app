import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'dart:developer' as developer;

import 'model.dart';

const distanceButtomHeight = 36.0;
const baseBlack = Color(0xFF2B3140);
const baseWhite = Color(0xFFE6EBF9);

final TextEditingController disTextController =
    TextEditingController(text: '18.44');

class UILayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                Expanded(child: DebugRow()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DebugRow extends StatelessWidget {
  final Random rand = Random();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        RaisedButton(
          child: Text('添加记录'),
          onPressed: () {
            context.read<Records>().add(
                Record(speed: rand.nextDouble(), createdAt: DateTime.now()));
          },
        ),
      ],
    );
  }
}

Widget makeUnifiedDialog(double height, double width, Widget child) {
  return Dialog(
    shape: ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(0),
    ),
    backgroundColor: Colors.white,
    child: Container(
      color: baseWhite,
      height: height,
      width: width,
      child: child,
    ),
  );
}

class SortByButton extends StatefulWidget {
  @override
  _SortByButtonState createState() => _SortByButtonState();
}

class _SortByButtonState extends State<SortByButton> {
  String value = 'Date';
  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      onChanged: (String newValue) {
        if (newValue == 'Date') {
          context.read<Records>().sortByDate();
        } else if (newValue == 'Speed') {
          context.read<Records>().sortBySpeed();
        }
        setState(() {
          value = newValue;
        });
      },
      items: <String>['Date', 'Speed']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}

class HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var screen = MediaQuery.of(context).size;
    var recordDialog = makeUnifiedDialog(
      screen.height * 0.6,
      screen.width * 0.6,
      Column(
        children: [
          Row(
            children: [
              Text(
                'Sort by:',
                style: TextStyle(color: baseWhite),
              ),
              SortByButton(),
            ],
          ),
          Expanded(
            child: Consumer<Records>(
              builder: (context, records, child) => ListView.builder(
                scrollDirection: Axis.vertical,
                padding: EdgeInsets.all(20),
                shrinkWrap: true,
                itemCount: records.length,
                itemBuilder: (BuildContext context, int index) {
                  var r = records[index];
                  return Card(
                    elevation: 8.0,
                    margin: new EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 6.0),
                    child: Container(
                      decoration:
                          BoxDecoration(color: Color.fromRGBO(64, 75, 96, .9)),
                      child: ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 20,
                              padding: EdgeInsets.only(right: 20, left: 10),
                              decoration: new BoxDecoration(
                                  border: new Border(
                                      right: new BorderSide(
                                          width: 1.0, color: Colors.white24))),
                              child: Text(index.toString(),
                                  style: TextStyle(color: baseWhite)),
                            ),
                          ],
                        ),
                        title: Text(
                          r.speed.toStringAsFixed(
                              r.speed.truncateToDouble() == r.speed ? 0 : 2),
                          style: TextStyle(
                              color: baseWhite, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd H:m:s').format(r.createdAt),
                          style: TextStyle(color: baseWhite),
                        ),
                        trailing: Container(
                          child: Icon(Icons.delete, color: baseWhite),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
    var settingDialog = makeUnifiedDialog(
        screen.height,
        screen.width,
        Column(
          children: [],
        ));
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
                  width: 100,
                  height: 50,
                  color: baseBlack,
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Consumer<Recognitions>(
                      builder: (context, recognitions, child) => Text(
                        '${recognitions.values?.length ?? 0} 个',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: baseWhite,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          Container(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.assignment),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => recordDialog,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => settingDialog,
                    );
                  },
                ),
              ],
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
                  color: baseWhite,
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
