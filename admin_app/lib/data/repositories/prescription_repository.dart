import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/prescription_model.dart';
import '../services/dio_service.dart';

class PrescriptionRepository {
  PrescriptionRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<PrescriptionContextModel> fetchContext(String bookingId) async {
    try {
      final response = await _dio.get(
        AppConstants.endpointConsultationPrescriptionContext(bookingId),
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return PrescriptionContextModel.fromJson(data);
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<PrescriptionSaveResult> savePrescription({
    required String bookingId,
    String? diagnosis,
    required List<PrescriptionMedicineModel> medicines,
    required List<PrescriptionTestModel> tests,
    String? advice,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointConsultationPrescription(bookingId),
        data: {
          if (diagnosis != null && diagnosis.isNotEmpty) 'diagnosis': diagnosis,
          'medicines': medicines.map((m) => m.toJson()).toList(),
          'tests': tests.map((t) => t.toJson()).toList(),
          if (advice != null && advice.isNotEmpty) 'advice': advice,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return PrescriptionSaveResult.fromJson(data);
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  String _messageFromDio(DioException error) {
    if (error.type == DioExceptionType.badResponse) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return (data['error'] ?? data['message'] ?? 'Request failed')
            as String;
      }
    }
    if (error.type == DioExceptionType.connectionError) {
      return AppConstants.errorNetworkException;
    }
    return AppConstants.errorSomethingWentWrong;
  }
}
