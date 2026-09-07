import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/media_url_utils.dart';
import '../../core/widgets/custom_widgets.dart';
import 'full_screen_image_viewer.dart';

/// Profile photo picker used on registration and edit-profile forms.
class ProfilePicturePicker extends StatelessWidget {
  const ProfilePicturePicker({
    super.key,
    required this.imageBytes,
    required this.onImagePicked,
    this.onError,
    this.existingImageUrl,
    this.allowRemove = false,
    this.onRemove,
    this.uploading = false,
  });

  final Uint8List? imageBytes;
  final void Function(Uint8List bytes, String fileName) onImagePicked;
  final void Function(String message)? onError;
  final String? existingImageUrl;
  final bool allowRemove;
  final VoidCallback? onRemove;
  final bool uploading;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (bytes.length > AppConstants.maxProfileImageSize) {
      onError?.call(
        'Profile image size exceeds ${AppConstants.maxProfileImageSize ~/ (1024 * 1024)} MB.',
      );
      return;
    }

    final name = file.name.isNotEmpty ? file.name : 'profile.jpg';
    onImagePicked(bytes, name);
  }

  Future<void> _showSources(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(context, ImageSource.gallery);
                },
              ),
              if (allowRemove)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onRemove?.call();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null && imageBytes!.isNotEmpty;
    final resolvedUrl = MediaUrlUtils.resolve(existingImageUrl);
    final hasUrl = resolvedUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile Picture', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            TappableProfilePhoto(
              imageBytes: imageBytes,
              imageUrl: hasImage ? null : existingImageUrl,
              title: 'Profile picture',
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.grey100,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: uploading
                      ? const Center(child: CircularProgressIndicator())
                      : hasImage
                          ? Image.memory(imageBytes!, fit: BoxFit.cover)
                          : hasUrl
                              ? Image.network(resolvedUrl, fit: BoxFit.cover)
                              : Icon(Icons.person, size: 48, color: AppColors.grey400),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomOutlineButton(
                label: hasImage || hasUrl ? 'Change photo' : 'Upload photo',
                onPressed: uploading ? () {} : () => _showSources(context),
                icon: Icons.upload,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'JPG, PNG, or WEBP. Photos are compressed before upload. Max ${AppConstants.maxProfileImageSize ~/ (1024 * 1024)} MB.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
