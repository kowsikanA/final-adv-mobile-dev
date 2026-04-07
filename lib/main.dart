import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'firebase_options.dart';
import 'auth_gate.dart';
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

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,

      /// BACKGROUND
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0E1116) : scheme.surface,

      /// APP BAR
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? const Color(0xFF0E1116) : scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),

      /// CARDS
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 1,
        color: isDark ? const Color(0xFF161B22) : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      /// INPUTS
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF1F242C)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),

      /// SNACKBAR
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF1F242C) : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Expenses',

          /// THEMES
          themeMode: mode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),

          /// GLOBAL UI LAYER (Toggle Button)
          builder: (context, child) {
            return Stack(
              children: [
                child!,

                /// 🔥 FLOATING THEME TOGGLE
                Positioned(
                  top: 50,
                  right: 16,
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        AppThemeController.toggle();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: ValueListenableBuilder<ThemeMode>(
                          valueListenable:
                              AppThemeController.themeMode,
                          builder: (context, mode, _) {
                            return Icon(
                              mode == ThemeMode.dark
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },

          /// START SCREEN
          home: const SplashScreen(),
        );
      },
    );
  }
}