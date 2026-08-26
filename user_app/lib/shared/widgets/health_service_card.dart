import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_utils.dart';

enum HealthServiceCardType { asset, designed }

class HealthServiceItem {
  const HealthServiceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.type = HealthServiceCardType.designed,
    this.illustrationImage,
    this.image,
    this.assetAspectRatio,
    this.illustrationScale = 1.0,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final HealthServiceCardType type;
  final String? illustrationImage;
  final String? image;
  final double? assetAspectRatio;
  final double illustrationScale;
}

/// Two-column service grid for the home dashboard.
class HealthServiceGrid extends StatelessWidget {
  const HealthServiceGrid({
    super.key,
    required this.items,
    this.title = 'What are you looking for?',
    this.cardsPerRow = 2,
  });

  final List<HealthServiceItem> items;
  final String title;
  final int cardsPerRow;

  static const double _gridGap = 16;
  static const double _horizontalPadding = 16;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.valueFor(
          context,
          mobile: _horizontalPadding,
          tablet: 24,
          laptop: 32,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final perRow = _columnsForWidth(
            constraints.maxWidth,
            fallback: cardsPerRow < 1 ? 1 : cardsPerRow,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveUtils.valueFor(
                    context,
                    mobile: 18,
                    tablet: 20,
                    desktop: 22,
                  ),
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              for (var row = 0; row < items.length; row += perRow) ...[
                if (row > 0) const SizedBox(height: _gridGap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var col = 0; col < perRow; col++) ...[
                      if (col > 0) const SizedBox(width: _gridGap),
                      Expanded(
                        child: row + col < items.length
                            ? _buildCard(items[row + col])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Mobile: 2 columns. Tablet and up: 2–3 based on available width.
  static int _columnsForWidth(double width, {required int fallback}) {
    if (width >= 720) return 3;
    return fallback < 1 ? 2 : fallback;
  }

  Widget _buildCard(HealthServiceItem item) {
    if (item.type == HealthServiceCardType.asset && item.image != null) {
      return HealthServiceAssetCard(
        image: item.image!,
        aspectRatio: item.assetAspectRatio ?? 0.89,
        accentColor: item.color,
        semanticLabel: '${item.title.replaceAll('\n', ' ')}. ${item.subtitle}',
        onTap: item.onTap,
      );
    }

    return HealthServiceCard(
      title: item.title,
      subtitle: item.subtitle,
      icon: item.icon,
      color: item.color,
      illustrationImage: item.illustrationImage ?? '',
      illustrationScale: item.illustrationScale,
      onTap: item.onTap,
    );
  }
}

/// Shared hover / press interaction shell for service cards.
class _InteractiveServiceCardShell extends StatefulWidget {
  const _InteractiveServiceCardShell({
    required this.accentColor,
    required this.onTap,
    required this.child,
    this.borderRadius = 28,
  });

  final Color accentColor;
  final VoidCallback onTap;
  final Widget child;
  final double borderRadius;

  @override
  State<_InteractiveServiceCardShell> createState() =>
      _InteractiveServiceCardShellState();
}

class _InteractiveServiceCardShellState
    extends State<_InteractiveServiceCardShell> {
  bool _hovered = false;
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  List<BoxShadow> _shadows() {
    if (_pressed) {
      return [
        BoxShadow(
          color: widget.accentColor.withValues(alpha: 0.12),
          blurRadius: 14,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }

    if (_hovered) {
      return [
        BoxShadow(
          color: widget.accentColor.withValues(alpha: 0.28),
          blurRadius: 32,
          offset: const Offset(0, 16),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: widget.accentColor.withValues(alpha: 0.12),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];
    }

    return [
      BoxShadow(
        color: widget.accentColor.withValues(alpha: 0.16),
        blurRadius: 22,
        offset: const Offset(0, 10),
        spreadRadius: -2,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.07),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.978 : (_hovered ? 1.015 : 1.0);
    final lift = _hovered && !_pressed ? -5.0 : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, lift, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: _shadows(),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Pixel-perfect pre-rendered service card image from the design reference.
class HealthServiceAssetCard extends StatelessWidget {
  const HealthServiceAssetCard({
    super.key,
    required this.image,
    required this.onTap,
    required this.accentColor,
    this.aspectRatio = 0.89,
    this.semanticLabel,
  });

  final String image;
  final VoidCallback onTap;
  final Color accentColor;
  final double aspectRatio;
  final String? semanticLabel;

  static const double _borderRadius = 28;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: _InteractiveServiceCardShell(
        accentColor: accentColor,
        borderRadius: _borderRadius,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_borderRadius),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Image.asset(
              image,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      ),
    );
  }
}

/// Composed service card with layered UI elements and 3D illustration assets.
class HealthServiceCard extends StatelessWidget {
  const HealthServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.illustrationImage,
    required this.onTap,
    this.illustrationScale = 1.0,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String illustrationImage;
  final VoidCallback onTap;
  final double illustrationScale;

  static const double _borderRadius = 28;
  static const double _aspectRatio = 0.89;
  static const double _contentPadding = 16;

  Color get _backgroundTint => Color.lerp(Colors.white, color, 0.06)!;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = cardWidth / _aspectRatio;

        return _InteractiveServiceCardShell(
          accentColor: color,
          borderRadius: _borderRadius,
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_borderRadius),
            child: AspectRatio(
              aspectRatio: _aspectRatio,
              child: Container(
                color: _backgroundTint,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    CustomPaint(
                      painter: _CardBlobPainter(color: color),
                      size: Size.infinite,
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: _DecorativeDotGrid(
                        color: color.withValues(alpha: 0.22),
                      ),
                    ),
                    if (illustrationImage.isNotEmpty)
                      Positioned(
                        right: illustrationScale > 1 ? -8 : 0,
                        bottom: illustrationScale > 1 ? 8 : 16,
                        width: cardWidth * 0.56 * illustrationScale,
                        height: cardHeight * 0.82 * illustrationScale,
                        child: Image.asset(
                          illustrationImage,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomRight,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(_contentPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IconBadge(icon: icon, color: color),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: cardWidth * 0.52,
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                                letterSpacing: -0.3,
                                color: Color(0xFF101828),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 24,
                            height: 3,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: cardWidth * 0.50,
                            child: Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w400,
                                height: 1.38,
                                color: Color(0xFF667085),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color,
                              Color.lerp(color, Colors.black, 0.12)!,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.45),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.15)!,
            color,
          ],
        ).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: Icon(icon, size: 18),
      ),
    );
  }
}

/// Organic wavy blob shapes in the card background.
class _CardBlobPainter extends CustomPainter {
  const _CardBlobPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
      Offset(w * 0.88, h * 0.78),
      w * 0.42,
      Paint()..color = color.withValues(alpha: 0.09),
    );

    canvas.drawCircle(
      Offset(w * 0.95, h * 0.55),
      w * 0.28,
      Paint()..color = color.withValues(alpha: 0.06),
    );

    _drawBlob(
      canvas,
      color.withValues(alpha: 0.07),
      Path()
        ..moveTo(0, h * 0.55)
        ..cubicTo(w * 0.06, h * 0.72, w * 0.28, h * 0.88, w * 0.48, h * 0.82)
        ..cubicTo(w * 0.65, h * 0.76, w * 0.78, h * 0.92, w, h * 0.95)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
    );

    _drawBlob(
      canvas,
      color.withValues(alpha: 0.04),
      Path()
        ..moveTo(-w * 0.04, h * 0.28)
        ..cubicTo(w * 0.08, h * 0.14, w * 0.18, h * 0.36, w * 0.08, h * 0.52)
        ..cubicTo(0, h * 0.65, -w * 0.02, h * 0.44, -w * 0.04, h * 0.28)
        ..close(),
    );
  }

  void _drawBlob(Canvas canvas, Color fill, Path path) {
    canvas.drawPath(
      path,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _CardBlobPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 4×4 decorative dot grid in the top-right corner.
class _DecorativeDotGrid extends StatelessWidget {
  const _DecorativeDotGrid({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    const dotSize = 3.0;
    const gap = 3.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        4,
        (row) => Padding(
          padding: EdgeInsets.only(bottom: row < 3 ? gap : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              4,
              (col) => Container(
                width: dotSize,
                height: dotSize,
                margin: EdgeInsets.only(right: col < 3 ? gap : 0),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
