import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/responsive_metrics.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onLoginSuccess});

  final VoidCallback? onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = AuthService();

    try {
      if (_isLogin) {
        // Login — verify credentials
        final userName = _nameController.text.trim();
        await authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        // Update the user's name if provided on login too
        if (userName.isNotEmpty) {
          final user = await authService.getUser();
          if (user != null) {
            await authService.saveUser(user.copyWith(name: userName));
          }
        }
      } else {
        // Sign up — create new account with password
        await authService.register(
          name: _nameController.text.trim().isEmpty
              ? _emailController.text.split('@')[0]
              : _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        widget.onLoginSuccess?.call();
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(metrics.pagePadding, 24, metrics.pagePadding, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.savings_rounded,
                        size: 80,
                        color: AppColors.lime,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Goal Saver',
                        style: AppText.hero.copyWith(fontSize: metrics.heroFont),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Welcome back!' : 'Create your account',
                        style: AppText.body.copyWith(
                          color: AppColors.muted,
                          fontSize: metrics.bodyFont,
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _nameController,
                        style: AppText.body,
                        decoration: goalInputDecoration(
                          _isLogin ? 'Your Name (optional)' : 'Full Name',
                          Icons.person_rounded,
                        ),
                        validator: (value) {
                          if (!_isLogin && (value == null || value.trim().isEmpty)) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        style: AppText.body,
                        keyboardType: TextInputType.emailAddress,
                        decoration: goalInputDecoration('Email', Icons.email_rounded),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!isValidEmail(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        style: AppText.body,
                        obscureText: _obscurePassword,
                        decoration: goalInputDecoration(
                          'Password',
                          Icons.lock_rounded,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.muted,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleAuth,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.lime,
                            foregroundColor: AppColors.ink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.ink,
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Sign In' : 'Sign Up',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin
                              ? "Don't have an account? Sign Up"
                              : 'Already have an account? Sign In',
                          style: TextStyle(
                            color: AppColors.lime,
                            fontWeight: FontWeight.w600,
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
    );
  }
}