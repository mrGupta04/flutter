import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/payment_repository.dart';

enum _DummyPayMethod { upi, card, wallet }

/// Development checkout for nurse home visits. Replace with Razorpay later.
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
  final _formKey = GlobalKey<FormState>();
  final _upiController = TextEditingController(text: 'patient@upi');
  final _cardController = TextEditingController(text: '4111 1111 1111 1111');
  final _expiryController = TextEditingController(text: '12/28');
  final _cvvController = TextEditingController(text: '123');
  final _nameController = TextEditingController(text: 'Test Patient');

  _DummyPayMethod _method = _DummyPayMethod.upi;
  bool _busy = false;

  @override
  void dispose() {
    _upiController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool success}) async {
    if (_busy) return;
    if (success && !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final res = await _repo.submitMockPayment(
      bookingId: widget.bookingId,
      result: success ? 'SUCCESS' : 'FAILED',
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

    if (!success) {
      SnackBarHelper.showError(
        context,
        res.message ??
            'Payment failed. You can try again before the payment window expires.',
      );
      Navigator.pop(context, false);
      return;
    }

    SnackBarHelper.showSuccess(
      context,
      res.message ?? 'Payment successful. Your nurse booking is confirmed.',
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pay for nurse visit')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.offerLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.offer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dummy payment for development. No money is charged. Razorpay can replace this later.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Amount payable',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${widget.amount}',
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose payment method',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _MethodTile(
                  selected: _method == _DummyPayMethod.upi,
                  icon: Icons.qr_code_2_rounded,
                  title: 'UPI',
                  subtitle: 'GPay, PhonePe, Paytm',
                  onTap: () => setState(() => _method = _DummyPayMethod.upi),
                ),
                const SizedBox(height: 8),
                _MethodTile(
                  selected: _method == _DummyPayMethod.card,
                  icon: Icons.credit_card_rounded,
                  title: 'Debit / Credit card',
                  subtitle: 'Visa, Mastercard, RuPay',
                  onTap: () => setState(() => _method = _DummyPayMethod.card),
                ),
                const SizedBox(height: 8),
                _MethodTile(
                  selected: _method == _DummyPayMethod.wallet,
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Wallet',
                  subtitle: 'Dummy wallet balance',
                  onTap: () => setState(() => _method = _DummyPayMethod.wallet),
                ),
                const SizedBox(height: 16),
                if (_method == _DummyPayMethod.upi)
                  CustomTextField(
                    controller: _upiController,
                    label: 'UPI ID',
                    hint: 'name@upi',
                    prefixIcon: Icons.alternate_email,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a UPI ID';
                      }
                      if (!value.contains('@')) return 'Enter a valid UPI ID';
                      return null;
                    },
                  )
                else if (_method == _DummyPayMethod.card) ...[
                  CustomTextField(
                    controller: _nameController,
                    label: 'Name on card',
                    prefixIcon: Icons.person_outline,
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter the name on the card'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _cardController,
                    label: 'Card number',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.credit_card,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                    ],
                    validator: (value) {
                      final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 12) return 'Enter a dummy card number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _expiryController,
                          label: 'Expiry',
                          hint: 'MM/YY',
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Required'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _cvvController,
                          label: 'CVV',
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          validator: (value) =>
                              value == null || value.trim().length < 3
                                  ? 'Enter CVV'
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Dummy wallet will be used. No real balance is deducted.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _busy ? null : () => _submit(success: true),
                  child: Text('Pay ₹${widget.amount}'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : () => _submit(success: false),
                  child: const Text('Simulate failed payment'),
                ),
              ],
            ),
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x66FFFFFF),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Processing dummy payment…'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
