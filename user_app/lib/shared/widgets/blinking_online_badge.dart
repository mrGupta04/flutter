import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Red accent for doctors currently live in the app.
const Color kLiveOnlineColor = AppColors.error;

/// Eye-catching color-blinking "Online now" badge for doctors currently using the app.
class BlinkingOnlineBadge extends StatefulWidget {
  const BlinkingOnlineBadge({super.key, this.compact = false});

  final bool compact;

  @override
  State<BlinkingOnlineBadge> createState() => _BlinkingOnlineBadgeState();
}

class _BlinkingOnlineBadgeState extends State<BlinkingOnlineBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = _pulse.value;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 7 : 9,
            vertical: widget.compact ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: kLiveOnlineColor.withValues(alpha: 0.1 + glow * 0.16),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: kLiveOnlineColor.withValues(alpha: 0.45 + glow * 0.55),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlinkingOnlineDot(size: widget.compact ? 6 : 7, pulse: glow),
              const SizedBox(width: 5),
              Text(
                'Online now',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Color.lerp(
                    kLiveOnlineColor.withValues(alpha: 0.7),
                    kLiveOnlineColor,
                    glow,
                  ),
                  fontWeight: FontWeight.w800,
                  fontSize: widget.compact ? 9 : 10,
                  height: 1,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Small pulsing red dot — use on avatars or compact layouts.
class BlinkingOnlineDot extends StatefulWidget {
  const BlinkingOnlineDot({
    super.key,
    this.size = 10,
    this.pulse,
    this.showRing = true,
  });

  final double size;
  final double? pulse;
  final bool showRing;

  @override
  State<BlinkingOnlineDot> createState() => _BlinkingOnlineDotState();
}

class _BlinkingOnlineDotState extends State<BlinkingOnlineDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _localPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
    _localPulse = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final externalPulse = widget.pulse;

    if (externalPulse != null) {
      return _dot(externalPulse);
    }

    return AnimatedBuilder(
      animation: _localPulse,
      builder: (context, _) => _dot(_localPulse.value),
    );
  }

  Widget _dot(double glow) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(
          kLiveOnlineColor.withValues(alpha: 0.5),
          kLiveOnlineColor,
          glow,
        ),
        border: widget.showRing
            ? Border.all(
                color: AppColors.white.withValues(alpha: 0.9),
                width: 1.2,
              )
            : null,
      ),
    );
  }
}

/// Pulsing red ring around a live doctor's profile photo.
class BlinkingLiveAvatarBorder extends StatefulWidget {
  const BlinkingLiveAvatarBorder({
    super.key,
    required this.child,
    this.padding = 3,
    this.borderWidth = 2.5,
  });

  final Widget child;
  final double padding;
  final double borderWidth;

  @override
  State<BlinkingLiveAvatarBorder> createState() =>
      _BlinkingLiveAvatarBorderState();
}

class _BlinkingLiveAvatarBorderState extends State<BlinkingLiveAvatarBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = _pulse.value;
        return Container(
          padding: EdgeInsets.all(widget.padding),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: kLiveOnlineColor.withValues(alpha: 0.55 + glow * 0.45),
              width: widget.borderWidth,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Avatar overlay indicator for online doctors.
class BlinkingOnlineAvatarBadge extends StatelessWidget {
  const BlinkingOnlineAvatarBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
      ),
      child: const BlinkingOnlineDot(size: 11),
    );
  }
}
