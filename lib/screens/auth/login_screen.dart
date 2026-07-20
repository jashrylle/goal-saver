import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart' show isValidEmail, UserModel;
import '../../services/auth_service.dart';
import '../../state/goal_saver_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/responsive_metrics.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common_widgets.dart';

/// Modern Material Design 3 login/signup screen.
///
/// Features:
/// - Smooth animated transitions
/// - Password visibility toggle
/// - Clear validation with inline error messages
/// - Animated illustrations/icons
/// - Material Design 3 glassmorphism card
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onLoginSuccess});

  final VoidCallback? onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = AuthService();

    try {
      UserModel? user;
      if (_isLogin) {
        user = await authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        final userName = _nameController.text.trim().isEmpty
            ? _emailController.text.split('@')[0]
            : _nameController.text.trim();
        user = await authService.signUpWithEmail(
          name: userName,
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        // Auto-assign a fun default profile emoji based on the user's name
        final defaultEmojis = ['🦊', '🦁', '🐼', '🐨', '🤖', '🚀', '💡', '💰', '🐷', '🍕'];
        final emojiIndex = userName.hashCode.abs() % defaultEmojis.length;
        user = user.copyWith(photoUrl: defaultEmojis[emojiIndex]);
        // Save the default photo URL immediately
        await authService.saveUser(user);
      }

      if (mounted) {
        setState(() => _isLoading = false);

        try {
          final ctrl = context.read<GoalSaverController>();
          final currentUser = user;
          if (_isLogin) {
            // For returning users: load all data from Hive under user-scoped keys
            await ctrl.loadUserData(currentUser.id);

            // Safety net: sync profile from auth service if Hive store has defaults
            try {
              final authUser = await authService.getUser();
              if (authUser != null) {
                final needsUpdate = ctrl.userName == 'User' || 
                    ctrl.userName.isEmpty || 
                    ctrl.userEmail.isEmpty;
                if (needsUpdate) {
                  await ctrl.updateProfile(
                    name: authUser.name,
                    email: authUser.email,
                    photoUrl: authUser.photoUrl,
                  );
                }
              }
            } catch (_) {}
          } else {
            // For new user signup, initialize all data in Hive
            await ctrl.initializeNewUser(currentUser.id, currentUser);
          }
        } catch (e) {
          debugPrint('Failed to sync user data to controller: $e');
        }

        widget.onLoginSuccess?.call();
      }
    } on AuthServiceException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _errorMessage = e.message;
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('══════════════════════════════════════════════');
        debugPrint('AUTH EXCEPTION (real error): $e');
        debugPrint('STACK TRACE: $stackTrace');
        debugPrint('══════════════════════════════════════════════');
        // Show the actual exception message so we can see what's really wrong
        _errorMessage = e.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;

    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  metrics.pagePadding, 24, metrics.pagePadding, 24,
                ),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Animated Hero Section ──────────────────────────────
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            children: [
                              // Glowing logo with gradient ring
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.lime.withValues(alpha: 0.2),
                                      AppColors.lime.withValues(alpha: 0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: AppColors.lime.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.lime.withValues(alpha: 0.15),
                                      blurRadius: 30,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.savings_rounded,
                                  size: 48,
                                  color: AppColors.lime,
                                ),
                              ).animate().fadeIn(duration: 800.ms).scale(
                                begin: const Offset(0.5, 0.5),
                                curve: Curves.elasticOut,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Goal Saver',
                                style: AppText.hero.copyWith(
                                  fontSize: metrics.heroFont,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isLogin
                                    ? 'Welcome back! Let\'s reach your goals.'
                                    : 'Start your savings journey today.',
                                textAlign: TextAlign.center,
                                style: AppText.body.copyWith(
                                  color: mutedColor,
                                  fontSize: metrics.bodyFont,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Glassmorphism Form Card ──────────────────────────
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.glass,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // ── Animated Tab Toggle ─────────────────────
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: AnimatedContainer(
                                          duration: 250.ms,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _isLogin
                                                ? AppColors.lime
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: GestureDetector(
                                            onTap: () => setState(() {
                                              _isLogin = true;
                                              _errorMessage = null;
                                            }),
                                            child: Text(
                                              'Sign In',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                color: _isLogin
                                                    ? AppColors.ink
                                                    : mutedColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: AnimatedContainer(
                                          duration: 250.ms,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: !_isLogin
                                                ? AppColors.lime
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: GestureDetector(
                                            onTap: () => setState(() {
                                              _isLogin = false;
                                              _errorMessage = null;
                                            }),
                                            child: Text(
                                              'Sign Up',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                color: !_isLogin
                                                    ? AppColors.ink
                                                    : mutedColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // ── Name Field (Sign Up only) ──────────────
                                if (!_isLogin)
                                  Column(
                                    children: [
                                      TextFormField(
                                        controller: _nameController,
                                        style: TextStyle(color: textColor),
                                        decoration: goalInputDecoration(
                                          'Full Name',
                                          Icons.person_rounded,
                                        ).copyWith(
                                          hintText: 'Enter your name',
                                        ),
                                        textInputAction: TextInputAction.next,
                                        validator: (value) {
                                          if (!_isLogin &&
                                              (value == null || value.trim().isEmpty)) {
                                            return 'Please enter your name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                    ].animate().fadeIn(duration: 350.ms),
                                  ),

                                // ── Email Field ─────────────────────────────
                                TextFormField(
                                  controller: _emailController,
                                  style: TextStyle(color: textColor),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: goalInputDecoration(
                                    'Email address',
                                    Icons.email_rounded,
                                  ).copyWith(
                                    hintText: 'you@example.com',
                                  ),
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

                                // ── Password Field ──────────────────────────
                                TextFormField(
                                  controller: _passwordController,
                                  style: TextStyle(color: textColor),
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleEmailAuth(),
                                  decoration: goalInputDecoration(
                                    'Password',
                                    Icons.lock_rounded,
                                  ).copyWith(
                                    hintText: 'Min. 6 characters',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: mutedColor,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() =>
                                            _obscurePassword = !_obscurePassword);
                                      },
                                      tooltip: _obscurePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    if (value.length > 128) {
                                      return 'Password is too long';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),

                                // ── Error Message ───────────────────────────
                                if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.error.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            color: AppColors.error,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animate(
                                      key: ValueKey(_errorMessage),
                                    ).shake(duration: 400.ms),
                                  ),

                                const SizedBox(height: 20),

                                // ── Submit Button ───────────────────────────
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: FilledButton(
                                    onPressed: _isLoading ? null : _handleEmailAuth,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.lime,
                                      foregroundColor: AppColors.ink,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: AppColors.ink,
                                            ),
                                          )
                                        : Text(
                                            _isLogin ? 'Sign In' : 'Create Account',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Footer hint ──────────────────────────────────────
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          children: [
                            Text(
                              'Your data stays on your device',
                              style: TextStyle(
                                fontSize: 11,
                                color: mutedColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
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
