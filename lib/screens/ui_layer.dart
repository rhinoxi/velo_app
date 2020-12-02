import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:velo_app/models/image_buffer.dart';

import 'dart:developer' as developer;

import 'video_player.dart';
import '../global.dart' as global;
import '../models/record.dart';
import '../models/custom_settings.dart';

const distanceButtomHeight = 36.0;

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
                Expanded(child: BottomRow()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

class BottomRow extends StatelessWidget {
  final Random rand = Random();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RaisedButton(
            child: Text('+测试数据'),
            onPressed: () {
              var speed = rand.nextDouble() * 100;
              var now = DateTime.now();
              context.read<CurrentSpeed>().update(speed);
              global.oneBuffer.update(
                Record(speed: speed, createdAt: now),
                YUVImages(
                  global.imageBuffer.validBuffer(),
                  global.imageBuffer.width,
                  global.imageBuffer.height,
                  global.imageBuffer.fps,
                  now,
                ),
              );
              if (context.read<CustomSettings>().autoSave) {
                saveVideoAndShowInfo(context);
              }
            },
          ),
          Container(
            child: Row(
              children: [
                VideoSaveButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VideoSaveButton extends StatefulWidget {
  @override
  _VideoSaveButtonState createState() => _VideoSaveButtonState();
}

class _VideoSaveButtonState extends State<VideoSaveButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Consumer<CustomSettings>(
        builder: (context, settings, child) => Visibility(
          visible: !settings.autoSave,
          child: IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              saveVideoAndShowInfo(context);
            },
          ),
        ),
      ),
    );
  }
}

Widget makeUnifiedDialog(
    BuildContext context, double height, double width, Widget child) {
  return Dialog(
    shape: ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(0),
    ),
    child: Container(
      height: height,
      width: width,
      child: Stack(
        overflow: Overflow.visible,
        children: [
          Positioned(
            right: -12.0,
            top: -12.0,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: CircleAvatar(
                radius: 14.0,
                child: Icon(Icons.close),
              ),
            ),
          ),
          child,
        ],
      ),
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
      context,
      screen.height * 0.75,
      screen.width * 0.75,
      Column(
        children: [
          // Row(
          //   children: [
          //     Text(
          //       'Sort by:',
          //     ),
          //     SortByButton(),
          //   ],
          // ),
          Container(
            padding: EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '我的记录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10),
              child: Consumer<Records>(
                builder: (context, records, child) => ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: records.length,
                  itemBuilder: (BuildContext context, int index) {
                    var r = records[records.length - index - 1];
                    var formattedDate =
                        DateFormat('yyyy-MM-dd HH:mm:ss').format(r.createdAt);
                    return Card(
                      color: Theme.of(context).primaryColorDark,
                      elevation: 8.0,
                      margin: new EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 6.0),
                      child: Container(
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPage(r.videoPath),
                              ),
                            );
                          },
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 20,
                                padding: EdgeInsets.only(left: 10),
                                child: Icon(Icons.play_arrow),
                              ),
                            ],
                          ),
                          title: Text(
                            r.speed.toStringAsFixed(
                                r.speed.truncateToDouble() == r.speed ? 0 : 2),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            formattedDate,
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              developer
                                  .log('records: ${records.length}, $index');
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  content: Text('确定删除 $formattedDate 的记录？'),
                                  actions: [
                                    TextButton(
                                      child: Text('取消'),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                    TextButton(
                                        child: Text('确定'),
                                        onPressed: () {
                                          context.read<Records>().removeAt(
                                              records.length - index - 1);
                                          Navigator.of(context).pop();
                                        }),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    var settingDialog = makeUnifiedDialog(
      context,
      screen.height * 0.75,
      screen.width * 0.75,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Container(
                    child: Consumer<CustomSettings>(
                      builder: (context, customSettings, child) =>
                          SwitchListTile(
                        value: customSettings.autoSave,
                        title: Text('自动保存视频'),
                        onChanged: (value) {
                          customSettings.toggleAutoSave();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
    );
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
                  color: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Consumer<CurrentSpeed>(
                      builder: (context, speed, child) => Text(
                        '${speed.value.toStringAsFixed(speed.value.truncateToDouble() == speed.value ? 0 : 2)} KPH',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                  icon: Icon(
                    Icons.assignment,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => recordDialog,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings,
                  ),
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
            painter: ReferenceLine(Theme.of(context).accentColor),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: distanceButtomHeight,
              width: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
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
  final Color color;
  ReferenceLine(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final thickLine = Paint()
      ..color = color
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
      ..color = color
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
