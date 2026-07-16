import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/patient_booking_model.dart';
import '../services/dio_service.dart';

class CancellationPolicy {
  final bool canCancel;
  final double hoursLeft;
  final bool refundEligible;
  final int refundPercent;
  final String message;

  const CancellationPolicy({
    required this.canCancel,
    required this.hoursLeft,
    required this.refundEligible,
    required this.refundPercent,
    required this.message,
  });

  factory CancellationPolicy.fromJson(Map<String, dynamic> json) {
    return CancellationPolicy(
      canCancel: json['canCancel'] as bool? ?? false,
      hoursLeft: (json['hoursLeft'] as num?)?.toDouble() ?? 0,
      refundEligible: json['refundEligible'] as bool? ?? false,
      refundPercent: (json['refundPercent'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? '',
    );
  }
}

class BookingLifecycleRepository {
  BookingLifecycleRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<
      ({
        List<BookingTimelineStep> timeline,
        CancellationPolicy? policy,
        String? status,
        String? visitProgress,
      })> fetchTimeline(String bookingId) async {
    try {
      final response = await _dio.get(
        AppConstants.endpointPatientBookingTimeline(bookingId),
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final steps = (data['timeline'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) =>
              BookingTimelineStep.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final policyJson = data['policy'] as Map<String, dynamic>?;
      return (
        timeline: steps,
        policy:
            policyJson != null ? CancellationPolicy.fromJson(policyJson) : null,
        status: data['status']?.toString(),
        visitProgress: data['visitProgress']?.toString(),
      );
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<CancellationPolicy> fetchPolicy(String bookingId) async {
    try {
      final response = await _dio.get(
        AppConstants.endpointPatientBookingCancellationPolicy(bookingId),
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return CancellationPolicy.fromJson(data);
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<void> cancel(String bookingId, {String? reason}) async {
    try {
      await _dio.post(
        AppConstants.endpointPatientBookingCancel(bookingId),
        data: {
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      );
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<void> reschedule(
    String bookingId, {
    required DateTime slotStart,
    required DateTime slotEnd,
    int? dayOfWeek,
    int? startHour,
  }) async {
    try {
      await _dio.post(
        AppConstants.endpointPatientBookingReschedule(bookingId),
        data: {
          'slotStart': slotStart.toUtc().toIso8601String(),
          'slotEnd': slotEnd.toUtc().toIso8601String(),
          if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
          if (startHour != null) 'startHour': startHour,
        },
      );
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  String _messageFromDio(DioException error) {
    if (error.type == DioExceptionType.badResponse) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return (data['error'] ?? data['message'] ?? 'Request failed') as String;
      }
    }
    if (error.type == DioExceptionType.connectionError) {
      return AppConstants.errorNetworkException;
    }
    return AppConstants.errorSomethingWentWrong;
  }
}
