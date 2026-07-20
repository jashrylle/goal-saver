import 'package:flutter/material.dart';

/// Messenger-style in-app toast overlay.
///
/// Shows a banner sliding down from the top of the screen with icon, message,
/// and auto-dismiss. Can be triggered from anywhere via [ToastService.show()].
class ToastService {
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;
  ToastService._internal();

  OverlayEntry? _currentEntry;
  bool _isShowing = false;

  /// Show a toast overlay on the app.
  ///
  /// [message] is the text to display.
  /// [icon] is an optional icon (defaults to a green checkmark).
  /// [backgroundColor] defaults to a dark green for success.
  /// [duration] controls auto-dismiss time.
  /// [onTap] is an optional callback when the toast is tapped.
  void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    if (_isShowing) {
      _dismiss();
    }

    _isShowing = true;

    _currentEntry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        icon: icon ?? Icons.check_circle_rounded,
        backgroundColor: backgroundColor ?? const Color(0xFF1B5E20),
        onDismiss: _dismiss,
        onTap: onTap,
      ),
    );

    Overlay.of(context).insert(_currentEntry!);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (_isShowing) {
        _dismiss();
      }
    });
  }

  /// Convenience: show a success toast (green, checkmark).
  void success(BuildContext context, String message, {VoidCallback? onTap}) {
    show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF1B5E20),
      onTap: onTap,
    );
  }

  /// Convenience: show an error toast (red, warning).
  void error(BuildContext context, String message, {VoidCallback? onTap}) {
    show(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFFB71C1C),
      onTap: onTap,
    );
  }

  /// Convenience: show an info toast (blue, info).
  void info(BuildContext context, String message, {VoidCallback? onTap}) {
    show(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: const Color(0xFF0D47A1),
      onTap: onTap,
    );
  }

  /// Convenience: show an achievement toast (gold, trophy).
  void achievement(BuildContext context, String message, {VoidCallback? onTap}) {
    show(
      context,
      message: message,
      icon: Icons.emoji_events_rounded,
      backgroundColor: const Color(0xFFE65100),
      duration: const Duration(seconds: 4),
      onTap: onTap,
    );
  }

  void _dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
    _isShowing = false;
  }
}

/// The actual overlay widget with slide animation and swipe-to-dismiss.
class _ToastOverlay extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const _ToastOverlay({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.onDismiss,
    this.onTap,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: GestureDetector(
            onTap: () {
              widget.onTap?.call();
              _dismiss();
            },
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < -200) {
                _dismiss();
              }
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: widget.backgroundColor,
              shadowColor: widget.backgroundColor.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismiss,
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
