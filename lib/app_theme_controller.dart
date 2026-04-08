import 'package:flutter/material.dart';

enum AppTextScale {
  small(0.95, 'Small'),
  medium(1.0, 'Medium'),
  large(1.15, 'Large'),
  extraLarge(1.3, 'Extra Large');

  final double factor;
  final String label;
  const AppTextScale(this.factor, this.label);
}

class AppThemeController {
  AppThemeController._();

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static final ValueNotifier<bool> lowVisionMode =
      ValueNotifier<bool>(false);

  static final ValueNotifier<bool> highContrastMode =
      ValueNotifier<bool>(false);

  static final ValueNotifier<bool> boldTextMode =
      ValueNotifier<bool>(false);

  static final ValueNotifier<bool> reducedMotionMode =
      ValueNotifier<bool>(false);

  static final ValueNotifier<bool> largerTouchTargets =
      ValueNotifier<bool>(false);

  static final ValueNotifier<AppTextScale> textScale =
      ValueNotifier<AppTextScale>(AppTextScale.medium);

  static void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
  }

  static void setLowVisionMode(bool enabled) {
    lowVisionMode.value = enabled;
    if (enabled && textScale.value.factor < AppTextScale.large.factor) {
      textScale.value = AppTextScale.large;
    }
  }

  static void setHighContrastMode(bool enabled) {
    highContrastMode.value = enabled;
  }

  static void setBoldTextMode(bool enabled) {
    boldTextMode.value = enabled;
  }

  static void setReducedMotionMode(bool enabled) {
    reducedMotionMode.value = enabled;
  }

  static void setLargerTouchTargets(bool enabled) {
    largerTouchTargets.value = enabled;
  }

  static void setTextScale(AppTextScale scale) {
    textScale.value = scale;
  }
}