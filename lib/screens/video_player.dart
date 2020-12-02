import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  final String videoPath;
  VideoPage(this.videoPath);

  @override
  State<StatefulWidget> createState() {
    return _VideoPageState();
  }
}

class _VideoPageState extends State<VideoPage> {
  VideoPlayerController _videoPlayerController;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  @override
  void dispose() {
    developer.log('47d5eb video page disposed');
    _videoPlayerController.dispose();
    super.dispose();
  }

  Future<void> initializePlayer() async {
    _videoPlayerController = VideoPlayerController.file(File(widget.videoPath));
    // TODO: file not found error
    await _videoPlayerController.initialize();
    _videoPlayerController.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      Navigator.pop(context);
    }
    return MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
      ),
      home: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: _videoPlayerController != null &&
                        _videoPlayerController.value.initialized
                    ? VideoPlayer(_videoPlayerController)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
