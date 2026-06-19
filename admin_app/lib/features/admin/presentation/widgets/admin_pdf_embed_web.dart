// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// In-app PDF viewer for Flutter web (iframe).
class AdminPdfEmbed extends StatefulWidget {
  const AdminPdfEmbed({super.key, required this.url});

  final String url;

  @override
  State<AdminPdfEmbed> createState() => _AdminPdfEmbedState();
}

class _AdminPdfEmbedState extends State<AdminPdfEmbed> {
  static int _viewCounter = 0;
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'admin-pdf-${_viewCounter++}';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = widget.url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
