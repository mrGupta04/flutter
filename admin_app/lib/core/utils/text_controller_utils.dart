import 'package:flutter/widgets.dart';

/// Registers a listener that runs only when [controller] text changes.
///
/// [TextEditingController] also notifies on selection/composing changes (e.g. tap
/// to focus). Syncing Riverpod state on those notifications rebuilds the form and
/// can select the whole field. This helper ignores selection-only updates.
VoidCallback addTextChangeListener(
  TextEditingController controller,
  ValueChanged<String> onTextChanged,
) {
  var lastText = controller.text;
  void listener() {
    final text = controller.text;
    if (text == lastText) return;
    lastText = text;
    onTextChanged(text);
  }

  controller.addListener(listener);
  return listener;
}

/// Sets controller text with the caret at the end (does not select all).
void setControllerText(TextEditingController controller, String text) {
  controller.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}
