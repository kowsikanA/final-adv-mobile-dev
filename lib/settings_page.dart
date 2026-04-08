import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: scheme.primary.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.settings,
                      size: 32,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Appearance & Accessibility",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Customize how the app looks and behaves for comfort and readability.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Appearance",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: AppThemeController.themeMode,
                    builder: (context, mode, _) {
                      return Column(
                        children: [
                          _themeTile(
                            context,
                            "Light Mode",
                            "Bright, clean interface",
                            Icons.light_mode_outlined,
                            mode == ThemeMode.light,
                            () {
                              HapticFeedback.selectionClick();
                              AppThemeController.setThemeMode(ThemeMode.light);
                            },
                          ),
                          _themeTile(
                            context,
                            "Dark Mode",
                            "Low-light, higher contrast look",
                            Icons.dark_mode_outlined,
                            mode == ThemeMode.dark,
                            () {
                              HapticFeedback.selectionClick();
                              AppThemeController.setThemeMode(ThemeMode.dark);
                            },
                          ),
                          _themeTile(
                            context,
                            "Use Device Setting",
                            "Automatically follow system theme",
                            Icons.settings_suggest_outlined,
                            mode == ThemeMode.system,
                            () {
                              HapticFeedback.selectionClick();
                              AppThemeController.setThemeMode(ThemeMode.system);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Text Size",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<AppTextScale>(
                    valueListenable: AppThemeController.textScale,
                    builder: (context, currentScale, _) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppTextScale.values.map((scale) {
                          final selected = currentScale == scale;
                          return ChoiceChip(
                            label: Text(scale.label),
                            selected: selected,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              AppThemeController.setTextScale(scale);
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Accessibility",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ValueListenableBuilder<bool>(
                    valueListenable: AppThemeController.lowVisionMode,
                    builder: (context, enabled, _) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(
                          Icons.visibility_outlined,
                          color: scheme.primary,
                        ),
                        title: const Text(
                          "Low Vision Mode",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          "Automatically enlarge text for easier reading.",
                        ),
                        value: enabled,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          AppThemeController.setLowVisionMode(value);
                        },
                      );
                    },
                  ),

                  ValueListenableBuilder<bool>(
                    valueListenable: AppThemeController.highContrastMode,
                    builder: (context, enabled, _) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(
                          Icons.contrast_outlined,
                          color: scheme.primary,
                        ),
                        title: const Text(
                          "High Contrast",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          "Increase visual contrast for clearer text and controls.",
                        ),
                        value: enabled,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          AppThemeController.setHighContrastMode(value);
                        },
                      );
                    },
                  ),

                  ValueListenableBuilder<bool>(
                    valueListenable: AppThemeController.boldTextMode,
                    builder: (context, enabled, _) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(
                          Icons.format_bold_outlined,
                          color: scheme.primary,
                        ),
                        title: const Text(
                          "Bold Text",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          "Use heavier font weights across the app.",
                        ),
                        value: enabled,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          AppThemeController.setBoldTextMode(value);
                        },
                      );
                    },
                  ),

                  ValueListenableBuilder<bool>(
                    valueListenable: AppThemeController.reducedMotionMode,
                    builder: (context, enabled, _) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(
                          Icons.motion_photos_off_outlined,
                          color: scheme.primary,
                        ),
                        title: const Text(
                          "Reduced Motion",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          "Reduce movement and simplify transitions.",
                        ),
                        value: enabled,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          AppThemeController.setReducedMotionMode(value);
                        },
                      );
                    },
                  ),

                  ValueListenableBuilder<bool>(
                    valueListenable: AppThemeController.largerTouchTargets,
                    builder: (context, enabled, _) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(
                          Icons.touch_app_outlined,
                          color: scheme.primary,
                        ),
                        title: const Text(
                          "Larger Touch Targets",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          "Increase tap area for buttons, fields, and lists.",
                        ),
                        value: enabled,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          AppThemeController.setLargerTouchTargets(value);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: scheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle),
        trailing: selected
            ? Icon(Icons.check_circle, color: scheme.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}