import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart' as custom;
import '../../../../data/models/consultation_type.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/consultation_type_cards.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/doctor_search_provider.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';
import '../widgets/doctor_search_result_tile.dart';

class DoctorSearchScreen extends ConsumerStatefulWidget {
  const DoctorSearchScreen({
    super.key,
    this.initialQuery,
    this.initialCity,
    this.initialSpecialization,
  });

  final String? initialQuery;
  final String? initialCity;
  final String? initialSpecialization;

  @override
  ConsumerState<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends ConsumerState<DoctorSearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String? _query;
  String? _city;
  String? _specialization;
  ConsultationType _consultationType = ConsultationType.onlineConsult;

  static const _popularCities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
    'Chennai',
    'Pune',
    'Kolkata',
  ];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _city = widget.initialCity;
    _specialization = widget.initialSpecialization;
    _controller = TextEditingController(
      text: widget.initialQuery ??
          widget.initialCity ??
          widget.initialSpecialization ??
          '',
    );
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _query = _controller.text.trim().isEmpty
            ? null
            : _controller.text.trim();
        _city = null;
        _specialization = null;
      });
    });
  }

  void _applyCityFilter(String city) {
    setState(() {
      _city = city;
      _specialization = null;
      _query = null;
      _controller.text = city;
    });
  }

  void _applySpecializationFilter(String specialization) {
    setState(() {
      _specialization = specialization;
      _city = null;
      _query = null;
      _controller.text = specialization;
    });
  }

  void _clearFilters() {
    setState(() {
      _query = null;
      _city = null;
      _specialization = null;
      _controller.clear();
    });
  }

  DoctorSearchParams get _params => DoctorSearchParams(
        query: _query,
        city: _city,
        specialization: _specialization,
        consultationType: _consultationType,
      );

  @override
  Widget build(BuildContext context) {
    final asyncResults = ref.watch(doctorSearchProvider(_params));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find a doctor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _controller,
              autofocus: widget.initialQuery == null &&
                  widget.initialCity == null &&
                  widget.initialSpecialization == null,
              decoration: InputDecoration(
                hintText: 'Search by name, city, specialty, clinic...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _params.hasTextFilters
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: _clearFilters,
                      )
                    : null,
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                setState(() {
                  _query = value.trim();
                  _city = null;
                  _specialization = null;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          ConsultationTypeCards(
            selected: _consultationType,
            onSelected: (type) => setState(() => _consultationType = type),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Showing: ${_consultationType.label}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ..._popularCities.map(
                  (city) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(city),
                      backgroundColor: AppColors.white,
                      side: BorderSide(
                        color: _city == city
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      onPressed: () => _applyCityFilter(city),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: categorySpecializationMap.entries.map((entry) {
                final selected = _specialization == entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(entry.key),
                    backgroundColor: AppColors.white,
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    onPressed: () => _applySpecializationFilter(entry.value),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildResults(asyncResults),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(AsyncValue<List<DoctorModel>> asyncResults) {
    return asyncResults.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: ShimmerLoadingList(),
      ),
      error: (error, _) => custom.AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(doctorSearchProvider(_params)),
      ),
      data: (doctors) {
        if (doctors.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_search_rounded,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No doctors found',
                    style: AppTextStyles.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try another consultation type, city, specialty, or keyword',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: doctors.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: kDoctorCardSpacing),
          itemBuilder: (context, index) {
            return DoctorSearchResultTile(
              doctor: doctors[index],
              showBottomDivider: false,
            );
          },
        );
      },
    );
  }
}
