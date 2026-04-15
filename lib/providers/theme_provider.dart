import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void setDarkMode(bool value) {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
  }
}
