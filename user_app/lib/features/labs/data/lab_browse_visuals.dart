import 'package:flutter/material.dart';

import '../data/lab_catalog_metadata.dart';

/// Per-category brand color + logo treatment for browse cards.
class LabBrowseVisual {
  const LabBrowseVisual({
    required this.accent,
    required this.soft,
    required this.deep,
    this.secondary,
  });

  final Color accent;
  final Color soft;
  final Color deep;
  final Color? secondary;

  static LabBrowseVisual forGroup(LabBrowseGroup group) =>
      forId(group.id) ?? _fallbackForType(group.type);

  static LabBrowseVisual? forId(String id) => _byId[id];

  static LabBrowseVisual _fallbackForType(LabBrowseGroupType type) {
    return switch (type) {
      LabBrowseGroupType.healthRisk => const LabBrowseVisual(
          accent: Color(0xFFE53935),
          soft: Color(0xFFFFEBEE),
          deep: Color(0xFFC62828),
        ),
      LabBrowseGroupType.healthCondition => const LabBrowseVisual(
          accent: Color(0xFF1E88E5),
          soft: Color(0xFFE3F2FD),
          deep: Color(0xFF1565C0),
        ),
      LabBrowseGroupType.bodyOrgan => const LabBrowseVisual(
          accent: Color(0xFF43A047),
          soft: Color(0xFFE8F5E9),
          deep: Color(0xFF2E7D32),
        ),
      LabBrowseGroupType.package => const LabBrowseVisual(
          accent: Color(0xFF208376),
          soft: Color(0xFFE8F6F3),
          deep: Color(0xFF165C54),
        ),
    };
  }
}

const _byId = <String, LabBrowseVisual>{
  // Risks
  'diabetes-risk': LabBrowseVisual(
    accent: Color(0xFFEF6C00),
    soft: Color(0xFFFFF3E0),
    deep: Color(0xFFE65100),
    secondary: Color(0xFFFFB74D),
  ),
  'heart-risk': LabBrowseVisual(
    accent: Color(0xFFE53935),
    soft: Color(0xFFFFEBEE),
    deep: Color(0xFFC62828),
    secondary: Color(0xFFEF9A9A),
  ),
  'kidney-risk': LabBrowseVisual(
    accent: Color(0xFF8D6E63),
    soft: Color(0xFFEFEBE9),
    deep: Color(0xFF5D4037),
    secondary: Color(0xFFBCAAA4),
  ),
  'liver-risk': LabBrowseVisual(
    accent: Color(0xFFFB8C00),
    soft: Color(0xFFFFF8E1),
    deep: Color(0xFFEF6C00),
    secondary: Color(0xFFFFD54F),
  ),
  'thyroid-risk': LabBrowseVisual(
    accent: Color(0xFF8E24AA),
    soft: Color(0xFFF3E5F5),
    deep: Color(0xFF6A1B9A),
    secondary: Color(0xFFCE93D8),
  ),
  'vitamin-risk': LabBrowseVisual(
    accent: Color(0xFFF9A825),
    soft: Color(0xFFFFFDE7),
    deep: Color(0xFFF57F17),
    secondary: Color(0xFFFFEE58),
  ),
  'cancer-risk': LabBrowseVisual(
    accent: Color(0xFF5E35B1),
    soft: Color(0xFFEDE7F6),
    deep: Color(0xFF4527A0),
    secondary: Color(0xFFB39DDB),
  ),
  'obesity-risk': LabBrowseVisual(
    accent: Color(0xFF00897B),
    soft: Color(0xFFE0F2F1),
    deep: Color(0xFF00695C),
    secondary: Color(0xFF80CBC4),
  ),
  'hypertension-risk': LabBrowseVisual(
    accent: Color(0xFFD32F2F),
    soft: Color(0xFFFFEBEE),
    deep: Color(0xFFB71C1C),
    secondary: Color(0xFFE57373),
  ),
  'cholesterol-risk': LabBrowseVisual(
    accent: Color(0xFFEC407A),
    soft: Color(0xFFFCE4EC),
    deep: Color(0xFFC2185B),
    secondary: Color(0xFFF48FB1),
  ),
  'bone-risk': LabBrowseVisual(
    accent: Color(0xFF5C6BC0),
    soft: Color(0xFFE8EAF6),
    deep: Color(0xFF3949AB),
    secondary: Color(0xFF9FA8DA),
  ),
  'hormonal-risk': LabBrowseVisual(
    accent: Color(0xFF7B1FA2),
    soft: Color(0xFFF3E5F5),
    deep: Color(0xFF4A148C),
    secondary: Color(0xFFBA68C8),
  ),

  // Conditions
  'diabetes': LabBrowseVisual(
    accent: Color(0xFFEF6C00),
    soft: Color(0xFFFFF3E0),
    deep: Color(0xFFE65100),
    secondary: Color(0xFFFFB74D),
  ),
  'fever': LabBrowseVisual(
    accent: Color(0xFFE53935),
    soft: Color(0xFFFFEBEE),
    deep: Color(0xFFC62828),
    secondary: Color(0xFFFF7043),
  ),
  'dengue': LabBrowseVisual(
    accent: Color(0xFF43A047),
    soft: Color(0xFFE8F5E9),
    deep: Color(0xFF2E7D32),
    secondary: Color(0xFF81C784),
  ),
  'malaria': LabBrowseVisual(
    accent: Color(0xFF00897B),
    soft: Color(0xFFE0F2F1),
    deep: Color(0xFF00695C),
    secondary: Color(0xFF4DB6AC),
  ),
  'covid': LabBrowseVisual(
    accent: Color(0xFF546E7A),
    soft: Color(0xFFECEFF1),
    deep: Color(0xFF37474F),
    secondary: Color(0xFF90A4AE),
  ),
  'pregnancy': LabBrowseVisual(
    accent: Color(0xFFEC407A),
    soft: Color(0xFFFCE4EC),
    deep: Color(0xFFC2185B),
    secondary: Color(0xFFF48FB1),
  ),
  'pcos': LabBrowseVisual(
    accent: Color(0xFFAB47BC),
    soft: Color(0xFFF3E5F5),
    deep: Color(0xFF8E24AA),
    secondary: Color(0xFFCE93D8),
  ),
  'thyroid': LabBrowseVisual(
    accent: Color(0xFF8E24AA),
    soft: Color(0xFFF3E5F5),
    deep: Color(0xFF6A1B9A),
    secondary: Color(0xFFCE93D8),
  ),
  'cholesterol': LabBrowseVisual(
    accent: Color(0xFFD81B60),
    soft: Color(0xFFFCE4EC),
    deep: Color(0xFFAD1457),
    secondary: Color(0xFFF06292),
  ),
  'anemia': LabBrowseVisual(
    accent: Color(0xFFE53935),
    soft: Color(0xFFFFEBEE),
    deep: Color(0xFFB71C1C),
    secondary: Color(0xFFEF9A9A),
  ),
  'vitamin-d': LabBrowseVisual(
    accent: Color(0xFFF9A825),
    soft: Color(0xFFFFFDE7),
    deep: Color(0xFFF57F17),
    secondary: Color(0xFFFFEE58),
  ),
  'vitamin-b12': LabBrowseVisual(
    accent: Color(0xFFFFA000),
    soft: Color(0xFFFFF8E1),
    deep: Color(0xFFFF6F00),
    secondary: Color(0xFFFFD54F),
  ),
  'arthritis': LabBrowseVisual(
    accent: Color(0xFF6D4C41),
    soft: Color(0xFFEFEBE9),
    deep: Color(0xFF4E342E),
    secondary: Color(0xFFA1887F),
  ),
  'fatty-liver': LabBrowseVisual(
    accent: Color(0xFFFB8C00),
    soft: Color(0xFFFFF8E1),
    deep: Color(0xFFEF6C00),
    secondary: Color(0xFFFFD54F),
  ),
  'kidney-disease': LabBrowseVisual(
    accent: Color(0xFF8D6E63),
    soft: Color(0xFFEFEBE9),
    deep: Color(0xFF5D4037),
    secondary: Color(0xFFBCAAA4),
  ),
  'asthma': LabBrowseVisual(
    accent: Color(0xFF29B6F6),
    soft: Color(0xFFE1F5FE),
    deep: Color(0xFF0288D1),
    secondary: Color(0xFF81D4FA),
  ),
  'allergy': LabBrowseVisual(
    accent: Color(0xFF66BB6A),
    soft: Color(0xFFE8F5E9),
    deep: Color(0xFF43A047),
    secondary: Color(0xFFA5D6A7),
  ),
  'hypertension': LabBrowseVisual(
    accent: Color(0xFFD32F2F),
    soft: Color(0xFFFFEBEE),
    deep: Color(0xFFB71C1C),
    secondary: Color(0xFFE57373),
  ),

  // Organs
  'heart': LabBrowseVisual(
    accent: Color(0xFFE53935),
    soft: Color(0xFFFFEBEE),
    deep: Color(0xFFC62828),
    secondary: Color(0xFFEF9A9A),
  ),
  'liver': LabBrowseVisual(
    accent: Color(0xFFFB8C00),
    soft: Color(0xFFFFF8E1),
    deep: Color(0xFFEF6C00),
    secondary: Color(0xFFFFD54F),
  ),
  'kidney': LabBrowseVisual(
    accent: Color(0xFF8D6E63),
    soft: Color(0xFFEFEBE9),
    deep: Color(0xFF5D4037),
    secondary: Color(0xFFBCAAA4),
  ),
  'brain': LabBrowseVisual(
    accent: Color(0xFF5C6BC0),
    soft: Color(0xFFE8EAF6),
    deep: Color(0xFF3949AB),
    secondary: Color(0xFF9FA8DA),
  ),
  'lungs': LabBrowseVisual(
    accent: Color(0xFF29B6F6),
    soft: Color(0xFFE1F5FE),
    deep: Color(0xFF0288D1),
    secondary: Color(0xFF81D4FA),
  ),
  'stomach': LabBrowseVisual(
    accent: Color(0xFFFF7043),
    soft: Color(0xFFFBE9E7),
    deep: Color(0xFFE64A19),
    secondary: Color(0xFFFFAB91),
  ),
  'bones': LabBrowseVisual(
    accent: Color(0xFF78909C),
    soft: Color(0xFFECEFF1),
    deep: Color(0xFF546E7A),
    secondary: Color(0xFFB0BEC5),
  ),
  'blood': LabBrowseVisual(
    accent: Color(0xFFE53935),
    soft: Color(0xFFFFEBEE),
    deep: Color(0xFFB71C1C),
    secondary: Color(0xFFEF9A9A),
  ),
  'hormones': LabBrowseVisual(
    accent: Color(0xFF7B1FA2),
    soft: Color(0xFFF3E5F5),
    deep: Color(0xFF4A148C),
    secondary: Color(0xFFBA68C8),
  ),
  'thyroid-organ': LabBrowseVisual(
    accent: Color(0xFF8E24AA),
    soft: Color(0xFFF3E5F5),
    deep: Color(0xFF6A1B9A),
    secondary: Color(0xFFCE93D8),
  ),
  'eyes': LabBrowseVisual(
    accent: Color(0xFF42A5F5),
    soft: Color(0xFFE3F2FD),
    deep: Color(0xFF1E88E5),
    secondary: Color(0xFF90CAF9),
  ),
  'skin': LabBrowseVisual(
    accent: Color(0xFFFF8A65),
    soft: Color(0xFFFBE9E7),
    deep: Color(0xFFF4511E),
    secondary: Color(0xFFFFAB91),
  ),
};
