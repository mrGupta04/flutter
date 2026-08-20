import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/payment_repository.dart';

class NurseMockPaymentScreen extends StatefulWidget {
  const NurseMockPaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
  });

  final String bookingId;
  final int amount;

  @override
  State<NurseMockPaymentScreen> createState() => _NurseMockPaymentScreenState();
}

class _NurseMockPaymentScreenState extends State<NurseMockPaymentScreen> {
  final _repo = PaymentRepository();
  bool _busy = false;

  Future<void> _submit(String result) async {
    if (_busy) return;
    setState(() => _busy = true);
    final res = await _repo.submitMockPayment(
      bookingId: widget.bookingId,
      result: result,
      amount: widget.amount,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (!res.success) {
      SnackBarHelper.showError(
        context,
        res.error ?? 'Payment could not be processed',
      );
      return;
    }

    if (result == 'FAILED') {
      SnackBarHelper.showError(
        context,
        res.message ??
            'Payment failed. You can try again before the 10-minute payment window expires.',
      );
      Navigator.pop(context, false);
      return;
    }

    SnackBarHelper.showSuccess(
      context,
      res.message ?? 'Your nurse booking is confirmed.',
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mock Payment')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Mock Payment',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is a development payment.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Amount: ₹${widget.amount}',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else ...[
              FilledButton(
                onPressed: () => _submit('SUCCESS'),
                child: const Text('SUCCESS PAYMENT'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _submit('FAILED'),
                child: const Text('FAILED PAYMENT'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
