import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/care_filter_chip.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../data/models/scan_procedure_model.dart';
import '../../data/scans_catalog.dart';
import '../widgets/scan_procedure_card.dart';

class ScansScreen extends StatefulWidget {
  const ScansScreen({super.key, this.initialCategory});

  final ScanCategory? initialCategory;

  @override
  State<ScansScreen> createState() => _ScansScreenState();
}

class _ScansScreenState extends State<ScansScreen> {
  late final TextEditingController _searchController;
  Timer? _debounce;
  String _query = '';
  ScanCategory? _selectedCategory;

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

  void _selectCategory(ScanCategory? category) {
    setState(() => _selectedCategory = category);
  }

  List<ScanProcedure> get _filteredScans => ScansCatalog.filter(
        query: _query.isEmpty ? null : _query,
        category: _selectedCategory,
      );

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredScans;
    final grouped = ScansCatalog.groupedByCategory(filtered);
    final categoriesInResults = grouped.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Imaging & Scans'),
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
                    hintText: 'Search MRI, X-Ray, CT, ultrasound...',
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
                      ...ScansCatalog.allCategories.map((category) {
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
                        title: '${filtered.length} scans available',
                        subtitle:
                            'MRI, X-Ray, CT & more at verified imaging centers',
                        badge: 'SCANS',
                        icon: Icons.radar_rounded,
                        includeMargin: false,
                        compact: true,
                      ),
                      const SizedBox(height: 16),
                      if (_selectedCategory != null)
                        _CategorySection(
                          category: _selectedCategory!,
                          procedures: grouped[_selectedCategory!] ?? filtered,
                          onBook: _openBooking,
                        )
                      else
                        ...categoriesInResults.map((category) {
                          final procedures = grouped[category]!;
                          return _CategorySection(
                            category: category,
                            procedures: procedures,
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

  void _openBooking(ScanProcedure procedure) {
    context.push(
      '${AppConstants.routeScanSearch}?scanId=${Uri.encodeComponent(procedure.id)}'
      '&scanName=${Uri.encodeComponent(procedure.name)}'
      '&category=${Uri.encodeComponent(procedure.category.id)}',
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.procedures,
    required this.onBook,
  });

  final ScanCategory category;
  final List<ScanProcedure> procedures;
  final void Function(ScanProcedure procedure) onBook;

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
                '${procedures.length}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ...procedures.map(
          (procedure) => ScanProcedureCard(
            procedure: procedure,
            onBookNow: () => onBook(procedure),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  IconData _categoryIcon(ScanCategory category) {
    return switch (category) {
      ScanCategory.mri => Icons.view_in_ar_outlined,
      ScanCategory.xray => Icons.radio_button_checked_outlined,
      ScanCategory.ct => Icons.layers_outlined,
      ScanCategory.ultrasound => Icons.waves_outlined,
      ScanCategory.pet => Icons.biotech_outlined,
      ScanCategory.mammography => Icons.favorite_border_rounded,
      ScanCategory.ecg => Icons.monitor_heart_outlined,
      ScanCategory.eeg => Icons.psychology_outlined,
      ScanCategory.echo => Icons.favorite_outline_rounded,
      ScanCategory.doppler => Icons.water_outlined,
      ScanCategory.dexa => Icons.accessibility_new_outlined,
      ScanCategory.fluoroscopy => Icons.video_camera_back_outlined,
      ScanCategory.endoscopy => Icons.medical_services_outlined,
      ScanCategory.colonoscopy => Icons.healing_outlined,
      ScanCategory.bronchoscopy => Icons.air_outlined,
      ScanCategory.tmt => Icons.directions_run_outlined,
      ScanCategory.ncv => Icons.cable_outlined,
      ScanCategory.emg => Icons.electric_bolt_outlined,
      ScanCategory.other => Icons.medical_information_outlined,
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
  final ScanCategory? category;
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
              'No scans found',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isNotEmpty
                  ? 'Try a different search term or clear filters.'
                  : category != null
                      ? 'No scans in ${category!.label} match your filters.'
                      : 'Adjust your filters to see available scans.',
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
