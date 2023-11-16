import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitThemeTool {
  static Future<int> initThemeColor() async {
    final prefs = await SharedPreferences.getInstance();

    final int? seedColor = prefs.getInt('seedColor');

    if (seedColor == null) {
      return 0xFFBBDEFB;
    } else {
      return seedColor;
    }
  }

  static Future<bool> initThemeBrightness() async {
    final prefs = await SharedPreferences.getInstance();

    final bool? isDarkMode = prefs.getBool('isDarkMode');

    if (isDarkMode == null) {
      return false;
    } else {
      return isDarkMode;
    }
  }
}

class ThemeModel extends ChangeNotifier {
  late bool isDarkMode = false;
  late int seedColor = 0xFFBBDEFB;

  ThemeModel() {
    init();
  }

  void init() async {
    isDarkMode = await InitThemeTool.initThemeBrightness();
    seedColor = await InitThemeTool.initThemeColor();
    notifyListeners();
  }

  void changeBrightness(bool newIsDarkMode) {
    isDarkMode = newIsDarkMode;
    notifyListeners();
  }

  void changeThemeColor(int newSeedColor) {
    seedColor = newSeedColor;
    notifyListeners();
  }
}
