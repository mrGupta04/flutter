import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/previous_report_model.dart';
import '../services/dio_service.dart';

class BookingReportsRepository {
  BookingReportsRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<PreviousReportModel> uploadPreviousReport({
    required String bookingId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final response = await _dio.uploadFile(
        AppConstants.endpointPatientBookingPreviousReport(bookingId),
        bytes: bytes,
        filename: fileName,
        fieldName: 'file',
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return PreviousReportModel.fromJson(data);
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  String _messageFromDio(DioException error) {
    if (error.type == DioExceptionType.badResponse) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return (data['error'] ?? data['message'] ?? 'Upload failed') as String;
      }
    }
    if (error.type == DioExceptionType.connectionError) {
      return AppConstants.errorNetworkException;
    }
    return AppConstants.errorSomethingWentWrong;
  }
}
