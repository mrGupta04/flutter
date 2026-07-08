import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart' as custom;
import '../../../../data/models/blood_bank_model.dart';
import '../../../../shared/widgets/care_provider_listing_cards.dart';
import '../../../../shared/widgets/horizontal_filter_chips.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../../doctor_registration/provider/care_filter_constants.dart';
import '../../data/blood_bank_catalog.dart';
import '../../provider/blood_bank_search_provider.dart';

class BloodBankSearchScreen extends ConsumerStatefulWidget {
  const BloodBankSearchScreen({
    super.key,
    this.initialQuery,
    this.initialCity,
    this.initialBloodGroup,
    this.initialComponentType,
  });

  final String? initialQuery;
  final String? initialCity;
  final String? initialBloodGroup;
  final String? initialComponentType;

  @override
  ConsumerState<BloodBankSearchScreen> createState() =>
      _BloodBankSearchScreenState();
}

class _BloodBankSearchScreenState extends ConsumerState<BloodBankSearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String? _query;
  String? _city;
  String? _bloodGroup;
  String? _componentType;
  BloodBankCareFilter _careFilter = BloodBankCareFilter.all;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _city = widget.initialCity;
    _bloodGroup = widget.initialBloodGroup;
    _componentType = widget.initialComponentType;
    _controller = TextEditingController(
      text: widget.initialQuery ??
          widget.initialCity ??
          widget.initialBloodGroup ??
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
        _bloodGroup = null;
      });
    });
  }

  BloodBankSearchParams get _params => BloodBankSearchParams(
        query: _query,
        city: _city,
        bloodGroup: _bloodGroup,
        componentType: _componentType,
        careFilter: _careFilter,
      );

  @override
  Widget build(BuildContext context) {
    final asyncResults = ref.watch(bloodBankSearchProvider(_params));

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const UserBottomNavBar(currentTab: UserNavTab.care),
      appBar: AppBar(
        title: const Text('Find blood bank'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency_rounded, color: Color(0xFFB71C1C)),
            onPressed: () => context.push(AppConstants.routeEmergencyBloodRequest),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildFilters()),
          ..._buildResultSlivers(asyncResults),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Name, city, area, pincode...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: BloodBankCareFilter.values
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.label),
                      selected: _careFilter == f,
                      onSelected: (_) => setState(() => _careFilter = f),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        HorizontalFilterChips(
          labels: popularCareCities,
          selected: _city,
          onSelected: (city) => setState(() {
            _city = city;
            _controller.text = city;
          }),
        ),
        const SizedBox(height: 8),
        HorizontalFilterChips(
          labels: bloodGroupFilters,
          selected: _bloodGroup,
          onSelected: (group) => setState(() => _bloodGroup = group),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  List<Widget> _buildResultSlivers(
    AsyncValue<List<BloodBankModel>> asyncResults,
  ) {
    return asyncResults.when(
      loading: () => const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: ShimmerLoadingList(),
          ),
        ),
      ],
      error: (error, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: custom.AppErrorWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(bloodBankSearchProvider(_params)),
          ),
        ),
      ],
      data: (items) {
        if (items.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No blood banks found.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ];
        }

        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => BloodBankListingCard(
                bloodBank: items[index],
                onTap: () => context.push(
                  '${AppConstants.routeBloodBankDetail}/${items[index].id}',
                ),
                onOrder: () => context.push(
                  '${AppConstants.routeBloodBankDetail}/${items[index].id}',
                ),
              ),
            ),
          ),
        ];
      },
    );
  }
}
