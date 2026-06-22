import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/patient_booking_model.dart';

/// Dropdown-style control with checkbox options for booking type filters.
class BookingCategoryFilterDropdown extends StatelessWidget {
  const BookingCategoryFilterDropdown({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<PatientBookingCategory> selected;
  final ValueChanged<Set<PatientBookingCategory>> onChanged;

  String _summaryLabel() {
    final active = selected.isEmpty || selected.contains(PatientBookingCategory.all)
        ? const <PatientBookingCategory>[]
        : selected.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    if (active.isEmpty) return 'All booking types';
    if (active.length == 1) return active.first.label;
    return '${active.length} types selected';
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    var local = Set<PatientBookingCategory>.from(
      selected.isEmpty ? {PatientBookingCategory.all} : selected,
    );

    final applied = await showModalBottomSheet<Set<PatientBookingCategory>>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void toggleCategory(PatientBookingCategory category, bool? checked) {
              setModalState(() {
                if (category == PatientBookingCategory.all) {
                  local = {PatientBookingCategory.all};
                  return;
                }

                local.remove(PatientBookingCategory.all);
                if (checked == true) {
                  local.add(category);
                } else {
                  local.remove(category);
                }

                if (local.isEmpty) {
                  local = {PatientBookingCategory.all};
                }
              });
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    Text(
                      'Filter by booking type',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select one or more types to narrow the list.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...PatientBookingCategory.values.map(
                      (category) => CheckboxListTile(
                        value: local.contains(category),
                        onChanged: (checked) =>
                            toggleCategory(category, checked),
                        title: Text(
                          category.label,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(
                                ctx,
                                {PatientBookingCategory.all},
                              );
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(ctx, local),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (applied != null) {
      onChanged(applied);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => _openFilterSheet(context),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Booking type',
            suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          ),
          child: Text(
            _summaryLabel(),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Filters bookings by one or more categories (`All` shows everything).
List<PatientBookingModel> filterBookingsByCategories(
  List<PatientBookingModel> bookings,
  Set<PatientBookingCategory> categories,
) {
  if (categories.isEmpty || categories.contains(PatientBookingCategory.all)) {
    return bookings;
  }
  return bookings
      .where((booking) => categories.any((category) => category.matches(booking)))
      .toList();
}
