import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'firebase_options.dart';
import 'app_theme_controller.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Stripe.publishableKey =
      'pk_test_51SRCVt0RNCB3m8QSpZhxFBpOZr8mMSpIO8MO43DcfLXX1AArhDGLlcWUpcMKVOUsLLwl8keO00YdPFiKjkua5FYH00mnsHFca3';

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _seed = Color(0xFF1B5E20);

  ThemeData _buildTheme({
    required Brightness brightness,
    required bool highContrast,
    required bool boldText,
    required bool reducedMotion,
    required bool largerTargets,
  }) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    final isDark = brightness == Brightness.dark;

    final scheme = highContrast
        ? baseScheme.copyWith(
            surface: isDark ? const Color(0xFF090B0F) : Colors.white,
            onSurface: isDark ? Colors.white : Colors.black,
            primary: isDark ? const Color(0xFF72E28B) : const Color(0xFF0F6A2A),
            onPrimary: Colors.white,
            outline: isDark ? Colors.white70 : Colors.black87,
            outlineVariant: isDark ? Colors.white38 : Colors.black26,
            surfaceContainerHighest:
                isDark ? const Color(0xFF1A1E25) : const Color(0xFFEAEFF2),
          )
        : baseScheme;

    TextTheme withWeight(TextTheme textTheme) {
      if (!boldText) return textTheme;
      return textTheme.copyWith(
        bodyLarge: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        bodyMedium: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        bodySmall: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        titleMedium:
            textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        labelMedium:
            textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
      );
    }

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0E1116) : scheme.surface,
      pageTransitionsTheme: reducedMotion
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
              },
            )
          : null,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? const Color(0xFF0E1116) : scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: boldText ? FontWeight.w900 : FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 0.8,
        color: isDark ? const Color(0xFF161B22) : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: highContrast
              ? BorderSide(color: scheme.outline.withValues(alpha: 0.55))
              : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF1F242C)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: highContrast
              ? BorderSide(color: scheme.outline.withValues(alpha: 0.45))
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: highContrast ? 2 : 1.2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: largerTargets ? 18 : 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(largerTargets ? 52 : 46),
          padding: EdgeInsets.symmetric(vertical: largerTargets ? 16 : 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: boldText ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(largerTargets ? 52 : 46),
          padding: EdgeInsets.symmetric(
            vertical: largerTargets ? 16 : 14,
            horizontal: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: boldText ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: largerTargets ? 12 : 8,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: largerTargets ? 4 : 0),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF1F242C) : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      visualDensity:
          largerTargets ? VisualDensity.standard : VisualDensity.compact,
      materialTapTargetSize: largerTargets
          ? MaterialTapTargetSize.padded
          : MaterialTapTargetSize.shrinkWrap,
    );

    return theme.copyWith(
      textTheme: withWeight(theme.textTheme),
      primaryTextTheme: withWeight(theme.primaryTextTheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, mode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: AppThemeController.lowVisionMode,
          builder: (context, lowVision, __) {
            return ValueListenableBuilder<bool>(
              valueListenable: AppThemeController.highContrastMode,
              builder: (context, highContrast, ___) {
                return ValueListenableBuilder<bool>(
                  valueListenable: AppThemeController.boldTextMode,
                  builder: (context, boldText, ____) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: AppThemeController.reducedMotionMode,
                      builder: (context, reducedMotion, _____) {
                        return ValueListenableBuilder<bool>(
                          valueListenable:
                              AppThemeController.largerTouchTargets,
                          builder: (context, largerTargets, ______) {
                            return ValueListenableBuilder<AppTextScale>(
                              valueListenable: AppThemeController.textScale,
                              builder: (context, textScale, _______) {
                                final scaleFactor = lowVision
                                    ? (textScale.factor < 1.15
                                        ? 1.15
                                        : textScale.factor)
                                    : textScale.factor;

                                return MaterialApp(
                                  debugShowCheckedModeBanner: false,
                                  title: 'Expenses',
                                  themeMode: mode,
                                  theme: _buildTheme(
                                    brightness: Brightness.light,
                                    highContrast: highContrast,
                                    boldText: boldText,
                                    reducedMotion: reducedMotion,
                                    largerTargets: largerTargets,
                                  ),
                                  darkTheme: _buildTheme(
                                    brightness: Brightness.dark,
                                    highContrast: highContrast,
                                    boldText: boldText,
                                    reducedMotion: reducedMotion,
                                    largerTargets: largerTargets,
                                  ),
                                  builder: (context, child) {
                                    final media = MediaQuery.of(context);
                                    return MediaQuery(
                                      data: media.copyWith(
                                        textScaler:
                                            TextScaler.linear(scaleFactor),
                                      ),
                                      child: child!,
                                    );
                                  },
                                  home: const SplashScreen(),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}