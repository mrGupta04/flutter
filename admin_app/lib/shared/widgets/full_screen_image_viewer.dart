import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/media_url_utils.dart';

/// Opens a dark full-screen viewer so the complete profile photo can be seen.
void showFullScreenNetworkImage(
  BuildContext context, {
  required String imageUrl,
  String? title,
}) {
  final resolved = MediaUrlUtils.resolve(imageUrl);
  if (resolved.isEmpty) return;
  _pushViewer(context, imageUrl: resolved, title: title);
}

void showFullScreenMemoryImage(
  BuildContext context, {
  required Uint8List bytes,
  String? title,
}) {
  if (bytes.isEmpty) return;
  _pushViewer(context, imageBytes: bytes, title: title);
}

void _pushViewer(
  BuildContext context, {
  String? imageUrl,
  Uint8List? imageBytes,
  String? title,
}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      barrierDismissible: true,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: _FullScreenImagePage(
            imageUrl: imageUrl,
            imageBytes: imageBytes,
            title: title,
          ),
        );
      },
    ),
  );
}

/// Wraps a profile photo so tapping it opens the full image.
class TappableProfilePhoto extends StatelessWidget {
  const TappableProfilePhoto({
    super.key,
    required this.child,
    this.imageUrl,
    this.imageBytes,
    this.title,
  });

  final Widget child;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? title;

  bool get _hasBytes => imageBytes != null && imageBytes!.isNotEmpty;
  bool get _hasUrl => MediaUrlUtils.resolve(imageUrl).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasBytes && !_hasUrl) return child;

    return GestureDetector(
      onTap: () {
        if (_hasBytes) {
          showFullScreenMemoryImage(
            context,
            bytes: imageBytes!,
            title: title,
          );
          return;
        }
        showFullScreenNetworkImage(
          context,
          imageUrl: imageUrl!,
          title: title,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _FullScreenImagePage extends StatelessWidget {
  const _FullScreenImagePage({
    this.imageUrl,
    this.imageBytes,
    this.title,
  });

  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(child: _image()),
              ),
            ),
            Positioned(
              top: 4,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  if (title != null && title!.trim().isNotEmpty)
                    Expanded(
                      child: Text(
                        title!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return Image.memory(imageBytes!, fit: BoxFit.contain);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl ?? '',
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      ),
      errorWidget: (_, __, ___) => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
          SizedBox(height: 12),
          Text('Could not load photo', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
