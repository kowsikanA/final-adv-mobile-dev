import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'expense_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final Widget child;

        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const Scaffold(
            key: ValueKey('auth-loading'),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.data == null) {
          child = const LoginPage(key: ValueKey('auth-login'));
        } else {
          child = const ExpensePage(key: ValueKey('auth-expense'));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            return FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1.0).animate(fade),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
    );
  }
}