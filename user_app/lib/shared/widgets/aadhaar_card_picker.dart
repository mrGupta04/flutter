import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_widgets.dart';

/// Aadhaar card image picker for patient registration.
class AadhaarCardPicker extends StatelessWidget {
  const AadhaarCardPicker({
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
    if (bytes.length > AppConstants.maxFileSize) {
      onError?.call(
        'Image size exceeds ${AppConstants.maxFileSize ~/ (1024 * 1024)} MB.',
      );
      return;
    }

    final name = file.name.isNotEmpty ? file.name : 'aadhaar.jpg';
    onImagePicked(bytes, name);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null && imageBytes!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aadhaar card photo', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: hasImage
                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 40,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload front of Aadhaar card',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        CustomOutlineButton(
          label: 'Upload Aadhaar card',
          onPressed: () => _pick(context),
          icon: Icons.upload_file_rounded,
        ),
        const SizedBox(height: 8),
        Text(
          'Clear photo of your Aadhaar card. JPG or PNG, max ${AppConstants.maxFileSize ~/ (1024 * 1024)} MB.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
