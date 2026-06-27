import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart' as custom;
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/care_provider_listing_cards.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';
import '../../../../shared/widgets/horizontal_filter_chips.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../provider/care_filter_constants.dart';
import '../../provider/nurse_search_provider.dart';
import 'nurse_profile_screen.dart';

class NurseSearchScreen extends ConsumerStatefulWidget {
  const NurseSearchScreen({
    super.key,
    this.initialQuery,
    this.initialCity,
    this.initialSpecialization,
  });

  final String? initialQuery;
  final String? initialCity;
  final String? initialSpecialization;

  @override
  ConsumerState<NurseSearchScreen> createState() => _NurseSearchScreenState();
}

class _NurseSearchScreenState extends ConsumerState<NurseSearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String? _query;
  String? _city;
  String? _specialization;

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
        _query = _controller.text.trim().isEmpty ? null : _controller.text.trim();
        _city = null;
        _specialization = null;
      });
    });
  }

  NurseSearchParams get _params => NurseSearchParams(
        query: _query,
        city: _city,
        specialization: _specialization,
      );

  @override
  Widget build(BuildContext context) {
    final asyncResults = ref.watch(nurseSearchProvider(_params));

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const UserBottomNavBar(currentTab: UserNavTab.search),
      appBar: AppBar(
        title: const Text('Find a nurse'),
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
              decoration: InputDecoration(
                hintText: 'Search by name, city, qualification...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _params.hasTextFilters
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _query = null;
                            _city = null;
                            _specialization = null;
                            _controller.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              onSubmitted: (value) => setState(() {
                _query = value.trim().isEmpty ? null : value.trim();
                _city = null;
                _specialization = null;
              }),
            ),
          ),
          const SizedBox(height: 12),
          HorizontalFilterChips(
            labels: popularCareCities,
            selected: _city,
            onSelected: (city) => setState(() {
              _city = city;
              _specialization = null;
              _query = null;
              _controller.text = city;
            }),
          ),
          const SizedBox(height: 8),
          HorizontalFilterChips(
            labels: nurseSpecializationFilters,
            selected: _specialization,
            onSelected: (spec) => setState(() {
              _specialization = spec;
              _city = null;
              _query = null;
              _controller.text = spec;
            }),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildResults(asyncResults)),
        ],
      ),
    );
  }

  Widget _buildResults(AsyncValue<List<NurseModel>> asyncResults) {
    return asyncResults.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: ShimmerLoadingList(),
      ),
      error: (error, _) => custom.AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(nurseSearchProvider(_params)),
      ),
      data: (nurses) {
        if (nurses.isEmpty) {
          return Center(
            child: Text(
              'No nurses found. Try another filter or city.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: nurses.length,
          separatorBuilder: (_, __) => const SizedBox(height: kDoctorCardSpacing),
          itemBuilder: (_, index) => NurseListingCard(
            nurse: nurses[index],
            onTap: () => openNurseProfile(context, nurses[index]),
          ),
        );
      },
    );
  }
}
