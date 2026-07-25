import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'lab_test_illustrations.dart';
import 'lab_test_organ_assets.dart';
import 'models/lab_test_model.dart';
import '../presentation/widgets/lab_organ_logos.dart';
import '../presentation/widgets/lab_test_logo.dart';

/// Category-level colors for kidney, liver, vitamins, allergy, etc.
extension LabTestCategoryX on LabTestCategory {
  Color get iconColor {
    return switch (this) {
      LabTestCategory.bloodTests => const Color(0xFFE53935),
      LabTestCategory.urineTests => const Color(0xFF1E88E5),
      LabTestCategory.thyroidTests => const Color(0xFF8E24AA),
      LabTestCategory.diabetesTests => const Color(0xFFF4511E),
      LabTestCategory.liverFunctionTests => const Color(0xFFFB8C00),
      LabTestCategory.kidneyFunctionTests => const Color(0xFF6D4C41),
      LabTestCategory.lipidProfile => const Color(0xFFD81B60),
      LabTestCategory.vitaminTests => const Color(0xFFF59E0B),
      LabTestCategory.hormoneTests => const Color(0xFF5E35B1),
      LabTestCategory.allergyTests => const Color(0xFF43A047),
      LabTestCategory.covid19Tests => const Color(0xFF546E7A),
      LabTestCategory.fullBodyCheckups => AppColors.primary,
      LabTestCategory.other => AppColors.info,
    };
  }

  String get illustrationPath => labTestIllustrationForId(id);
}

extension LabTestX on LabTest {
  Color get iconColor => category.iconColor;

  LabOrganLogo get organLogo => labOrganLogoForTestId(id);

  String get illustrationPath => labTestIllustrationForTestId(id);

  String get organAssetPath => labTestOrganAssetFor(this);

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

/// Category header organ illustration.
String labIllustrationForCategory(LabTestCategory category) =>
    category.illustrationPath;

/// Thumbnail with organ-specific SVG for test list cards.
class LabTestThumbnail extends StatelessWidget {
  const LabTestThumbnail({
    super.key,
    required this.test,
    this.width = 72,
    this.height = 56,
    this.logoSize = 30,
  });

  final LabTest test;
  final double width;
  final double height;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return LabTestProfileThumbnail(
      illustrationPath: test.illustrationPath,
      organAssetPath: test.organAssetPath,
      color: test.iconColor,
      fallbackLogo: test.organLogo,
      width: width,
      height: height,
      logoSize: logoSize,
    );
  }
}

/// Circular illustration badge for a lab test tile or list row.
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
    return LabTestProfileAvatar(
      illustrationPath: test.illustrationPath,
      organAssetPath: test.organAssetPath,
      color: test.iconColor,
      fallbackLogo: test.organLogo,
      size: size,
      logoSize: iconSize,
    );
  }
}

/// Illustration avatar resolved from a test id (falls back to generic lab icon).
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

    final color = AppColors.primary;
    return LabTestProfileAvatar(
      illustrationPath: labTestIllustrationForTestId(testId),
      organAssetPath: labTestOrganAssetForTestId(
        testId,
        resolved?.category ?? LabTestCategory.other,
      ),
      color: color,
      fallbackLogo: labOrganLogoForTestId(testId),
      size: size,
      logoSize: iconSize,
    );
  }
}
