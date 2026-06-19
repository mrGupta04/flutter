import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// PDF embed on mobile/desktop — opens in the system browser.
class AdminPdfEmbed extends StatelessWidget {
  const AdminPdfEmbed({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 72),
            const SizedBox(height: 16),
            const Text(
              'PDF preview opens in your browser on this device.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openPdf(url),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPdf(String link) async {
    final uri = Uri.parse(link);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri);
    }
  }
}
