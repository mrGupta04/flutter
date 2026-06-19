import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/doctor_feedback_model.dart';

/// Horizontally auto-scrolling patient feedback cards for doctor profiles.
class DoctorFeedbackCarousel extends StatefulWidget {
  const DoctorFeedbackCarousel({
    super.key,
    required this.reviews,
    this.averageRating,
    this.ratingCount = 0,
  });

  final List<DoctorFeedbackReview> reviews;
  final double? averageRating;
  final int ratingCount;

  @override
  State<DoctorFeedbackCarousel> createState() => _DoctorFeedbackCarouselState();
}

class _DoctorFeedbackCarouselState extends State<DoctorFeedbackCarousel> {
  static const double _cardWidth = 280;
  static const Duration _scrollInterval = Duration(seconds: 4);

  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  @override
  void didUpdateWidget(covariant DoctorFeedbackCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reviews.length != widget.reviews.length) {
      _currentIndex = 0;
      _restartAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _restartAutoScroll() {
    _autoScrollTimer?.cancel();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.reviews.length <= 1) return;

    _autoScrollTimer = Timer.periodic(_scrollInterval, (_) {
      if (!mounted || !_scrollController.hasClients) return;

      _currentIndex = (_currentIndex + 1) % widget.reviews.length;
      final target = _currentIndex * (_cardWidth + 12);

      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reviews.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Patient feedback',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (widget.averageRating != null && widget.ratingCount > 0)
              _OverallRatingBadge(
                rating: widget.averageRating!,
                count: widget.ratingCount,
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 148,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.reviews.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: _cardWidth,
                child: _FeedbackReviewCard(review: widget.reviews[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class DoctorOverallRatingChip extends StatelessWidget {
  const DoctorOverallRatingChip({
    super.key,
    required this.rating,
    this.count,
    this.compact = false,
  });

  final double rating;
  final int? count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.offerLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.offer.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: compact ? 12 : 13,
            color: AppColors.offer,
          ),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.offerDark,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 9 : 10,
              height: 1,
            ),
          ),
          if (count != null && count! > 0) ...[
            Text(
              ' ($count)',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.offerDark.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
                fontSize: compact ? 8 : 9,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverallRatingBadge extends StatelessWidget {
  const _OverallRatingBadge({required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.offerLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.offer.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: AppColors.offer),
          const SizedBox(width: 4),
          Text(
            '${rating.toStringAsFixed(1)} · $count',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.offerDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackReviewCard extends StatelessWidget {
  const _FeedbackReviewCard({required this.review});

  final DoctorFeedbackReview review;

  @override
  Widget build(BuildContext context) {
    final initial = review.patientDisplayName.isNotEmpty
        ? review.patientDisplayName.substring(0, 1).toUpperCase()
        : 'P';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  initial,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.patientDisplayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 15,
                    color: AppColors.offer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              review.comment,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
