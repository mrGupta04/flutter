import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/health_package_visuals.dart';
import '../../data/models/health_package.dart';

/// Layout constants for premium health test cards.
abstract final class HealthTestCardTheme {
  static const double cardWidth = 170;
  static const double cardHeight = 210;
  static const double borderRadius = 24;
  static const double padding = 14;
  static const double illustrationHeight = 118;
  static const double shadowBlur = 25;
  static const double shadowOpacity = 0.08;
  static const Duration animationDuration = Duration(milliseconds: 220);
}

/// Premium healthcare test card with transparent organ illustration hero.
class HealthPackageCard extends StatefulWidget {
  const HealthPackageCard({
    super.key,
    required this.package,
    this.onTap,
    this.heroTag,
    this.width,
    this.height,
  });

  final HealthPackage package;
  final VoidCallback? onTap;
  final String? heroTag;
  final double? width;
  final double? height;

  @override
  State<HealthPackageCard> createState() => _HealthPackageCardState();
}

class _HealthPackageCardState extends State<HealthPackageCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _badgeController;

  HealthPackage get pkg => widget.package;

  HealthPackageVisual get visual => HealthPackageVisuals.forId(pkg.id);

  @override
  void initState() {
    super.initState();
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _badgeController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.width ?? HealthTestCardTheme.cardWidth;
    final cardHeight = widget.height ?? HealthTestCardTheme.cardHeight;
    final visual = this.visual;
    final shadowOpacity = _pressed
        ? HealthTestCardTheme.shadowOpacity * 1.6
        : HealthTestCardTheme.shadowOpacity;

    return Semantics(
      button: widget.onTap != null,
      label: '${pkg.title}, rupees ${pkg.price.round()}',
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => _setPressed(true) : null,
        onTapUp: widget.onTap != null ? (_) => _setPressed(false) : null,
        onTapCancel: widget.onTap != null ? () => _setPressed(false) : null,
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: HealthTestCardTheme.animationDuration,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: HealthTestCardTheme.animationDuration,
            curve: Curves.easeOutCubic,
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(HealthTestCardTheme.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: shadowOpacity),
                  blurRadius: _pressed
                      ? HealthTestCardTheme.shadowBlur + 8
                      : HealthTestCardTheme.shadowBlur,
                  offset: Offset(0, _pressed ? 10 : 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(HealthTestCardTheme.borderRadius),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: visual.cardGradient,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MedicalPatternPainter(
                            pattern: visual.pattern,
                            color: visual.accent,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(
                          HealthTestCardTheme.padding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    pkg.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                      letterSpacing: -0.3,
                                      color: const Color(0xFF101828),
                                    ),
                                  ),
                                ),
                                if (pkg.discount > 0) ...[
                                  const SizedBox(width: 6),
                                  ScaleTransition(
                                    scale: CurvedAnimation(
                                      parent: _badgeController,
                                      curve: Curves.elasticOut,
                                    ),
                                    child: _DiscountBadge(
                                      label: '${pkg.discount}% OFF',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            _HeadingDivider(accent: visual.accent),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      bottom: 4,
                                      child: Container(
                                        width: 78,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          boxShadow: [
                                            BoxShadow(
                                              color: visual.accent
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 16,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Hero(
                                      tag: widget.heroTag ??
                                          'organ_${pkg.id}',
                                      child: Image.asset(
                                        visual.organAsset,
                                        height: 108,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                          Icons.biotech_rounded,
                                          size: 64,
                                          color: visual.accent
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _BookPriceButton(
                              price: pkg.price,
                              onBook: widget.onTap,
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
        ),
      ),
    );
  }
}

class _HeadingDivider extends StatelessWidget {
  const _HeadingDivider({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.0),
                        accent.withValues(alpha: 0.45),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.45),
                        accent.withValues(alpha: 0.0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6A6A), Color(0xFFFF4B5C)],
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4B5C).withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 8.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _BookPriceButton extends StatelessWidget {
  const _BookPriceButton({
    required this.price,
    this.onBook,
  });

  final double price;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBook,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Book',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '₹${price.round()}',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicalPatternPainter extends CustomPainter {
  const _MedicalPatternPainter({
    required this.pattern,
    required this.color,
  });

  final HealthCardPattern pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    switch (pattern) {
      case HealthCardPattern.ecg:
        _drawEcg(canvas, size, paint);
      case HealthCardPattern.dna:
        _drawDna(canvas, size, paint);
      case HealthCardPattern.dots:
        _drawDots(canvas, size, paint);
      case HealthCardPattern.hexagon:
        _drawHexagons(canvas, size, paint);
    }
  }

  void _drawEcg(Canvas canvas, Size size, Paint paint) {
    final path = Path()..moveTo(0, size.height * 0.72);
    for (var x = 0.0; x <= size.width; x += 6) {
      final y = size.height * 0.72 +
          math.sin(x / 18) * 4 +
          (x % 48 < 4 ? -10 : 0) +
          (x % 72 > 34 && x % 72 < 40 ? 14 : 0);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  void _drawDna(Canvas canvas, Size size, Paint paint) {
    for (var x = 12.0; x < size.width; x += 18) {
      canvas.drawLine(
        Offset(x, size.height * 0.2),
        Offset(x + 8, size.height * 0.8),
        paint,
      );
      canvas.drawCircle(
        Offset(x, size.height * 0.35),
        2.2,
        paint..style = PaintingStyle.fill,
      );
      canvas.drawCircle(Offset(x + 8, size.height * 0.65), 2.2, paint);
      paint.style = PaintingStyle.stroke;
    }
  }

  void _drawDots(Canvas canvas, Size size, Paint paint) {
    paint.style = PaintingStyle.fill;
    for (var row = 0; row < 6; row++) {
      for (var col = 0; col < 8; col++) {
        canvas.drawCircle(
          Offset(10 + col * 20.0, 12 + row * 18.0),
          1.4,
          paint,
        );
      }
    }
  }

  void _drawHexagons(Canvas canvas, Size size, Paint paint) {
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 4; col++) {
        final cx = 18 + col * 42.0 + (row.isOdd ? 18 : 0);
        final cy = 20 + row * 36.0;
        _drawHex(canvas, Offset(cx, cy), 12, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 6;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MedicalPatternPainter oldDelegate) =>
      oldDelegate.pattern != pattern || oldDelegate.color != color;
}

/// Skeleton placeholder matching premium card dimensions.
class HealthPackageCardSkeleton extends StatelessWidget {
  const HealthPackageCardSkeleton({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkSurface : AppColors.grey100;
    final highlight =
        isDark ? AppColors.darkSurfaceElevated : AppColors.grey50;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width ?? HealthTestCardTheme.cardWidth,
        height: height ?? HealthTestCardTheme.cardHeight,
        decoration: BoxDecoration(
          color: base,
          borderRadius:
              BorderRadius.circular(HealthTestCardTheme.borderRadius),
        ),
      ),
    );
  }
}
