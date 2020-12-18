import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'models/image_buffer.dart';
import 'models/one_buffer.dart';
import 'models/ball.dart';

ImageBuffer imageBuffer;
SharedPreferences prefs;
OneBuffer oneBuffer = OneBuffer();

Track track = Track();

final TextEditingController disTextController =
    TextEditingController(text: '18.44');
