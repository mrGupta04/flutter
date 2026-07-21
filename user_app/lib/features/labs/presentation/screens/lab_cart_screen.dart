import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/phone_countries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../../../core/widgets/custom_widgets.dart' as custom;
import '../../../../data/repositories/lab_repository.dart';
import '../../../../data/repositories/scan_repository.dart';
import '../../../scans/data/scan_procedure_icons.dart';
import '../../../scans/data/scans_catalog.dart';
import '../../../scans/provider/scan_cart_provider.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';
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
  final _addressController = TextEditingController();

  static const _timeSlots = [
    '07:00 AM - 09:00 AM',
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
  ];

  static const _scanTimeSlots = [
    '8:00 AM',
    '10:00 AM',
    '12:00 PM',
    '2:00 PM',
    '4:00 PM',
    '6:00 PM',
  ];

  String? _selectedSlot;
  String? _scanSlot;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedSlot = _timeSlots.first;
    _scanSlot = _scanTimeSlots.first;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
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

  Future<void> _confirmBooking({
    required LabCartState labCart,
    required ScanCartState scanCart,
  }) async {
    final hasLab = labCart.items.isNotEmpty;
    final hasScan = scanCart.items.isNotEmpty;

    if (hasLab &&
        (_collectionOption == null ||
            _selectedDate == null ||
            _selectedSlot == null)) {
      return;
    }

    if (hasScan && (_selectedDate == null || _scanSlot == null)) {
      return;
    }

    if (hasLab) {
      final labId = labCart.labId;
      if (labId == null || labId.isEmpty) {
        custom.SnackBarHelper.showError(
          context,
          'Please select a lab before booking.',
        );
        return;
      }

      if (_collectionOption == SampleCollectionOption.homeVisit &&
          _addressController.text.trim().length < 5) {
        custom.SnackBarHelper.showError(
          context,
          'Enter your home collection address.',
        );
        return;
      }
    }

    if (hasScan && (scanCart.centerId == null || scanCart.centerId!.isEmpty)) {
      custom.SnackBarHelper.showError(context, 'Invalid scan center.');
      return;
    }

    final loggedIn = await ensureUserLoggedIn(
      context,
      message: 'Please log in to book tests and track your reports.',
    );
    if (!loggedIn || !mounted) return;

    final user = ref.read(patientAuthProvider).user;
    if (user == null) {
      custom.SnackBarHelper.showError(context, 'Please log in again.');
      return;
    }

    setState(() => _isSubmitting = true);

    if (hasLab) {
      final response = await LabRepository().createBooking(
        labId: labCart.labId!,
        patientName: user.fullName,
        patientMobile: user.mobileNumber,
        patientEmail: user.email,
        patientId: user.id,
        countryCode: user.countryCode.isEmpty
            ? PhoneCountries.defaultDialCode
            : user.countryCode,
        collectionType: _collectionOption == SampleCollectionOption.homeVisit
            ? 'home_collection'
            : 'lab_visit',
        collectionAddress: _collectionOption == SampleCollectionOption.homeVisit
            ? _addressController.text.trim()
            : null,
        scheduledDate: _selectedDate!,
        timeSlot: _selectedSlot!,
        items: labCart.items
            .map(
              (i) => {
                'testId': i.testId,
                'testName': i.testName,
                'price': i.priceInr,
              },
            )
            .toList(),
        totalAmount: labCart.subtotal,
      );

      if (!mounted) return;
      if (!response.success) {
        setState(() => _isSubmitting = false);
        custom.SnackBarHelper.showError(
          context,
          response.error ?? 'Could not submit lab booking',
        );
        return;
      }
      ref.read(labCartProvider.notifier).clear();
    }

    if (hasScan) {
      final repo = ScanRepository();
      for (final item in scanCart.items) {
        final response = await repo.createBooking(
          scanCenterId: scanCart.centerId!,
          patientName: user.fullName,
          patientMobile: user.mobileNumber,
          patientEmail: user.email,
          patientId: user.id,
          countryCode: user.countryCode.isEmpty
              ? PhoneCountries.defaultDialCode
              : user.countryCode,
          scanId: item.scanId,
          scanName: item.scanName,
          categoryId: item.categoryId,
          scheduledDate: _selectedDate!,
          timeSlot: _scanSlot!,
          totalAmount: item.priceInr,
          preparationNotes: item.preparationInstructions,
          paymentMethod: 'online',
        );

        if (!mounted) return;
        if (!response.success) {
          setState(() => _isSubmitting = false);
          custom.SnackBarHelper.showError(
            context,
            response.error ?? 'Could not submit scan booking for ${item.scanName}',
          );
          return;
        }
      }
      ref.read(scanCartProvider.notifier).clear();
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final dateStr = DateFormat('EEE, dd MMM yyyy').format(_selectedDate!);
    final total = (hasLab ? labCart.subtotal : 0) + (hasScan ? scanCart.subtotal : 0);
    final labName = hasLab ? (labCart.labName ?? 'Lab') : '';

    if (hasLab && !hasScan) {
      context.go(
        '${AppConstants.routeLabBookingConfirmation}?'
        'lab=${Uri.encodeComponent(labName)}'
        '&date=${Uri.encodeComponent(dateStr)}'
        '&slot=${Uri.encodeComponent(_selectedSlot!)}'
        '&total=$total',
      );
      return;
    }

    custom.SnackBarHelper.showSuccess(
      context,
      hasLab && hasScan
          ? 'Lab and scan booking requests submitted. Complete payment from My Bookings after confirmation.'
          : hasScan
              ? 'Scan booking requests submitted. Complete payment from My Bookings after the center confirms.'
              : 'Booking request submitted.',
    );
    context.go(AppConstants.routeUserDashboard);
  }

  @override
  Widget build(BuildContext context) {
    final labCart = ref.watch(labCartProvider);
    final scanCart = ref.watch(scanCartProvider);
    final hasLab = labCart.items.isNotEmpty;
    final hasScan = scanCart.items.isNotEmpty;
    final grandTotal = labCart.subtotal + scanCart.subtotal;
    final grandDiscount = labCart.discount + scanCart.discount;

    if (!hasLab && !hasScan) {
      return Scaffold(
        appBar: AppBar(title: const Text('My cart')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    size: 56, color: AppColors.textTertiary),
                const SizedBox(height: 12),
                Text(
                  'Your cart is empty',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add lab tests or scans from partner labs and imaging centers.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go(AppConstants.routeLabs),
                  child: const Text('Explore lab tests'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => context.go(AppConstants.routeScans),
                  child: const Text('Explore scans'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final homeAvailable =
        labCart.items.any((i) => i.homeCollectionAvailable);
    final onsiteAvailable =
        labCart.items.any((i) => i.onsiteCollectionAvailable);

    if (hasLab && _collectionOption == null) {
      if (homeAvailable) {
        _collectionOption = SampleCollectionOption.homeVisit;
      } else if (onsiteAvailable) {
        _collectionOption = SampleCollectionOption.onsite;
      }
    }

    final canSubmit = (!hasLab ||
            (_collectionOption != null &&
                _selectedDate != null &&
                _selectedSlot != null)) &&
        (!hasScan || (_selectedDate != null && _scanSlot != null));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My cart'),
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
              label: 'Request booking • ₹$grandTotal',
              icon: Icons.check_rounded,
              isLoading: _isSubmitting,
              isEnabled: canSubmit,
              onPressed: () => _confirmBooking(
                labCart: labCart,
                scanCart: scanCart,
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (hasLab) ...[
            Text(
              'Lab tests',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              labCart.labName ?? 'Selected lab',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${labCart.itemCount} test${labCart.itemCount == 1 ? '' : 's'}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ...labCart.items.map(
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
            const SizedBox(height: 8),
          ],
          if (hasScan) ...[
            if (hasLab) const Divider(height: 28),
            Text(
              'Scans',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              scanCart.centerName ?? 'Selected center',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${scanCart.itemCount} scan${scanCart.itemCount == 1 ? '' : 's'}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ...scanCart.items.map((item) {
              final procedure = ScansCatalog.byId(item.scanId);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: procedure != null
                      ? ScanProcedureIconAvatar(procedure: procedure, size: 44)
                      : const Icon(Icons.medical_services_outlined),
                  title: Text(item.scanName),
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
                            .read(scanCartProvider.notifier)
                            .removeItem(item.scanId),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
          const Divider(height: 24),
          if (hasLab) ...[
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
            if (_collectionOption == SampleCollectionOption.homeVisit) ...[
              const SizedBox(height: 12),
              if ((ref.watch(patientAuthProvider).user?.savedAddresses ??
                      const [])
                  .isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in ref
                            .watch(patientAuthProvider)
                            .user
                            ?.savedAddresses ??
                        const [])
                      ActionChip(
                        label: Text(a.label),
                        onPressed: () {
                          _addressController.text = a.displayLine;
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Home collection address',
                  hintText: 'Flat, street, landmark, city',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
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
          if (hasLab) ...[
            Text(
              'Lab time slot',
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
            const SizedBox(height: 16),
          ],
          if (hasScan) ...[
            Text(
              'Scan time slot',
              style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _scanTimeSlots.map((slot) {
                final selected = _scanSlot == slot;
                return FilterChip(
                  label: Text(slot),
                  selected: selected,
                  onSelected: (_) => setState(() => _scanSlot = slot),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Text('Total', style: AppTextStyles.bodyMedium),
              const Spacer(),
              Text(
                '₹$grandTotal',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (grandDiscount > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text('You save',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                    )),
                const Spacer(),
                Text(
                  '₹$grandDiscount',
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
