import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Confetti overlay widget that displays a celebratory particle burst.
/// Shows colorful confetti pieces falling from the top of the screen.
class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool show;

  const ConfettiOverlay({
    super.key,
    required this.child,
    this.show = false,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final _random = Random();

  static const List<Color> _confettiColors = [
    Color(0xFFA8FF3E), // Lime
    Color(0xFF00E676), // Green
    Color(0xFFFF6B9D), // Pink
    Color(0xFFFFD93D), // Yellow
    Color(0xFF00D9FF), // Cyan
    Color(0xFF9D4EDD), // Purple
    Color(0xFFFF7043), // Orange
    Color(0xFF52B788), // Teal
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _burstConfetti();
    }
  }

  void _burstConfetti() {
    _particles.clear();
    for (int i = 0; i < 60; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: -0.1 - _random.nextDouble() * 0.3,
        speed: 0.008 + _random.nextDouble() * 0.015,
        size: 6 + _random.nextDouble() * 10,
        color: _confettiColors[_random.nextInt(_confettiColors.length)],
        rotation: _random.nextDouble() * 6.28,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
        sway: (_random.nextDouble() - 0.5) * 0.04,
      ));
    }
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.show)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = _controller.value;
              if (progress >= 1.0) return const SizedBox.shrink();

              for (final p in _particles) {
                p.y += p.speed;
                p.x += p.sway * sin(progress * 20);
                p.rotation += p.rotationSpeed;
              }

              return IgnorePointer(
                child: CustomPaint(
                  size: MediaQuery.sizeOf(context),
                  painter: _ConfettiPainter(_particles, progress),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  double x, y;
  final double speed;
  final double size;
  final Color color;
  double rotation;
  final double rotationSpeed;
  final double sway;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.sway,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.y > 1.1) continue;
      if (progress > 0.95) {
        // Fade out near the end
        final alpha = ((1.0 - progress) / 0.05).clamp(0.0, 1.0);
        canvas.save();
        canvas.translate(p.x * size.width, p.y * size.height);
        canvas.rotate(p.rotation);
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        );
        canvas.drawRRect(
          rect,
          Paint()..color = p.color.withValues(alpha: alpha),
        );
        canvas.restore();
      } else {
        canvas.save();
        canvas.translate(p.x * size.width, p.y * size.height);
        canvas.rotate(p.rotation);
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        );
        canvas.drawRRect(rect, Paint()..color = p.color);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}

/// A simple success celebration overlay that shows a checkmark + confetti.
class CelebrationOverlay extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const CelebrationOverlay({
    super.key,
    required this.message,
    this.onTap,
  });

  static void show(BuildContext context, {required String message, VoidCallback? onTap}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => CelebrationOverlay(message: message, onTap: onTap),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            constraints: const BoxConstraints(maxWidth: 380),
            decoration: BoxDecoration(
              color: isDark ? AppColors.panel : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.lime.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lime.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 28),
                // Trophy icon with glow
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.lime, Color(0xFF5FDE9E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lime.withValues(alpha: 0.4),
                        blurRadius: 25,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.ink,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '🎉 Goal Complete!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.white : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.muted : AppColors.lightMuted,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        onTap?.call();
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.lime,
                        foregroundColor: AppColors.ink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '🎉 Awesome!',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
