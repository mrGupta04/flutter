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
