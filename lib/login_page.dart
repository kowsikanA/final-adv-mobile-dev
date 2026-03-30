// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   bool _isLogin = true;
//   bool _loading = false;
//   bool _obscure = true;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _showMessage(String message, {bool error = false}) {
//     if (error) {
//       HapticFeedback.heavyImpact();
//     } else {
//       HapticFeedback.lightImpact();
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   Future<void> _submit() async {
//     final email = _emailController.text.trim();
//     final password = _passwordController.text;

//     if (email.isEmpty || password.isEmpty) {
//       _showMessage("Email and password are required", error: true);
//       return;
//     }

//     if (password.length < 6) {
//       _showMessage("Password must be at least 6 characters", error: true);
//       return;
//     }

//     setState(() => _loading = true);

//     try {
//       if (_isLogin) {
//         await FirebaseAuth.instance.signInWithEmailAndPassword(
//           email: email,
//           password: password,
//         );
//       } else {
//         await FirebaseAuth.instance.createUserWithEmailAndPassword(
//           email: email,
//           password: password,
//         );
//       }

//       HapticFeedback.mediumImpact();
//     } on FirebaseAuthException catch (e) {
//       _showMessage(e.message ?? "Authentication failed", error: true);
//     } catch (_) {
//       _showMessage("Something went wrong", error: true);
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   /// ===== Forgot Password =====
//   Future<void> _forgotPassword() async {
//     final email = _emailController.text.trim();

//     if (email.isEmpty) {
//       _showMessage("Enter your email to reset your password", error: true);
//       return;
//     }

//     try {
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
//       _showMessage("Password reset email sent");
//     } on FirebaseAuthException catch (e) {
//       _showMessage(e.message ?? "Unable to send reset email", error: true);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;

//     return Scaffold(
//       body: SafeArea(
//         child: Stack(
//           children: [
//             /// Background
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     scheme.primary.withValues(alpha: 0.18),
//                     scheme.surface,
//                     scheme.secondary.withValues(alpha: 0.10),
//                   ],
//                 ),
//               ),
//             ),

//             /// Content
//             Center(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(18),
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(maxWidth: 420),
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 250),
//                     curve: Curves.easeOut,
//                     padding: const EdgeInsets.all(18),
//                     decoration: BoxDecoration(
//                       color: scheme.surface.withValues(alpha: 0.90),
//                       borderRadius: BorderRadius.circular(22),
//                       border: Border.all(
//                         color: scheme.outlineVariant.withValues(alpha: 0.55),
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           blurRadius: 18,
//                           offset: const Offset(0, 10),
//                           color: Colors.black.withValues(alpha: 0.06),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         /// Header
//                         Row(
//                           children: [
//                             Container(
//                               width: 44,
//                               height: 44,
//                               decoration: BoxDecoration(
//                                 color: scheme.primary.withValues(alpha: 0.14),
//                                 borderRadius: BorderRadius.circular(14),
//                               ),
//                               child: Icon(
//                                 Icons.payments_rounded,
//                                 color: scheme.primary,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: AnimatedSwitcher(
//                                 duration: const Duration(milliseconds: 200),
//                                 child: Text(
//                                   _isLogin
//                                       ? "Welcome back"
//                                       : "Create your account",
//                                   key: ValueKey(_isLogin),
//                                   style: TextStyle(
//                                     fontSize: 22,
//                                     fontWeight: FontWeight.w900,
//                                     color: scheme.onSurface,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 8),

//                         AnimatedSwitcher(
//                           duration: const Duration(milliseconds: 200),
//                           child: Text(
//                             _isLogin
//                                 ? "Log in to continue tracking expenses."
//                                 : "Sign up to start tracking expenses.",
//                             key: ValueKey("sub$_isLogin"),
//                             style: TextStyle(
//                               color: scheme.onSurfaceVariant,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 18),

//                         /// Email
//                         TextField(
//                           controller: _emailController,
//                           keyboardType: TextInputType.emailAddress,
//                           textInputAction: TextInputAction.next,
//                           decoration: const InputDecoration(
//                             labelText: "Email",
//                             prefixIcon: Icon(Icons.email_outlined),
//                           ),
//                         ),

//                         const SizedBox(height: 12),

//                         /// Password
//                         TextField(
//                           controller: _passwordController,
//                           obscureText: _obscure,
//                           textInputAction: TextInputAction.done,
//                           onSubmitted: (_) =>
//                               _loading ? null : _submit(),
//                           decoration: InputDecoration(
//                             labelText: "Password",
//                             prefixIcon: const Icon(Icons.lock_outline),
//                             suffixIcon: IconButton(
//                               tooltip:
//                                   _obscure ? "Show password" : "Hide password",
//                               onPressed: () {
//                                 HapticFeedback.selectionClick();
//                                 setState(() => _obscure = !_obscure);
//                               },
//                               icon: Icon(
//                                 _obscure
//                                     ? Icons.visibility_off
//                                     : Icons.visibility,
//                               ),
//                             ),
//                           ),
//                         ),

//                         /// Forgot password
//                         if (_isLogin)
//                           Align(
//                             alignment: Alignment.centerRight,
//                             child: TextButton(
//                               onPressed: () {
//                                 HapticFeedback.selectionClick();
//                                 _forgotPassword();
//                               },
//                               child: const Text("Forgot password?"),
//                             ),
//                           ),

//                         const SizedBox(height: 10),

//                         /// Submit button
//                         AnimatedSwitcher(
//                           duration: const Duration(milliseconds: 200),
//                           child: _loading
//                               ? Center(
//                                   child: Padding(
//                                     padding:
//                                         const EdgeInsets.symmetric(vertical: 8),
//                                     child: CircularProgressIndicator(
//                                       color: scheme.primary,
//                                     ),
//                                   ),
//                                 )
//                               : ElevatedButton.icon(
//                                   key: const ValueKey("submitBtn"),
//                                   onPressed: () {
//                                     HapticFeedback.selectionClick();
//                                     _submit();
//                                   },
//                                   icon: Icon(
//                                     _isLogin
//                                         ? Icons.login
//                                         : Icons.person_add_alt_1,
//                                   ),
//                                   label: Text(
//                                     _isLogin
//                                         ? "Login"
//                                         : "Create account",
//                                   ),
//                                 ),
//                         ),

//                         const SizedBox(height: 10),

//                         /// Toggle login/signup
//                         TextButton(
//                           onPressed: () {
//                             HapticFeedback.lightImpact();
//                             setState(() => _isLogin = !_isLogin);
//                           },
//                           child: Text(
//                             _isLogin
//                                 ? "Create account"
//                                 : "Already have an account? Login",
//                             style: TextStyle(
//                               fontWeight: FontWeight.w700,
//                               color: scheme.primary,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum SubmitState { idle, loading, success, error }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _obscure = true;
  SubmitState _submitState = SubmitState.idle;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool error = false}) {
    if (error) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _fail("Email and password are required");
      return;
    }

    if (password.length < 6) {
      _fail("Password must be at least 6 characters");
      return;
    }

    setState(() => _submitState = SubmitState.loading);

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      HapticFeedback.mediumImpact();
      setState(() => _submitState = SubmitState.success);
    } on FirebaseAuthException catch (e) {
      _fail(e.message ?? "Authentication failed");
    } catch (_) {
      _fail("Something went wrong");
    }
  }

  void _fail(String message) {
    setState(() => _submitState = SubmitState.error);
    _showMessage(message, error: true);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _submitState = SubmitState.idle);
      }
    });
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage("Enter your email to reset password", error: true);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage("Password reset email sent");
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Reset failed", error: true);
    }
  }

  Color _buttonColor(ColorScheme scheme) {
    switch (_submitState) {
      case SubmitState.success:
        return Colors.green;
      case SubmitState.error:
        return scheme.error;
      default:
        return scheme.primary;
    }
  }

  Widget _buttonChild() {
    switch (_submitState) {
      case SubmitState.loading:
        return const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.white,
          ),
        );
      case SubmitState.success:
        return const Icon(Icons.check, color: Colors.white);
      case SubmitState.error:
        return const Icon(Icons.close, color: Colors.white);
      default:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isLogin ? Icons.login : Icons.person_add_alt_1),
            const SizedBox(width: 8),
            Text(_isLogin ? "Login" : "Create account"),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            /// Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: 0.18),
                    scheme.surface,
                    scheme.secondary.withValues(alpha: 0.10),
                  ],
                ),
              ),
            ),

            /// Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.55),
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isLogin ? "Welcome back" : "Create your account",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => _obscure = !_obscure);
                              },
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),

                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              child: const Text("Forgot password?"),
                            ),
                          ),

                        const SizedBox(height: 14),

                        /// ===== Animated Submit Button =====
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _buttonColor(scheme),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _submitState == SubmitState.loading
                                  ? null
                                  : () {
                                      HapticFeedback.selectionClick();
                                      _submit();
                                    },
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  child: _buttonChild(),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _isLogin = !_isLogin;
                              _submitState = SubmitState.idle;
                            });
                          },
                          child: Text(
                            _isLogin
                                ? "Create account"
                                : "Already have an account? Login",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}