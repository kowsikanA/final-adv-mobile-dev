import 'package:flutter/material.dart';

class AppThemeController {
  AppThemeController._();

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Toggle between light & dark
  static void toggle() {
    themeMode.value =
        themeMode.value == ThemeMode.dark
            ? ThemeMode.light
            : ThemeMode.dark;
  }

  /// Set specific mode (used in Contact page)
  static void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
  }
}