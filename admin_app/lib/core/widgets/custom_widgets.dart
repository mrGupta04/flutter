import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

/// Modern text field with floating label and themed borders.
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final VoidCallback? onChanged;
  final bool readOnly;
  final String? counterText;
  final TextInputAction? textInputAction;
  final VoidCallback? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.onChanged,
    this.readOnly = false,
    this.counterText,
    this.textInputAction,
    this.onFieldSubmitted,
    this.inputFormatters,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;
  late final FocusNode _focusNode;
  DateTime? _suppressSelectionUntil;
  VoidCallback? _controllerListener;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = FocusNode(debugLabel: 'CustomTextField:${widget.label}');
    _focusNode.addListener(_handleFocusChange);
    _attachController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController(oldWidget.controller);
      _attachController(widget.controller);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _detachController(widget.controller);
    _focusNode.dispose();
    super.dispose();
  }

  void _attachController(TextEditingController controller) {
    void listener() => _collapseAccidentalSelection();
    _controllerListener = listener;
    controller.addListener(listener);
  }

  void _detachController(TextEditingController controller) {
    final listener = _controllerListener;
    if (listener != null) {
      controller.removeListener(listener);
      _controllerListener = null;
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _suppressSelectionUntil = null;
      return;
    }
    // Desktop/web often select a range (or all) on the focusing click / rebuild.
    _suppressSelectionUntil =
        DateTime.now().add(const Duration(milliseconds: 400));
    _collapseAccidentalSelection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _collapseAccidentalSelection();
    });
  }

  void _collapseAccidentalSelection() {
    final until = _suppressSelectionUntil;
    if (until == null || DateTime.now().isAfter(until)) return;
    if (!_focusNode.hasFocus) return;

    final controller = widget.controller;
    final text = controller.text;
    if (text.isEmpty) return;

    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    final caret = selection.extentOffset.clamp(0, text.length);
    controller.selection = TextSelection.collapsed(offset: caret);
  }

  void _toggleObscure() {
    final controller = widget.controller;
    final selection = controller.selection;
    setState(() => _obscureText = !_obscureText);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !selection.isValid) return;
      final text = controller.text;
      final start = selection.start.clamp(0, text.length);
      final end = selection.end.clamp(0, text.length);
      controller.selection = TextSelection(baseOffset: start, extentOffset: end);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      obscureText: _obscureText,
      readOnly: widget.readOnly,
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.textInputAction,
      onChanged: (_) => widget.onChanged?.call(),
      onFieldSubmitted: (_) => widget.onFieldSubmitted?.call(),
      onTap: _collapseAccidentalSelection,
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: AppColors.primary, size: 22)
            : null,
        suffixIcon: widget.suffixIcon != null || widget.obscureText
            ? IconButton(
                icon: Icon(
                  widget.obscureText
                      ? (_obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined)
                      : widget.suffixIcon,
                  color: AppColors.grey500,
                ),
                onPressed: () {
                  if (widget.obscureText) {
                    _toggleObscure();
                  } else {
                    widget.onSuffixIconPressed?.call();
                  }
                },
              )
            : null,
        counterText: widget.counterText,
      ),
    );
  }
}

/// Primary CTA with optional gradient fill.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final double? height;
  final bool useGradient;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = isEnabled && !isLoading;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled && useGradient
              ? const LinearGradient(
                  colors: AppColors.gradientCta,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled
              ? (useGradient ? AppColors.primary : AppColors.primary)
              : AppColors.grey300,
          borderRadius: AppDecorations.borderRadiusMd,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: AppDecorations.borderRadiusMd,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: AppColors.white, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          label,
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final double? height;

  const CustomOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 54,
      child: OutlinedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.grey500,
          disabledBackgroundColor: AppColors.grey100,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppDecorations.borderRadiusMd,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingWidget({super.key, this.message, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppDecorations.iconTile(AppColors.error),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text('Something went wrong', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              CustomButton(label: 'Try Again', onPressed: onRetry!, width: 160),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppDecorations.iconTile(AppColors.grey400),
              child: Icon(icon, size: 48, color: AppColors.grey500),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTextStyles.headlineSmall),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: 28),
              CustomButton(
                label: actionLabel!,
                onPressed: onActionPressed!,
                width: 180,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SnackBarHelper {
  SnackBarHelper._();

  static void _show(
    BuildContext context,
    String message,
    Color background,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: AppDecorations.borderRadiusMd,
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, AppColors.success, Icons.check_circle_rounded);

  static void showError(BuildContext context, String message) =>
      _show(context, message, AppColors.error, Icons.error_outline_rounded);

  static void showInfo(BuildContext context, String message) =>
      _show(context, message, AppColors.info, Icons.info_outline_rounded);
}
