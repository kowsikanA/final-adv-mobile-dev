import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum SubmitState { idle, loading, success, error }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _obscure = true;
  SubmitState _submitState = SubmitState.idle;

  late final AnimationController _introController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.97,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
      ),
    );

    _introController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _introController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool error = false}) {
    if (error) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? Colors.red : Colors.green,),
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
      if (!mounted) return;
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
      case SubmitState.loading:
      case SubmitState.idle:
        return scheme.primary;
    }
  }

  IconData _buttonIcon() {
    switch (_submitState) {
      case SubmitState.success:
        return Icons.check_circle;
      case SubmitState.error:
        return Icons.error_outline;
      case SubmitState.loading:
      case SubmitState.idle:
        return _isLogin ? Icons.login : Icons.person_add_alt_1;
    }
  }

  String _buttonText() {
    switch (_submitState) {
      case SubmitState.loading:
        return _isLogin ? "Logging in..." : "Creating account...";
      case SubmitState.success:
        return "Success";
      case SubmitState.error:
        return "Try again";
      case SubmitState.idle:
        return _isLogin ? "Login" : "Create account";
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: 0.16),
                    scheme.surface,
                    scheme.secondary.withValues(alpha: 0.10),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -20,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -20,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.secondary.withValues(alpha: 0.08),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(alpha: 0.45),
                            ),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 22,
                                offset: const Offset(0, 14),
                                color: Colors.black.withValues(alpha: 0.08),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: scheme.primary.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 220),
                                      child: Column(
                                        key: ValueKey(_isLogin),
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isLogin
                                                ? "Welcome back"
                                                : "Create your account",
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              color: scheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _isLogin
                                                ? "Log in to continue tracking expenses."
                                                : "Sign up to start tracking expenses.",
                                            style: TextStyle(
                                              color: scheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: "Email",
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  if (_submitState != SubmitState.loading) {
                                    _submit();
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscure
                                        ? "Show password"
                                        : "Hide password",
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
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      _forgotPassword();
                                    },
                                    child: const Text("Forgot password?"),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _buttonColor(scheme)
                                          .withValues(alpha: 0.22),
                                      blurRadius: 14,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _submitState == SubmitState.loading
                                      ? null
                                      : () {
                                          HapticFeedback.selectionClick();
                                          _submit();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _buttonColor(scheme),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: _submitState == SubmitState.loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(_buttonIcon()),
                                  label: Text(
                                    _buttonText(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
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
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: Text(
                                    _isLogin
                                        ? "Create account"
                                        : "Already have an account? Login",
                                    key: ValueKey(_isLogin),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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