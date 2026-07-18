import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'scan_modality_logos.dart';
import 'models/scan_procedure_model.dart';

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
}

extension ScanProcedureX on ScanProcedure {
  Color get iconColor => category.iconColor;

  ScanModalityLogo get logo => scanLogoForProcedure(this);
}

/// Circular color logo badge for a scan procedure.
class ScanProcedureIconAvatar extends StatelessWidget {
  const ScanProcedureIconAvatar({
    super.key,
    required this.procedure,
    this.size = 44,
    this.iconSize = 22,
  });

  final ScanProcedure procedure;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final color = procedure.iconColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.18)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: ScanModalityLogoIcon.forProcedure(
          procedure,
          size: iconSize,
          color: Colors.white,
        ),
      ),
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.18)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: ScanModalityLogoIcon.forCategory(
          category,
          size: size * 0.52,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Colorful thumb with modality logo (MRI bore, CT ring, X-ray, etc.).
class ScanProcedureThumb extends StatelessWidget {
  const ScanProcedureThumb({
    super.key,
    required this.procedure,
    this.width = 72,
    this.height = 56,
  });

  final ScanProcedure procedure;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = procedure.iconColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.18),
              Color.lerp(color.withValues(alpha: 0.08), Colors.white, 0.4)!,
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/home_cards/diagnostic_scans.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.22),
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.55),
                    color.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, Color.lerp(color, Colors.black, 0.2)!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: ScanModalityLogoIcon.forProcedure(
                    procedure,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
