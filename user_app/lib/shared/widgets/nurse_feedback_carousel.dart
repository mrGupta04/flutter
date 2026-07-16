import 'package:flutter/material.dart';

import '../../data/models/doctor_feedback_model.dart';
import 'doctor_feedback_carousel.dart';

/// Nurse profile feedback carousel. The review payload shape (rating,
/// comment, patientDisplayName) is identical to doctor feedback, so this
/// simply reuses [DoctorFeedbackCarousel] under a nurse-facing name.
class NurseFeedbackCarousel extends StatelessWidget {
  const NurseFeedbackCarousel({
    super.key,
    required this.reviews,
    this.averageRating,
    this.ratingCount = 0,
  });

  final List<DoctorFeedbackReview> reviews;
  final double? averageRating;
  final int ratingCount;

  @override
  Widget build(BuildContext context) {
    return DoctorFeedbackCarousel(
      reviews: reviews,
      averageRating: averageRating,
      ratingCount: ratingCount,
    );
  }
}
