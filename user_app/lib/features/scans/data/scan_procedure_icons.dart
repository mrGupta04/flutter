import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/media_url_utils.dart';
import 'scan_modality_assets.dart';
import 'scan_modality_logos.dart';
import 'models/scan_procedure_model.dart';

export 'scan_modality_assets.dart'
    show
        ScanModalityAssets,
        scanProcedureAssetFor,
        scanCategoryAssetFor,
        scanProcedureNetworkImage,
        scanOfferedNetworkImage;

/// Category-level brand colors for MRI, CT, X-Ray, etc.
extension ScanCategoryX on ScanCategory {
  Color get iconColor {
    return switch (this) {
      ScanCategory.mri => const Color(0xFF5C6BC0),
      ScanCategory.ct => const Color(0xFF00897B),
      ScanCategory.xray => const Color(0xFF546E7A),
      ScanCategory.ultrasound => const Color(0xFF1E88E5),
      ScanCategory.pet => const Color(0xFF8E24AA),
      ScanCategory.mammography => const Color(0xFFEC407A),
      ScanCategory.ecg => const Color(0xFFE53935),
      ScanCategory.eeg => const Color(0xFF7B1FA2),
      ScanCategory.echo => const Color(0xFFD81B60),
      ScanCategory.doppler => const Color(0xFF039BE5),
      ScanCategory.dexa => const Color(0xFF6D4C41),
      ScanCategory.fluoroscopy => const Color(0xFF5E35B1),
      ScanCategory.endoscopy => const Color(0xFF43A047),
      ScanCategory.colonoscopy => const Color(0xFFFB8C00),
      ScanCategory.bronchoscopy => const Color(0xFF29B6F6),
      ScanCategory.tmt => const Color(0xFFEF6C00),
      ScanCategory.ncv => const Color(0xFF00838F),
      ScanCategory.emg => const Color(0xFFF9A825),
      ScanCategory.other => AppColors.info,
    };
  }

  Color get softColor => iconColor.withValues(alpha: 0.12);

  ScanModalityLogo get logo => scanLogoForCategory(this);

  String get assetPath => scanCategoryAssetFor(this);
}

extension ScanProcedureX on ScanProcedure {
  Color get iconColor => category.iconColor;

  ScanModalityLogo get logo => scanLogoForProcedure(this);

  String get assetPath => scanProcedureAssetFor(this);

  String? get networkImageUrl => scanProcedureNetworkImage(this);
}

/// Shows API scan image when present, otherwise a real local organ/modality PNG.
class ScanProcedureImage extends StatelessWidget {
  const ScanProcedureImage({
    super.key,
    required this.procedure,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius = 10,
    this.padding = 6,
    this.networkOverride,
  });

  final ScanProcedure procedure;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final double padding;
  final String? networkOverride;

  @override
  Widget build(BuildContext context) {
    final color = procedure.iconColor;
    final network = MediaUrlUtils.resolve(
      networkOverride ?? procedure.networkImageUrl,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: color.withValues(alpha: 0.08),
        child: network.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: network,
                fit: BoxFit.cover,
                placeholder: (_, __) => _AssetFallback(
                  assetPath: procedure.assetPath,
                  color: color,
                  padding: padding,
                  fit: fit,
                ),
                errorWidget: (_, __, ___) => _AssetFallback(
                  assetPath: procedure.assetPath,
                  color: color,
                  padding: padding,
                  fit: fit,
                ),
              )
            : _AssetFallback(
                assetPath: procedure.assetPath,
                color: color,
                padding: padding,
                fit: fit,
              ),
      ),
    );
  }
}

class _AssetFallback extends StatelessWidget {
  const _AssetFallback({
    required this.assetPath,
    required this.color,
    required this.padding,
    required this.fit,
  });

  final String assetPath;
  final Color color;
  final double padding;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color.withValues(alpha: 0.06),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Image.asset(
          assetPath,
          fit: fit,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(Icons.radar_rounded, color: color, size: 28),
          ),
        ),
      ),
    );
  }
}

/// Circular color logo badge for a scan procedure.
class ScanProcedureIconAvatar extends StatelessWidget {
  const ScanProcedureIconAvatar({
    super.key,
    required this.procedure,
    this.size = 44,
    this.iconSize = 22,
    this.networkOverride,
  });

  final ScanProcedure procedure;
  final double size;
  final double iconSize;
  final String? networkOverride;

  @override
  Widget build(BuildContext context) {
    return ScanProcedureImage(
      procedure: procedure,
      width: size,
      height: size,
      borderRadius: size * 0.28,
      padding: size * 0.12,
      networkOverride: networkOverride,
      fit: BoxFit.contain,
    );
  }
}

/// Category logo badge used in browse rows / section headers.
class ScanCategoryLogoBadge extends StatelessWidget {
  const ScanCategoryLogoBadge({
    super.key,
    required this.category,
    this.size = 40,
  });

  final ScanCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = category.iconColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: Container(
        width: size,
        height: size,
        color: color.withValues(alpha: 0.1),
        padding: EdgeInsets.all(size * 0.12),
        child: Image.asset(
          category.assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) =>
              ScanModalityLogoIcon.forCategory(
            category,
            size: size * 0.52,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Thumbnail with real scan / organ picture for procedure cards.
class ScanProcedureThumb extends StatelessWidget {
  const ScanProcedureThumb({
    super.key,
    required this.procedure,
    this.width = 72,
    this.height = 56,
    this.networkOverride,
  });

  final ScanProcedure procedure;
  final double width;
  final double height;
  final String? networkOverride;

  @override
  Widget build(BuildContext context) {
    return ScanProcedureImage(
      procedure: procedure,
      width: width,
      height: height,
      borderRadius: 10,
      padding: 4,
      networkOverride: networkOverride,
      fit: BoxFit.contain,
    );
  }
}
