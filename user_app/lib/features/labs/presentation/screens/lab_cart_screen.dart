import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart' as custom;
import '../../data/lab_test_icons.dart';
import '../../data/lab_tests_catalog.dart';
import '../../data/models/lab_test_model.dart';
import '../../provider/lab_cart_provider.dart';

class LabCartScreen extends ConsumerStatefulWidget {
  const LabCartScreen({super.key});

  @override
  ConsumerState<LabCartScreen> createState() => _LabCartScreenState();
}

class _LabCartScreenState extends ConsumerState<LabCartScreen> {
  SampleCollectionOption? _collectionOption;
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  static const _timeSlots = [
    '07:00 AM - 09:00 AM',
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
  ];

  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedSlot = _timeSlots.first;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _confirmBooking(LabCartState cart) async {
    if (_collectionOption == null ||
        _selectedDate == null ||
        _selectedSlot == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    ref.read(labCartProvider.notifier).clear();

    final dateStr = DateFormat('EEE, dd MMM yyyy').format(_selectedDate!);
    context.go(
      '${AppConstants.routeLabBookingConfirmation}?'
      'lab=${Uri.encodeComponent(cart.labName ?? 'Lab')}'
      '&date=${Uri.encodeComponent(dateStr)}'
      '&slot=${Uri.encodeComponent(_selectedSlot!)}'
      '&total=${cart.subtotal}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(labCartProvider);

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 56, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              const Text('Your cart is empty'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(AppConstants.routeLabs),
                child: const Text('Explore labs'),
              ),
            ],
          ),
        ),
      );
    }

    final homeAvailable =
        cart.items.any((i) => i.homeCollectionAvailable);
    final onsiteAvailable =
        cart.items.any((i) => i.onsiteCollectionAvailable);

    if (_collectionOption == null) {
      if (homeAvailable) {
        _collectionOption = SampleCollectionOption.homeVisit;
      } else if (onsiteAvailable) {
        _collectionOption = SampleCollectionOption.onsite;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Lab Tests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: Material(
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: custom.CustomButton(
              label: 'Confirm & Book • ₹${cart.subtotal}',
              icon: Icons.check_rounded,
              isLoading: _isSubmitting,
              isEnabled: _collectionOption != null &&
                  _selectedDate != null &&
                  _selectedSlot != null,
              onPressed: () => _confirmBooking(cart),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            cart.labName ?? 'Selected lab',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${cart.itemCount} test${cart.itemCount == 1 ? '' : 's'} selected',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...cart.items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: LabTestIdIconAvatar(
                  testId: item.testId,
                  test: LabTestsCatalog.byId(item.testId),
                ),
                title: Text(item.testName),
                subtitle: Text(item.reportDeliveryTime ?? '24–48 hours'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${item.priceInr}',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => ref
                          .read(labCartProvider.notifier)
                          .removeItem(item.testId),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 24),
          Text(
            'Sample collection',
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (homeAvailable)
            _CollectionTile(
              option: SampleCollectionOption.homeVisit,
              selected: _collectionOption == SampleCollectionOption.homeVisit,
              onTap: () => setState(
                () => _collectionOption = SampleCollectionOption.homeVisit,
              ),
            ),
          if (onsiteAvailable)
            _CollectionTile(
              option: SampleCollectionOption.onsite,
              selected: _collectionOption == SampleCollectionOption.onsite,
              onTap: () => setState(
                () => _collectionOption = SampleCollectionOption.onsite,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Preferred date',
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: AppDecorations.borderRadiusMd,
              side: const BorderSide(color: AppColors.border),
            ),
            leading: const Icon(Icons.event_rounded, color: AppColors.primary),
            title: Text(
              _selectedDate != null
                  ? DateFormat('EEE, dd MMM yyyy').format(_selectedDate!)
                  : 'Select date',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          Text(
            'Time slot',
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeSlots.map((slot) {
              final selected = _selectedSlot == slot;
              return FilterChip(
                label: Text(slot),
                selected: selected,
                onSelected: (_) => setState(() => _selectedSlot = slot),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Subtotal', style: AppTextStyles.bodyMedium),
              const Spacer(),
              Text(
                '₹${cart.subtotal}',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (cart.discount > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text('You save',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                    )),
                const Spacer(),
                Text(
                  '₹${cart.discount}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final SampleCollectionOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.primaryLight : AppColors.white,
        borderRadius: AppDecorations.borderRadiusMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDecorations.borderRadiusMd,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: AppDecorations.borderRadiusMd,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  option == SampleCollectionOption.homeVisit
                      ? Icons.home_rounded
                      : Icons.local_hospital_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.label,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                      Text(option.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          )),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
