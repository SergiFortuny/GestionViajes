import 'package:flutter/material.dart';

class ThemeManager extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  void toggle() {
    if (_mode == ThemeMode.dark) {
      _mode = ThemeMode.light;
    } else {
      _mode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void setLight() {
    _mode = ThemeMode.light;
    notifyListeners();
  }

  void setDark() {
    _mode = ThemeMode.dark;
    notifyListeners();
  }
}
