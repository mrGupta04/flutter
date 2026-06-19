class DoctorFeedbackReview {
  const DoctorFeedbackReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.patientDisplayName,
    this.consultationType,
    this.createdAt,
  });

  final String id;
  final int rating;
  final String comment;
  final String patientDisplayName;
  final String? consultationType;
  final DateTime? createdAt;

  factory DoctorFeedbackReview.fromJson(Map<String, dynamic> json) {
    return DoctorFeedbackReview(
      id: json['id'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: (json['comment'] as String? ?? '').trim(),
      patientDisplayName:
          (json['patientDisplayName'] as String? ?? 'Verified patient').trim(),
      consultationType: json['consultationType'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}

class DoctorFeedbackSummary {
  const DoctorFeedbackSummary({
    this.averageRating,
    this.ratingCount = 0,
    this.reviews = const [],
  });

  final double? averageRating;
  final int ratingCount;
  final List<DoctorFeedbackReview> reviews;

  bool get hasRating => ratingCount > 0 && averageRating != null;
  bool get hasReviews => reviews.isNotEmpty;

  factory DoctorFeedbackSummary.fromJson(Map<String, dynamic> json) {
    final reviews = (json['reviews'] as List? ?? [])
        .map((e) => DoctorFeedbackReview.fromJson(e as Map<String, dynamic>))
        .where((r) => r.rating > 0)
        .toList(growable: false);

    return DoctorFeedbackSummary(
      averageRating: _parseDouble(json['averageRating']),
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      reviews: reviews,
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
