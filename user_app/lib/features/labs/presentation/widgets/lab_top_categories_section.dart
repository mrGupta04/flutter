import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/lab_browse_visuals.dart';
import '../../data/lab_catalog_metadata.dart';
import '../../data/lab_tests_catalog.dart';
import '../../data/models/lab_test_model.dart';
import '../widgets/lab_organ_logos.dart';
import '../widgets/lab_test_card.dart';
import '../../../../shared/widgets/top_categories_grid.dart';

/// Top Categories grid for the Lab Tests explore screen.
class LabTopCategoriesSection extends StatelessWidget {
  const LabTopCategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final featured = LabCatalogMetadata.featuredTopCategories;
    if (featured.isEmpty) return const SizedBox.shrink();

    return TopCategoriesGrid(
      items: featured.map((entry) {
        final title = entry.$1;
        final group = entry.$2;
        final visual = LabBrowseVisual.forGroup(group);
        return TopCategoryItem(
          title: title,
          softColor: visual.soft,
          accentColor: visual.accent,
          illustration: LabOrganLogoIcon(
            groupId: group.id,
            size: 52,
            color: visual.accent,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LabCategoryTestsScreen(
                  title: title,
                  group: group,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

/// Lists tests for a Top Category and books via lab search.
class LabCategoryTestsScreen extends StatelessWidget {
  const LabCategoryTestsScreen({
    super.key,
    required this.title,
    required this.group,
  });

  final String title;
  final LabBrowseGroup group;

  @override
  Widget build(BuildContext context) {
    final tests = LabTestsCatalog.byIds(group.testIds);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: tests.isEmpty
          ? Center(
              child: Text(
                'No tests in this category yet',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: tests.length,
              itemBuilder: (context, index) {
                final test = tests[index];
                return LabTestCard(
                  test: test,
                  onBookNow: () => _openBooking(context, test),
                );
              },
            ),
    );
  }

  void _openBooking(BuildContext context, LabTest test) {
    context.push(
      '${AppConstants.routeLabSearch}?testId=${Uri.encodeComponent(test.id)}'
      '&testName=${Uri.encodeComponent(test.name)}',
    );
  }
}
