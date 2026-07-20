import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/responsive_metrics.dart';
import '../../widgets/app_background.dart';

/// Three-page onboarding flow shown on first launch.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _coinController;
  int _page = 0;

  final pages = const [
    _OnboardingPageData(
      title: 'Save for the\nProducts You Want',
      body: 'Create product goals, monitor your progress, and build saving discipline step by step.',
      icon: Icons.savings_rounded,
    ),
    _OnboardingPageData(
      title: 'Build Money\nDiscipline',
      body: 'Use reminders, streaks, recurring deposits, and clear milestones to make saving realistic.',
      icon: Icons.event_repeat_rounded,
    ),
    _OnboardingPageData(
      title: 'Understand Your\nHabits',
      body: 'Track trends, budget health, completion dates, and weekly contribution patterns in one place.',
      icon: Icons.analytics_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _coinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(metrics.pagePadding, 18, metrics.pagePadding, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      if (_page < pages.length - 1)
                        TextButton(
                          onPressed: widget.onComplete,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.muted,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _AnimatedProgressDots(count: pages.length, index: _page),
                  const SizedBox(height: 18),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (value) => setState(() => _page = value),
                      itemCount: pages.length,
                      itemBuilder: (context, index) => _OnboardingPage(
                        data: pages[index],
                        animation: _coinController,
                      ),
                    ),
                  ),
                  _OnboardingCTAButton(
                    isLast: _page == pages.length - 1,
                    onPressed: () {
                      final currentPage = (_pageController.hasClients
                              ? _pageController.page
                              : _page.toDouble()) ??
                          _page.toDouble();
                      if (_page == pages.length - 1 || currentPage >= pages.length - 1.2) {
                        widget.onComplete();
                        return;
                      }
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
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
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.body,
    required this.icon,
  });
  final String title;
  final String body;
  final IconData icon;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.animation});

  final _OnboardingPageData data;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 610;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: compact ? 230 : 310,
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) => CustomPaint(
                      painter: _SavingJarPainter(
                        progress: animation.value,
                        accentIcon: data.icon,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 16 : 28),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: AppText.hero.copyWith(fontSize: metrics.heroFont),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Text(
                    data.body,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(height: 1.55, fontSize: metrics.bodyFont),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedProgressDots extends StatelessWidget {
  const _AnimatedProgressDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 22 : 8,
          decoration: BoxDecoration(
            color: active ? AppColors.lime : AppColors.muted.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _OnboardingCTAButton extends StatelessWidget {
  const _OnboardingCTAButton({required this.isLast, required this.onPressed});

  final bool isLast;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: const ValueKey('onboarding-cta'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 14,
        shadowColor: AppColors.lime.withValues(alpha: .22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isLast ? 'Open Dashboard' : 'Continue',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}

class _SavingJarPainter extends CustomPainter {
  _SavingJarPainter({required this.progress, required this.accentIcon});

  final double progress;
  final IconData accentIcon;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.34;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.lime.withValues(alpha: 0.18),
          AppColors.lime.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(accentIcon.codePoint),
        style: TextStyle(
          fontSize: radius * 0.55,
          fontFamily: accentIcon.fontFamily,
          package: accentIcon.fontPackage,
          color: AppColors.lime,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(center.dx - iconPainter.width / 2, center.dy - iconPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SavingJarPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accentIcon.codePoint != accentIcon.codePoint;
}
