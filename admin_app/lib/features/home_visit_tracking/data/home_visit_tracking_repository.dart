import '../../../core/constants/app_constants.dart';
import '../../../data/services/dio_service.dart';
import 'tracking_models.dart';

class HomeVisitTrackingRepository {
  HomeVisitTrackingRepository({DioService? dio}) : _dio = dio ?? DioService();

  final DioService _dio;

  Future<TrackingSnapshot> fetchSnapshot({
    required String role,
    required String bookingId,
    bool includeRoute = true,
  }) async {
    final path = role == 'nurse'
        ? AppConstants.endpointNurseBookingTracking(bookingId)
        : AppConstants.endpointDoctorBookingTracking(bookingId);
    final response = await _dio.get(
      path,
      queryParameters: {'route': includeRoute ? 'true' : 'false'},
    );
    return _parseSnapshot(response.data);
  }

  Future<TrackingSnapshot> startTrip({
    required String role,
    required String bookingId,
  }) async {
    final path = role == 'nurse'
        ? AppConstants.endpointNurseTrackingStart(bookingId)
        : AppConstants.endpointDoctorTrackingStart(bookingId);
    final response = await _dio.post(path, data: {});
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final snapshot = data['snapshot'] as Map<String, dynamic>? ?? data;
    return TrackingSnapshot.fromJson(snapshot);
  }

  Future<TrackingSnapshot> stopTrip({
    required String role,
    required String bookingId,
    String? progress,
  }) async {
    final path = role == 'nurse'
        ? AppConstants.endpointNurseTrackingStop(bookingId)
        : AppConstants.endpointDoctorTrackingStop(bookingId);
    final response = await _dio.post(
      path,
      data: {'progress': ?progress},
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final snapshot = data['snapshot'] as Map<String, dynamic>? ?? data;
    return TrackingSnapshot.fromJson(snapshot);
  }

  Future<void> sendLocationFallback({
    required String role,
    required String bookingId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    required int timestamp,
  }) async {
    final path = role == 'nurse'
        ? AppConstants.endpointNurseBookingLocation(bookingId)
        : AppConstants.endpointDoctorBookingLocation(bookingId);
    await _dio.post(
      path,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'heading': ?heading,
        'speed': ?speed,
        'timestamp': timestamp,
      },
    );
  }

  TrackingSnapshot _parseSnapshot(dynamic raw) {
    final body = raw as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return TrackingSnapshot.fromJson(data);
  }
}
