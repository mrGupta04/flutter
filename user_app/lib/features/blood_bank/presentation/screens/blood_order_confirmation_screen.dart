import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/blood_bank_model.dart';
import '../../../../data/repositories/blood_bank_repository.dart';

class BloodOrderConfirmationScreen extends ConsumerStatefulWidget {
  const BloodOrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<BloodOrderConfirmationScreen> createState() =>
      _BloodOrderConfirmationScreenState();
}

class _BloodOrderConfirmationScreenState
    extends ConsumerState<BloodOrderConfirmationScreen> {
  BloodOrderModel? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final response =
        await BloodBankRepository().getOrder(widget.orderId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response.success && response.data != null) {
        _order = response.data;
      } else {
        _error = response.error;
      }
    });
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Awaiting confirmation';
      case 'accepted':
        return 'Order accepted';
      case 'blood_ready':
        return 'Blood ready';
      case 'out_for_delivery':
        return 'Out for delivery';
      case 'delivered':
        return 'Delivered';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Order confirmation')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF2E7D32),
                        size: 72,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Order placed!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Order ID: ${_order?.id ?? widget.orderId}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _InfoTile(
                        label: 'Status',
                        value: _statusLabel(_order?.status ?? 'pending'),
                      ),
                      _InfoTile(
                        label: 'Blood group',
                        value: _order?.bloodGroup ?? '—',
                      ),
                      _InfoTile(
                        label: 'Component',
                        value: _order?.componentType ?? '—',
                      ),
                      _InfoTile(
                        label: 'Units',
                        value: '${_order?.units ?? 1}',
                      ),
                      _InfoTile(
                        label: 'Total',
                        value: '₹${_order?.totalAmount ?? 0}',
                      ),
                      if (_order?.estimatedDeliveryTime != null)
                        _InfoTile(
                          label: 'Estimated delivery',
                          value: _order!.estimatedDeliveryTime!
                              .toLocal()
                              .toString()
                              .substring(0, 16),
                        ),
                      const Spacer(),
                      CustomButton(
                        label: 'Track order',
                        onPressed: _load,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () =>
                            context.go(AppConstants.routeBloodBankSearch),
                        child: const Text('Back to blood banks'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
