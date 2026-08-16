import '../../../core/constants/app_constants.dart';
import '../../../data/services/dio_service.dart';
import 'tracking_models.dart';

class HomeVisitTrackingRepository {
  HomeVisitTrackingRepository({DioService? dio}) : _dio = dio ?? DioService();

  final DioService _dio;

  Future<TrackingSnapshot> fetchSnapshot(
    String bookingId, {
    bool includeRoute = true,
  }) async {
    final response = await _dio.get(
      AppConstants.endpointPatientBookingTracking(bookingId),
      queryParameters: {'route': includeRoute ? 'true' : 'false'},
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return TrackingSnapshot.fromJson(data);
  }

  Future<TrackingSnapshot> fetchRoute(String bookingId) async {
    final response = await _dio.get(
      AppConstants.endpointPatientBookingRoute(bookingId),
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return TrackingSnapshot.fromJson({
      'bookingId': bookingId,
      'trackingStatus': 'on_the_way',
      ...data,
    });
  }
}
