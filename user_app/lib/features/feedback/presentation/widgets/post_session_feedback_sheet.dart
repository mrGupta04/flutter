import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/consultation_feedback_repository.dart';

class PostSessionFeedbackInfo {
  const PostSessionFeedbackInfo({
    required this.bookingId,
    required this.doctorId,
    required this.doctorName,
    this.doctorProfilePicture,
    required this.consultationType,
    this.sessionLabel,
  });

  final String bookingId;
  final String doctorId;
  final String doctorName;
  final String? doctorProfilePicture;
  final String consultationType;
  final String? sessionLabel;
}

String feedbackTitleForType(String consultationType) {
  switch (consultationType) {
    case 'visit_site':
      return 'How was your clinic visit?';
    case 'book_home':
      return 'How was your home visit?';
    default:
      return 'How was your consultation?';
  }
}

String feedbackSubtitleForType(String consultationType) {
  switch (consultationType) {
    case 'visit_site':
      return 'Rate your experience at the clinic';
    case 'book_home':
      return 'Rate your home visit experience';
    default:
      return 'Rate your video consultation experience';
  }
}

/// Zomato-style bottom sheet shown after a session or slot ends.
Future<void> showPostSessionFeedbackSheet(
  BuildContext context,
  PostSessionFeedbackInfo info, {
  ConsultationFeedbackRepository? repository,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => PostSessionFeedbackSheet(
      info: info,
      repository: repository ?? ConsultationFeedbackRepository(),
    ),
  );
}

class PostSessionFeedbackSheet extends StatefulWidget {
  const PostSessionFeedbackSheet({
    super.key,
    required this.info,
    required this.repository,
  });

  final PostSessionFeedbackInfo info;
  final ConsultationFeedbackRepository repository;

  @override
  State<PostSessionFeedbackSheet> createState() =>
      _PostSessionFeedbackSheetState();
}

class _PostSessionFeedbackSheetState extends State<PostSessionFeedbackSheet> {
  int _rating = 0;
  bool _submitting = false;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.repository.submitFeedback(
        bookingId: widget.info.bookingId,
        rating: _rating,
        comment: _commentController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      SnackBarHelper.showSuccess(context, 'Thanks for your feedback!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      SnackBarHelper.showError(context, e.toString());
    }
  }

  Future<void> _dismiss() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.repository.dismissFeedback(widget.info.bookingId);
    } catch (_) {
      // Closing the sheet is enough if dismiss fails offline.
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final imageUrl = MediaUrlUtils.resolve(info.doctorProfilePicture);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Session completed',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            feedbackSubtitleForType(info.consultationType),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.grey100,
            backgroundImage:
                imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
            child: imageUrl.isEmpty
                ? Icon(Icons.medical_services, color: AppColors.primary, size: 32)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            info.doctorName,
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          if (info.sessionLabel != null && info.sessionLabel!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              info.sessionLabel!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          Text(
            feedbackTitleForType(info.consultationType),
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final filled = starValue <= _rating;
              return IconButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _rating = starValue),
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 40,
                  color: filled ? AppColors.offer : AppColors.grey400,
                ),
              );
            }),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 4),
            Text(
              _ratingLabel(_rating),
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.offer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            enabled: !_submitting,
            maxLines: 3,
            maxLength: 500,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Tell us more (optional)',
              filled: true,
              fillColor: AppColors.grey50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _rating < 1 || _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text('Submit rating'),
            ),
          ),
          TextButton(
            onPressed: _submitting ? null : _dismiss,
            child: const Text('Maybe later'),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Could be better';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      default:
        return 'Excellent!';
    }
  }
}
