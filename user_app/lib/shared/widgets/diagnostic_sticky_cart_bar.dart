import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/labs/provider/lab_cart_provider.dart';
import '../../features/scans/provider/scan_cart_provider.dart';

/// Bottom sticky bar when lab or scan items are in the cart.
class DiagnosticStickyCartBar extends ConsumerWidget {
  const DiagnosticStickyCartBar({
    super.key,
    this.labId,
    this.centerId,
  });

  final String? labId;
  final String? centerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labCart = ref.watch(labCartProvider);
    final scanCart = ref.watch(scanCartProvider);

    final labVisible = labCart.items.isNotEmpty &&
        (labId == null || labCart.labId == labId);
    final scanVisible = scanCart.items.isNotEmpty &&
        (centerId == null || scanCart.centerId == centerId);

    if (!labVisible && !scanVisible) return const SizedBox.shrink();

    final itemCount = (labVisible ? labCart.itemCount : 0) +
        (scanVisible ? scanCart.itemCount : 0);
    final subtotal =
        (labVisible ? labCart.subtotal : 0) + (scanVisible ? scanCart.subtotal : 0);
    final discount =
        (labVisible ? labCart.discount : 0) + (scanVisible ? scanCart.discount : 0);

    return Material(
      elevation: 8,
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$itemCount item${itemCount == 1 ? '' : 's'} in cart',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '₹$subtotal',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (discount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Save ₹$discount',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => context.push(AppConstants.routeLabCart),
                child: const Text('View cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
