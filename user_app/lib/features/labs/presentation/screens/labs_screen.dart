import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/care_filter_chip.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../data/lab_tests_catalog.dart';
import '../../data/models/lab_test_model.dart';
import '../widgets/lab_test_card.dart';

class LabsScreen extends StatefulWidget {
  const LabsScreen({super.key, this.initialCategory});

  final LabTestCategory? initialCategory;

  @override
  State<LabsScreen> createState() => _LabsScreenState();
}

class _LabsScreenState extends State<LabsScreen> {
  late final TextEditingController _searchController;
  Timer? _debounce;
  String _query = '';
  LabTestCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = _searchController.text.trim());
    });
  }

  void _selectCategory(LabTestCategory? category) {
    setState(() => _selectedCategory = category);
  }

  List<LabTest> get _filteredTests => LabTestsCatalog.filter(
        query: _query.isEmpty ? null : _query,
        category: _selectedCategory,
      );

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTests;
    final grouped = LabTestsCatalog.groupedByCategory(filtered);
    final categoriesInResults = grouped.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Diagnostic Labs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tests, panels, or categories...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.grey50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CareFilterChip(
                          label: 'All',
                          selected: _selectedCategory == null,
                          onTap: () => _selectCategory(null),
                        ),
                      ),
                      ...LabTestsCatalog.allCategories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CareFilterChip(
                            label: category.label,
                            selected: _selectedCategory == category,
                            onTap: () => _selectCategory(
                              _selectedCategory == category ? null : category,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(
                    query: _query,
                    category: _selectedCategory,
                    onClear: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                        _selectedCategory = null;
                      });
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      OfferPromoCard(
                        title: '${filtered.length} tests available',
                        subtitle:
                            'Home sample collection or onsite visit at partner labs',
                        badge: 'LABS',
                        icon: Icons.biotech_rounded,
                        includeMargin: false,
                        compact: true,
                      ),
                      const SizedBox(height: 16),
                      if (_selectedCategory != null)
                        _CategorySection(
                          category: _selectedCategory!,
                          tests: grouped[_selectedCategory!] ?? filtered,
                          onBook: _openBooking,
                        )
                      else
                        ...categoriesInResults.map((category) {
                          final tests = grouped[category]!;
                          return _CategorySection(
                            category: category,
                            tests: tests,
                            onBook: _openBooking,
                          );
                        }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _openBooking(LabTest test) {
    context.push(
      '${AppConstants.routeLabSearch}?testId=${Uri.encodeComponent(test.id)}'
      '&testName=${Uri.encodeComponent(test.name)}',
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.tests,
    required this.onBook,
  });

  final LabTestCategory category;
  final List<LabTest> tests;
  final void Function(LabTest test) onBook;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            children: [
              Icon(
                _categoryIcon(category),
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.label,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${tests.length}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ...tests.map(
          (test) => LabTestCard(
            test: test,
            onBookNow: () => onBook(test),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  IconData _categoryIcon(LabTestCategory category) {
    return switch (category) {
      LabTestCategory.bloodTests => Icons.bloodtype_outlined,
      LabTestCategory.urineTests => Icons.water_drop_outlined,
      LabTestCategory.thyroidTests => Icons.monitor_heart_outlined,
      LabTestCategory.diabetesTests => Icons.bloodtype_rounded,
      LabTestCategory.liverFunctionTests => Icons.healing_outlined,
      LabTestCategory.kidneyFunctionTests => Icons.filter_alt_outlined,
      LabTestCategory.lipidProfile => Icons.favorite_outline_rounded,
      LabTestCategory.vitaminTests => Icons.wb_sunny_outlined,
      LabTestCategory.hormoneTests => Icons.science_outlined,
      LabTestCategory.allergyTests => Icons.coronavirus_outlined,
      LabTestCategory.covid19Tests => Icons.masks_outlined,
      LabTestCategory.fullBodyCheckups => Icons.health_and_safety_outlined,
      LabTestCategory.other => Icons.medical_information_outlined,
    };
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.query,
    required this.category,
    required this.onClear,
  });

  final String query;
  final LabTestCategory? category;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.grey400.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'No tests found',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isNotEmpty
                  ? 'Try a different search term or clear filters.'
                  : category != null
                      ? 'No tests in ${category!.label} match your filters.'
                      : 'Adjust your filters to see available tests.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}
