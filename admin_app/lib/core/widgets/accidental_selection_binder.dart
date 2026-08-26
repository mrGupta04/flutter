import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.autofocus = false,
    this.enabled,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.readOnly = false,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final bool autofocus;
  final bool? enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool obscureText;
  final bool readOnly;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

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
      textCapitalization: widget.textCapitalization,
      style: widget.style,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      obscureText: widget.obscureText,
      readOnly: widget.readOnly,
      textAlign: widget.textAlign,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onTap: () {
        _binder.arm();
        widget.onTap?.call();
      },
    );
  }
}

/// Drop-in [TextFormField] that places a caret on tap instead of a text range.
class CaretOnTapTextFormField extends StatefulWidget {
  const CaretOnTapTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.autofocus = false,
    this.enabled,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.readOnly = false,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.validator,
    this.autovalidateMode,
    this.onChanged,
    this.onFieldSubmitted,
    this.onSaved,
    this.onTap,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final bool autofocus;
  final bool? enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool obscureText;
  final String obscuringCharacter;
  final bool enableSuggestions;
  final bool autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool readOnly;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final void Function(String?)? onSaved;
  final VoidCallback? onTap;

  @override
  State<CaretOnTapTextFormField> createState() =>
      _CaretOnTapTextFormFieldState();
}

class _CaretOnTapTextFormFieldState extends State<CaretOnTapTextFormField> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  late final FocusNode _focusNode;
  late final bool _ownsFocus;
  late AccidentalSelectionBinder _binder;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _ownsFocus = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _binder = AccidentalSelectionBinder(
      controller: _controller,
      focusNode: _focusNode,
    );
  }

  @override
  void didUpdateWidget(covariant CaretOnTapTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller && widget.controller != null) {
      _binder.rebind(widget.controller!);
    }
  }

  @override
  void dispose() {
    _binder.dispose();
    if (_ownsFocus) _focusNode.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller ?? _controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      style: widget.style,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      obscureText: widget.obscureText,
      obscuringCharacter: widget.obscuringCharacter,
      enableSuggestions: widget.enableSuggestions,
      autocorrect: widget.autocorrect,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      readOnly: widget.readOnly,
      textAlign: widget.textAlign,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      onSaved: widget.onSaved,
      onTap: () {
        _binder.arm();
        widget.onTap?.call();
      },
    );
  }
}
