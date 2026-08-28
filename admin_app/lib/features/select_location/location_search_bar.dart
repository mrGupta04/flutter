import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';

class LocationSearchBar extends StatelessWidget {
  const LocationSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.focusNode,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Search for area, street name...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, color: AppColors.grey400),
                ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
