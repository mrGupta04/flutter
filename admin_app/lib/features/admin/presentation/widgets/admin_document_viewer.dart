import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../data/models/doctor_document_model.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/app_widgets.dart';
import 'admin_pdf_embed.dart';

/// Full-screen document viewer (images with zoom, PDF in-app on web).
class AdminDocumentViewerScreen extends StatelessWidget {
  const AdminDocumentViewerScreen({
    super.key,
    required this.title,
    required this.fileUrl,
    this.mimeType,
  });

  final String title;
  final String fileUrl;
  final String? mimeType;

  static void open(
    BuildContext context, {
    required String title,
    required String fileUrl,
    String? mimeType,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminDocumentViewerScreen(
          title: title,
          fileUrl: fileUrl,
          mimeType: mimeType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = MediaUrlUtils.resolve(fileUrl);
    final isPdf = MediaUrlUtils.isPdfUrl(resolved, mimeType: mimeType);
    final isImage = !isPdf && MediaUrlUtils.isImageUrl(resolved, mimeType: mimeType);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: resolved.isEmpty
          ? Center(
              child: AppErrorWidget(message: 'Document URL is missing'),
            )
          : isPdf
              ? AdminPdfEmbed(url: resolved)
              : isImage
                  ? _ImageFullView(url: resolved)
                  : _UnknownTypeView(url: resolved, mimeType: mimeType),
    );
  }
}

class _ImageFullView extends StatelessWidget {
  const _ImageFullView({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (_, __, ___) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, color: Colors.white54, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Could not load image',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnknownTypeView extends StatelessWidget {
  const _UnknownTypeView({required this.url, this.mimeType});

  final String url;
  final String? mimeType;

  @override
  Widget build(BuildContext context) {
    if (MediaUrlUtils.isPdfUrl(url, mimeType: mimeType)) {
      return AdminPdfEmbed(url: url);
    }
    return _ImageFullView(url: url);
  }
}

/// Inline preview card — tap opens full-screen viewer.
class AdminDocumentPreviewCard extends StatelessWidget {
  const AdminDocumentPreviewCard({
    super.key,
    required this.document,
    this.canReview = false,
    this.onVerify,
    this.onReject,
  });

  final DoctorDocumentModel document;
  final bool canReview;
  final Future<bool> Function()? onVerify;
  final Future<bool> Function(String reason)? onReject;

  @override
  Widget build(BuildContext context) {
    final url = document.fileUrl;
    final resolved = MediaUrlUtils.resolve(url);
    final isPdf = MediaUrlUtils.isPdfUrl(resolved, mimeType: document.mimeType);
    final isImage =
        !isPdf && MediaUrlUtils.isImageUrl(resolved, mimeType: document.mimeType);
    final canPreview = resolved.isNotEmpty && (isImage || isPdf);
    final statusColor = switch (document.status) {
      DocumentStatus.verified => AppColors.success,
      DocumentStatus.rejected => AppColors.error,
      DocumentStatus.underReview => AppColors.warning,
      _ => AppColors.pending,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: resolved.isEmpty
            ? null
            : () => AdminDocumentViewerScreen.open(
                  context,
                  title: document.documentTypeDisplay,
                  fileUrl: document.fileUrl!,
                  mimeType: document.mimeType,
                ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canPreview && isImage)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: resolved,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => _PreviewPlaceholder(isPdf: false),
                ),
              )
            else if (canPreview && isPdf)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _PreviewPlaceholder(isPdf: true),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.documentTypeDisplay,
                          style: AppTextStyles.titleSmall,
                        ),
                        if (document.contextLabel.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            document.contextLabel,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          document.fileName ?? 'Document',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (resolved.isNotEmpty)
                          Text(
                            'Tap to view full screen',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  VerificationBadge(
                    status: document.statusDisplay,
                    backgroundColor: statusColor,
                    textColor: statusColor,
                  ),
                  if (resolved.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.fullscreen, color: AppColors.textSecondary),
                  ],
                ],
              ),
            ),
            if (document.status == DocumentStatus.rejected &&
                document.rejectionReason?.trim().isNotEmpty == true)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  'Reason: ${document.rejectionReason}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            if (canReview && onVerify != null && onReject != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(context),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onVerify,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Verify'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    if (onReject == null) return;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject ${document.documentTypeDisplay}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Rejection reason',
            hintText: 'Tell the provider what needs to be fixed',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final reason = controller.text.trim();
      if (reason.isNotEmpty) {
        await onReject!(reason);
      }
    }
    controller.dispose();
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({required this.isPdf});

  final bool isPdf;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.25),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPdf ? Icons.picture_as_pdf : Icons.image,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              isPdf ? 'PDF document' : 'Preview unavailable',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
