import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../provider/lab_cart_provider.dart';

class LabStickyCartBar extends ConsumerWidget {
  const LabStickyCartBar({super.key, this.labId});

  final String? labId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(labCartProvider);
    if (cart.items.isEmpty) return const SizedBox.shrink();
    if (labId != null && cart.labId != labId) return const SizedBox.shrink();

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
                      '${cart.itemCount} test${cart.itemCount == 1 ? '' : 's'} selected',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '₹${cart.subtotal}',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (cart.discount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Save ₹${cart.discount}',
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
                child: const Text('Proceed to Cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
