import 'package:flutter/material.dart';

/// Android/Flutter can select a text *range* on a single tap.
/// Collapse that back to a caret for a short window after focus/tap.
class AccidentalSelectionBinder {
  AccidentalSelectionBinder({
    required TextEditingController controller,
    required FocusNode focusNode,
  })  : _controller = controller,
        _focusNode = focusNode {
    _focusNode.addListener(_handleFocus);
    _controller.addListener(_collapseIfArmed);
  }

  TextEditingController _controller;
  final FocusNode _focusNode;
  DateTime? _armedUntil;

  void rebind(TextEditingController controller) {
    if (identical(_controller, controller)) return;
    _controller.removeListener(_collapseIfArmed);
    _controller = controller;
    _controller.addListener(_collapseIfArmed);
  }

  void arm() {
    _armedUntil = DateTime.now().add(const Duration(milliseconds: 600));
    collapse();
    WidgetsBinding.instance.addPostFrameCallback((_) => collapse());
  }

  void collapse() {
    final until = _armedUntil;
    if (until == null || DateTime.now().isAfter(until)) return;
    if (!_focusNode.hasFocus) return;

    final text = _controller.text;
    if (text.isEmpty) return;

    final selection = _controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    final caret = selection.extentOffset.clamp(0, text.length);
    _controller.selection = TextSelection.collapsed(offset: caret);
  }

  void _handleFocus() {
    if (!_focusNode.hasFocus) {
      _armedUntil = null;
      return;
    }
    arm();
  }

  void _collapseIfArmed() => collapse();

  void dispose() {
    _focusNode.removeListener(_handleFocus);
    _controller.removeListener(_collapseIfArmed);
  }

  /// One-shot helper for raw [TextField]s that do not own a binder.
  static void onTap(TextEditingController controller) {
    void collapse() {
      final text = controller.text;
      final selection = controller.selection;
      if (!selection.isValid || selection.isCollapsed) return;
      controller.selection = TextSelection.collapsed(
        offset: selection.extentOffset.clamp(0, text.length),
      );
    }

    collapse();
    WidgetsBinding.instance.addPostFrameCallback((_) => collapse());
  }
}

/// Drop-in [TextField] that places a caret on tap instead of a text range.
class CaretOnTapTextField extends StatefulWidget {
  const CaretOnTapTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.style,
    this.autofocus = false,
    this.enabled,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final bool autofocus;
  final bool? enabled;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  State<CaretOnTapTextField> createState() => _CaretOnTapTextFieldState();
}

class _CaretOnTapTextFieldState extends State<CaretOnTapTextField> {
  late final FocusNode _focusNode;
  late final bool _ownsFocus;
  late AccidentalSelectionBinder _binder;

  @override
  void initState() {
    super.initState();
    _ownsFocus = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _binder = AccidentalSelectionBinder(
      controller: widget.controller,
      focusNode: _focusNode,
    );
  }

  @override
  void didUpdateWidget(covariant CaretOnTapTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _binder.rebind(widget.controller);
    }
  }

  @override
  void dispose() {
    _binder.dispose();
    if (_ownsFocus) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      style: widget.style,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      readOnly: widget.readOnly,
      onTap: () {
        _binder.arm();
        widget.onTap?.call();
      },
    );
  }
}
