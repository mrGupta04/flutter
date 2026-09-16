import 'package:flutter/material.dart';

import '../../core/constants/service_faqs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'service_faq_section.dart';

/// Home-screen FAQs + app highlights, styled like Practo's FAQ / Pro block.
class HomeHelpSection extends StatefulWidget {
  const HomeHelpSection({super.key});

  @override
  State<HomeHelpSection> createState() => _HomeHelpSectionState();
}

class _HomeHelpSectionState extends State<HomeHelpSection> {
  int? _openIndex;

  static const _highlights = <String>[
    'Book verified doctors for online, clinic, and home visits',
    'Find qualified nurses for home nursing care',
    'Compare lab tests, packages, and scan centres',
    'Request BLS, ALS, or ICU ambulances with live tracking',
    'Search blood banks by city and blood group',
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.grey50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              'FAQs',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          for (var i = 0; i < ServiceFaqs.home.length; i++)
            FaqAccordionCard(
              item: ServiceFaqs.home[i],
              expanded: _openIndex == i,
              onTap: () => setState(() {
                _openIndex = _openIndex == i ? null : i;
              }),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your health, one app',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A powerful app that lets you find care, book visits, and track reports without switching between services.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                for (final line in _highlights) ...[
                  _CheckLine(line),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_rounded,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
