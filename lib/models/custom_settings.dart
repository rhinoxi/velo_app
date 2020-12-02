import 'dart:convert';

import 'package:flutter/material.dart';

import '../global.dart' as global;

class CustomSettings with ChangeNotifier {
  static String customSettingsKey = 'custom_settings';
  bool autoSave = false;

  CustomSettings.fromJson(Map<String, dynamic> _json)
      : autoSave = _json['autoSave'];

  Map<String, dynamic> toJson() => {
        'autoSave': autoSave,
      };

  CustomSettings();

  static CustomSettings load() {
    String settingString = global.prefs.get(customSettingsKey);
    if (settingString != null) {
      return CustomSettings.fromJson(json.decode(settingString));
    }
    return CustomSettings();
  }

  Future<void> persist() async {
    String settingString = json.encode(this);
    await global.prefs.setString(customSettingsKey, settingString);
  }

  void toggleAutoSave() {
    autoSave = !autoSave;
    persist().then((_) {
      notifyListeners();
    });
  }
}
