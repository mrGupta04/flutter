import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../presentation/widgets/lab_organ_logos.dart';
import 'models/lab_test_model.dart';

/// Category-level icons for kidney, liver, vitamins, allergy, etc.
extension LabTestCategoryX on LabTestCategory {
  IconData get icon {
    return switch (this) {
      LabTestCategory.bloodTests => Icons.bloodtype_outlined,
      LabTestCategory.urineTests => Icons.water_drop_outlined,
      LabTestCategory.thyroidTests => Icons.monitor_heart_outlined,
      LabTestCategory.diabetesTests => Icons.bloodtype_rounded,
      LabTestCategory.liverFunctionTests => Icons.healing_outlined,
      LabTestCategory.kidneyFunctionTests => Icons.filter_alt_outlined,
      LabTestCategory.lipidProfile => Icons.favorite_outline_rounded,
      LabTestCategory.vitaminTests => Icons.wb_sunny_outlined,
      LabTestCategory.hormoneTests => Icons.biotech_outlined,
      LabTestCategory.allergyTests => Icons.coronavirus_outlined,
      LabTestCategory.covid19Tests => Icons.masks_outlined,
      LabTestCategory.fullBodyCheckups => Icons.health_and_safety_outlined,
      LabTestCategory.other => Icons.medical_information_outlined,
    };
  }

  Color get iconColor {
    return switch (this) {
      LabTestCategory.bloodTests => const Color(0xFFE53935),
      LabTestCategory.urineTests => const Color(0xFF1E88E5),
      LabTestCategory.thyroidTests => const Color(0xFF8E24AA),
      LabTestCategory.diabetesTests => const Color(0xFFF4511E),
      LabTestCategory.liverFunctionTests => const Color(0xFFFB8C00),
      LabTestCategory.kidneyFunctionTests => const Color(0xFF6D4C41),
      LabTestCategory.lipidProfile => const Color(0xFFD81B60),
      LabTestCategory.vitaminTests => const Color(0xFFFDD835),
      LabTestCategory.hormoneTests => const Color(0xFF5E35B1),
      LabTestCategory.allergyTests => const Color(0xFF43A047),
      LabTestCategory.covid19Tests => const Color(0xFF546E7A),
      LabTestCategory.fullBodyCheckups => AppColors.primary,
      LabTestCategory.other => AppColors.info,
    };
  }
}

final _testIconOverrides = <String, IconData>{
  'cbc': Icons.bloodtype_outlined,
  'esr': Icons.opacity_outlined,
  'blood-group': Icons.bloodtype_rounded,
  'iron-studies': Icons.opacity_outlined,
  'urine-routine': Icons.water_drop_outlined,
  'urine-culture': Icons.science_outlined,
  'urine-microalbumin': Icons.water_drop_rounded,
  'thyroid-profile': Icons.monitor_heart_outlined,
  'tsh': Icons.monitor_heart_rounded,
  'anti-tpo': Icons.shield_outlined,
  'fbs': Icons.water_drop_outlined,
  'ppbs': Icons.water_drop_outlined,
  'hba1c': Icons.percent_outlined,
  'glucose-tolerance': Icons.timeline_outlined,
  'lft-basic': Icons.healing_outlined,
  'lft-advanced': Icons.healing_rounded,
  'kft-basic': Icons.filter_alt_outlined,
  'kft-advanced': Icons.filter_alt_rounded,
  'lipid-basic': Icons.favorite_outline_rounded,
  'lipid-advanced': Icons.favorite_rounded,
  'vitamin-d': Icons.wb_sunny_outlined,
  'vitamin-b12': Icons.bolt_outlined,
  'vitamin-panel': Icons.wb_sunny_rounded,
  'testosterone': Icons.male_outlined,
  'progesterone': Icons.female_outlined,
  'cortisol': Icons.nightlight_outlined,
  'ige-total': Icons.coronavirus_outlined,
  'food-allergy-panel': Icons.restaurant_outlined,
  'inhalant-allergy': Icons.air_outlined,
  'rt-pcr': Icons.biotech_outlined,
  'rapid-antigen': Icons.coronavirus_outlined,
  'covid-antibody': Icons.masks_outlined,
  'basic-checkup': Icons.health_and_safety_outlined,
  'comprehensive-checkup': Icons.medical_services_outlined,
  'senior-checkup': Icons.elderly_outlined,
  'womens-checkup': Icons.female_outlined,
  'crp': Icons.local_fire_department_outlined,
  'psa': Icons.male_outlined,
  'stool-routine': Icons.wc_outlined,
  'dengue-ns1': Icons.bug_report_outlined,
};

extension LabTestX on LabTest {
  IconData get icon => _testIconOverrides[id] ?? category.icon;

  Color get iconColor => category.iconColor;

  LabOrganLogo get organLogo => labOrganLogoForTestId(id);

  IconData get sampleTypeIcon {
    final sample = sampleType.toLowerCase();
    if (sample.contains('urine')) return Icons.water_drop_outlined;
    if (sample.contains('stool')) return Icons.wc_outlined;
    if (sample.contains('swab') || sample.contains('nasal')) {
      return Icons.air_outlined;
    }
    if (sample.contains('saliva')) return Icons.mood_outlined;
    return Icons.bloodtype_outlined;
  }
}

/// Category header / chip organ logo.
LabOrganLogo labOrganLogoForCategory(LabTestCategory category) =>
    labOrganLogoForId(category.id);

/// Thumbnail with organ-specific logo for test list cards.
class LabTestThumbnail extends StatelessWidget {
  const LabTestThumbnail({
    super.key,
    required this.test,
    this.width = 72,
    this.height = 56,
    this.logoSize = 28,
  });

  final LabTest test;
  final double width;
  final double height;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: height,
        color: test.iconColor.withValues(alpha: 0.12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/home_cards/lab_tests.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    test.iconColor.withValues(alpha: 0.35),
                    test.iconColor.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
            Center(
              child: LabOrganLogoIcon(
                logo: test.organLogo,
                size: logoSize,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular icon badge for a lab test tile or list row.
class LabTestIconAvatar extends StatelessWidget {
  const LabTestIconAvatar({
    super.key,
    required this.test,
    this.size = 44,
    this.iconSize = 22,
  });

  final LabTest test;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final color = test.iconColor;
    return Container(
      width: size,
      height: size,
      decoration: AppDecorations.iconTile(color.withValues(alpha: 0.14)),
      child: Center(
        child: LabOrganLogoIcon(
          logo: test.organLogo,
          size: iconSize,
          color: color,
        ),
      ),
    );
  }
}

/// Icon avatar resolved from a test id (falls back to generic lab icon).
class LabTestIdIconAvatar extends StatelessWidget {
  const LabTestIdIconAvatar({
    super.key,
    required this.testId,
    this.test,
    this.size = 40,
    this.iconSize = 20,
  });

  final String testId;
  final LabTest? test;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final resolved = test;
    if (resolved != null) {
      return LabTestIconAvatar(
        test: resolved,
        size: size,
        iconSize: iconSize,
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: AppDecorations.iconTile(AppColors.primaryLight),
      child: Icon(
        Icons.biotech_outlined,
        color: AppColors.primary,
        size: iconSize,
      ),
    );
  }
}
