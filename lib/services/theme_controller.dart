import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool currentlyDark) {
    _themeMode = currentlyDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
