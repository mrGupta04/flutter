import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../features/labs/provider/lab_cart_provider.dart';
import '../../features/scans/provider/scan_cart_provider.dart';

final diagnosticCartItemCountProvider = Provider<int>((ref) {
  final labCount = ref.watch(labCartProvider).itemCount;
  final scanCount = ref.watch(scanCartProvider).itemCount;
  return labCount + scanCount;
});

/// Cart icon with badge for lab + scan items.
class DiagnosticCartIconButton extends ConsumerWidget {
  const DiagnosticCartIconButton({
    super.key,
    this.iconColor,
    this.tooltip = 'Cart',
  });

  final Color? iconColor;
  final String tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(diagnosticCartItemCountProvider);

    return IconButton(
      tooltip: tooltip,
      onPressed: () => context.push(AppConstants.routeLabCart),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: Icon(
          Icons.shopping_cart_outlined,
          color: iconColor,
        ),
      ),
    );
  }
}
