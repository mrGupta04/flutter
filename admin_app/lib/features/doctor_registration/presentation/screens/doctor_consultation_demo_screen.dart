import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/consultation_type.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/consultation_filter_bar.dart';
import '../../../../shared/widgets/consultation_type_cards.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/verified_doctors_provider.dart';

/// Side-by-side demo of three consultation listing layouts for client review.
class DoctorConsultationDemoScreen extends ConsumerStatefulWidget {
  const DoctorConsultationDemoScreen({super.key});

  @override
  ConsumerState<DoctorConsultationDemoScreen> createState() =>
      _DoctorConsultationDemoScreenState();
}

class _DoctorConsultationDemoScreenState
    extends ConsumerState<DoctorConsultationDemoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ConsultationType? _cardSelection;
  ConsultationType? _filterSelection;

  static const _modeLabels = [
    'Option 1 — Cards',
    'Option 2 — Fade buttons',
    'Option 3 — Filter',
  ];

  static const _modeDescriptions = [
    'Tap Online Book, Visit, or Book Home to show only doctors available for that option.',
    'All doctors listed; buttons that are not offered appear faded on each card.',
    'Use filter chips above the list to narrow doctors by consultation type.',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cardSelection = ConsultationType.onlineConsult;
    _filterSelection = null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consultation layouts'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
          tabs: _modeLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CardsLayout(
            selected: _cardSelection,
            description: _modeDescriptions[0],
            onSelected: (type) => setState(() => _cardSelection = type),
          ),
          _FadeButtonsLayout(description: _modeDescriptions[1]),
          _FilterLayout(
            selected: _filterSelection,
            description: _modeDescriptions[2],
            onSelected: (type) => setState(() => _filterSelection = type),
          ),
        ],
      ),
    );
  }
}

class _DemoDescription extends StatelessWidget {
  const _DemoDescription({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _CardsLayout extends ConsumerWidget {
  const _CardsLayout({
    required this.selected,
    required this.description,
    required this.onSelected,
  });

  final ConsultationType? selected;
  final String description;
  final ValueChanged<ConsultationType> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDoctors = ref.watch(
      verifiedDoctorsByConsultationProvider(selected),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DemoDescription(text: description),
        const SizedBox(height: 12),
        ConsultationTypeCards(
          selected: selected,
          onSelected: onSelected,
        ),
        const SizedBox(height: 8),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Showing doctors for: ${selected!.label}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: _DoctorListBody(asyncDoctors: asyncDoctors),
        ),
      ],
    );
  }
}

class _FadeButtonsLayout extends ConsumerWidget {
  const _FadeButtonsLayout({required this.description});

  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDoctors = ref.watch(verifiedDoctorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DemoDescription(text: description),
        const SizedBox(height: 12),
        Expanded(
          child: _DoctorListBody(
            asyncDoctors: asyncDoctors,
            fadeUnavailableButtons: true,
          ),
        ),
      ],
    );
  }
}

class _FilterLayout extends ConsumerWidget {
  const _FilterLayout({
    required this.selected,
    required this.description,
    required this.onSelected,
  });

  final ConsultationType? selected;
  final String description;
  final ValueChanged<ConsultationType?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDoctors = ref.watch(
      verifiedDoctorsByConsultationProvider(selected),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DemoDescription(text: description),
        const SizedBox(height: 12),
        ConsultationFilterBar(
          selected: selected,
          onSelected: onSelected,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _DoctorListBody(asyncDoctors: asyncDoctors),
        ),
      ],
    );
  }
}

class _DoctorListBody extends StatelessWidget {
  const _DoctorListBody({
    required this.asyncDoctors,
    this.fadeUnavailableButtons = false,
  });

  final AsyncValue<List<DoctorModel>> asyncDoctors;
  final bool fadeUnavailableButtons;

  @override
  Widget build(BuildContext context) {
    return asyncDoctors.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ShimmerLoadingList(),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load doctors.\n$error',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
      data: (doctors) {
        if (doctors.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No doctors available for this option yet.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const MarketplaceSectionTitle(title: 'Verified doctors'),
            const SizedBox(height: 8),
            for (var i = 0; i < doctors.length; i++) ...[
              if (i > 0) const SizedBox(height: kDoctorCardSpacing),
              DoctorListingCard(
                doctor: doctors[i],
                showBottomDivider: false,
                fadeUnavailableConsultationButtons: fadeUnavailableButtons,
              ),
            ],
          ],
        );
      },
    );
  }
}
