import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_widgets.dart';

/// Profile photo picker used on registration forms.
class ProfilePicturePicker extends StatelessWidget {
  const ProfilePicturePicker({
    super.key,
    required this.imageBytes,
    required this.onImagePicked,
    this.onError,
  });

  final Uint8List? imageBytes;
  final void Function(Uint8List bytes, String fileName) onImagePicked;
  final void Function(String message)? onError;

  Future<void> _pick(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
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

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null && imageBytes!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile Picture', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.grey100,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: ClipOval(
                child: hasImage
                    ? Image.memory(imageBytes!, fit: BoxFit.cover)
                    : Icon(Icons.person, size: 48, color: AppColors.grey400),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomOutlineButton(
                label: 'Upload Photo',
                onPressed: () => _pick(context),
                icon: Icons.upload,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'JPG, PNG, or WEBP. Max ${AppConstants.maxProfileImageSize ~/ (1024 * 1024)} MB.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
