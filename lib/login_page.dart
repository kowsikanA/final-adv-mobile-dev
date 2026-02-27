// // import 'package:flutter/material.dart';
// // import 'package:firebase_auth/firebase_auth.dart';

// // class LoginPage extends StatefulWidget {
// //   const LoginPage({super.key});

// //   @override
// //   State<LoginPage> createState() => _LoginPageState();
// // }

// // class _LoginPageState extends State<LoginPage> {
// //   final _emailController = TextEditingController();
// //   final _passwordController = TextEditingController();

// //   bool _isLogin = true; // toggle between login / signup
// //   bool _loading = false;

// //   Future<void> _submit() async {
// //     final email = _emailController.text.trim();
// //     final password = _passwordController.text;

// //     // 🔒 Basic validation BEFORE Firebase
// //     if (email.isEmpty || password.isEmpty) {
// //       _showError("Email and password are required");
// //       return;
// //     }

// //     if (password.length < 6) {
// //       _showError("Password must be at least 6 characters");
// //       return;
// //     }

// //     setState(() => _loading = true);

// //     try {
// //       if (_isLogin) {
// //         await FirebaseAuth.instance.signInWithEmailAndPassword(
// //           email: email,
// //           password: password,
// //         );
// //       } else {
// //         await FirebaseAuth.instance.createUserWithEmailAndPassword(
// //           email: email,
// //           password: password,
// //         );
// //       }
// //       // ✅ SUCCESS → AuthGate will handle navigation
// //     } on FirebaseAuthException catch (e) {
// //       _showError(_friendlyMessage(e.code));
// //     } finally {
// //       if (mounted) setState(() => _loading = false);
// //     }
// //   }

// //   String _friendlyMessage(String code) {
// //     switch (code) {
// //       case 'email-already-in-use':
// //         return 'This email is already registered';
// //       case 'invalid-email':
// //         return 'Invalid email address';
// //       case 'wrong-password':
// //         return 'Incorrect password';
// //       case 'user-not-found':
// //         return 'No account found for this email';
// //       case 'weak-password':
// //         return 'Password must be at least 6 characters';
// //       default:
// //         return 'Authentication failed ($code)';
// //     }
// //   }

// //   void _showError(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text(message)),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Center(
// //         child: Padding(
// //           padding: const EdgeInsets.all(24),
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               Text(
// //                 _isLogin ? "Login" : "Create Account",
// //                 style: const TextStyle(
// //                   fontSize: 26,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               const SizedBox(height: 24),

// //               TextField(
// //                 controller: _emailController,
// //                 keyboardType: TextInputType.emailAddress,
// //                 decoration: const InputDecoration(
// //                   labelText: "Email",
// //                 ),
// //               ),
// //               const SizedBox(height: 12),

// //               TextField(
// //                 controller: _passwordController,
// //                 obscureText: true,
// //                 decoration: const InputDecoration(
// //                   labelText: "Password",
// //                 ),
// //               ),
// //               const SizedBox(height: 24),

// //               if (_loading)
// //                 const CircularProgressIndicator()
// //               else ...[
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: ElevatedButton(
// //                     onPressed: _submit,
// //                     child: Text(_isLogin ? "Login" : "Create account"),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 12),
// //                 TextButton(
// //                   onPressed: () {
// //                     setState(() => _isLogin = !_isLogin);
// //                   },
// //                   child: Text(
// //                     _isLogin
// //                         ? "Create account"
// //                         : "Already have an account? Login",
// //                   ),
// //                 ),
// //               ],
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }


// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   bool _isLogin = true; // toggle between login / signup
//   bool _loading = false;

//   // ================= AUTH ACTION =================
//   Future<void> _submit() async {
//     final email = _emailController.text.trim();
//     final password = _passwordController.text;

//     // Basic validation
//     if (email.isEmpty || password.isEmpty) {
//       _showError("Email and password are required");
//       return;
//     }

//     if (password.length < 6) {
//       _showError("Password must be at least 6 characters");
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
//       // SUCCESS → AuthGate will handle navigation
//     } on FirebaseAuthException catch (e) {
//       _showError(_friendlyMessage(e.code));
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // ================= FORGOT PASSWORD =================
//   Future<void> _forgotPassword() async {
//     final email = _emailController.text.trim();

//     if (email.isEmpty) {
//       _showError("Enter your email to reset password");
//       return;
//     }

//     try {
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Password reset email sent")),
//       );
//     } on FirebaseAuthException catch (e) {
//       _showError(_friendlyMessage(e.code));
//     }
//   }

//   // ================= ERROR HANDLING =================
//   String _friendlyMessage(String code) {
//     switch (code) {
//       case 'invalid-email':
//         return 'Invalid email address';
//       case 'user-not-found':
//         return 'No account found for this email';
//       case 'wrong-password':
//         return 'Incorrect password';
//       case 'email-already-in-use':
//         return 'This email is already registered';
//       case 'weak-password':
//         return 'Password must be at least 6 characters';
//       default:
//         return 'Authentication failed ($code)';
//     }
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   // ================= UI =================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 _isLogin ? "Login" : "Create Account",
//                 style: const TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 32),

//               TextField(
//                 controller: _emailController,
//                 keyboardType: TextInputType.emailAddress,
//                 decoration: const InputDecoration(
//                   labelText: "Email",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               TextField(
//                 controller: _passwordController,
//                 obscureText: true,
//                 decoration: const InputDecoration(
//                   labelText: "Password",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),

//               Align(
//                 alignment: Alignment.centerRight,
//                 child: TextButton(
//                   onPressed: _forgotPassword,
//                   child: const Text("Forgot password?"),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               if (_loading)
//                 const CircularProgressIndicator()
//               else
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _submit,
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: Text(
//                       _isLogin ? "Login" : "Create account",
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),

//               const SizedBox(height: 16),

//               TextButton(
//                 onPressed: () {
//                   setState(() => _isLogin = !_isLogin);
//                 },
//                 child: Text(
//                   _isLogin
//                       ? "Create account"
//                       : "Already have an account? Login",
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError("Email and password are required");
      return;
    }

    if (password.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    setState(() => _loading = true);

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
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyMessage(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError("Enter your email to reset password");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent")),
      );
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyMessage(e.code));
    }
  }

  String _friendlyMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No account found';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already registered';
      default:
        return 'Authentication failed';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isLogin ? "Login" : "Create Account",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: const Text("Forgot password?"),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_loading)
                    const CircularProgressIndicator()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isLogin ? "Login" : "Create account",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() => _isLogin = !_isLogin);
                    },
                    child: Text(
                      _isLogin
                          ? "Create account"
                          : "Already have an account? Login",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}