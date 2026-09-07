import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/booking_lifecycle_repository.dart';

const cancelReasons = [
  'Change of plans',
  'Found another provider',
  'Wrong booking',
  'Provider unavailable',
  'Other',
];

Future<bool> showCancelBookingSheet(
  BuildContext context, {
  required String bookingId,
}) async {
  final repo = BookingLifecycleRepository();
  CancellationPolicy? policy;
  try {
    policy = await repo.fetchPolicy(bookingId);
  } catch (_) {
    policy = null;
  }
  if (!context.mounted) return false;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _CancelSheet(
      policy: policy,
      onConfirm: (reason) async {
        await repo.cancel(bookingId, reason: reason);
      },
    ),
  );
  return result == true;
}

class _CancelSheet extends StatefulWidget {
  const _CancelSheet({required this.onConfirm, this.policy});

  final CancellationPolicy? policy;
  final Future<void> Function(String reason) onConfirm;

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  String _reason = cancelReasons.first;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Are you sure you want to cancel this booking?',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (widget.policy != null && widget.policy!.message.isNotEmpty)
            Text(
              widget.policy!.message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 16),
          Text(
            'Reason',
            style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reason in cancelReasons)
                ChoiceChip(
                  label: Text(reason),
                  selected: _reason == reason,
                  onSelected: (_) => setState(() => _reason = reason),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.pop(context, false),
                  child: const Text('Keep booking'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                  onPressed: _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          try {
                            await widget.onConfirm(_reason);
                            if (context.mounted) Navigator.pop(context, true);
                          } catch (e) {
                            if (context.mounted) {
                              setState(() => _busy = false);
                              SnackBarHelper.showError(context, e.toString());
                            }
                          }
                        },
                  child: Text(_busy ? 'Cancelling…' : 'Cancel booking'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
