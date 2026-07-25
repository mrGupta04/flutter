import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'lab_organ_logos.dart';

/// Premium medical illustration badge for lab tests and browse groups.
class LabTestLogo extends StatelessWidget {
  const LabTestLogo({
    super.key,
    required this.illustrationPath,
    required this.color,
    this.fallbackLogo,
    this.size = 32,
    this.watermarkOpacity = 0.10,
  });

  final String illustrationPath;
  final Color color;
  final LabOrganLogo? fallbackLogo;
  final double size;
  final double watermarkOpacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: watermarkOpacity,
          child: SvgPicture.asset(
            illustrationPath,
            width: size * 1.35,
            height: size * 1.35,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
        SvgPicture.asset(
          illustrationPath,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          placeholderBuilder: fallbackLogo == null
              ? null
              : (_) => CustomPaint(
                    painter: LabOrganLogoPainter(
                      logo: fallbackLogo!,
                      color: color,
                    ),
                  ),
        ),
      ],
    );
  }
}

/// Rectangular profile thumbnail used on individual test cards.
class LabTestProfileThumbnail extends StatelessWidget {
  const LabTestProfileThumbnail({
    super.key,
    required this.illustrationPath,
    required this.color,
    this.organAssetPath,
    this.fallbackLogo,
    this.width = 72,
    this.height = 56,
    this.logoSize = 30,
    this.borderRadius = 10,
  });

  final String illustrationPath;
  final Color color;
  final String? organAssetPath;
  final LabOrganLogo? fallbackLogo;
  final double width;
  final double height;
  final double logoSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF21262D) : Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: color.withValues(alpha: 0.12)),
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              surface,
              color.withValues(alpha: isDark ? 0.10 : 0.06),
              color.withValues(alpha: isDark ? 0.16 : 0.12),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: organAssetPath != null
            ? Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  organAssetPath!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => LabTestLogo(
                    illustrationPath: illustrationPath,
                    color: color,
                    fallbackLogo: fallbackLogo,
                    size: logoSize,
                  ),
                ),
              )
            : LabTestLogo(
                illustrationPath: illustrationPath,
                color: color,
                fallbackLogo: fallbackLogo,
                size: logoSize,
              ),
      ),
    );
  }
}

/// Circular avatar variant for compact list rows.
class LabTestProfileAvatar extends StatelessWidget {
  const LabTestProfileAvatar({
    super.key,
    required this.illustrationPath,
    required this.color,
    this.organAssetPath,
    this.fallbackLogo,
    this.size = 44,
    this.logoSize = 22,
  });

  final String illustrationPath;
  final Color color;
  final String? organAssetPath;
  final LabOrganLogo? fallbackLogo;
  final double size;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF21262D) : Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: surface,
        border: Border.all(color: color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        gradient: RadialGradient(
          colors: [
            surface,
            color.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: Center(
        child: organAssetPath != null
            ? Padding(
                padding: EdgeInsets.all(size * 0.08),
                child: Image.asset(
                  organAssetPath!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => LabTestLogo(
                    illustrationPath: illustrationPath,
                    color: color,
                    fallbackLogo: fallbackLogo,
                    size: logoSize,
                    watermarkOpacity: 0.08,
                  ),
                ),
              )
            : LabTestLogo(
                illustrationPath: illustrationPath,
                color: color,
                fallbackLogo: fallbackLogo,
                size: logoSize,
                watermarkOpacity: 0.08,
              ),
      ),
    );
  }
}
