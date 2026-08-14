import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response_model.dart';
import '../services/dio_service.dart';

class LabPrescriptionQuotation {
  const LabPrescriptionQuotation({
    required this.id,
    required this.status,
    required this.paymentStatus,
    this.quotedAmount,
    this.labNotes,
    this.estimatedCompletionTime,
    this.rejectionReason,
  });

  final String id;
  final String status;
  final String paymentStatus;
  final double? quotedAmount;
  final String? labNotes;
  final String? estimatedCompletionTime;
  final String? rejectionReason;

  factory LabPrescriptionQuotation.fromJson(Map<String, dynamic> json) {
    return LabPrescriptionQuotation(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
      quotedAmount: (json['quotedAmount'] as num?)?.toDouble(),
      labNotes: json['labNotes']?.toString(),
      estimatedCompletionTime: json['estimatedCompletionTime']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}

class LabPrescriptionRequestItem {
  const LabPrescriptionRequestItem({
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.chatEnabled,
    required this.prescriptionFileUrl,
    required this.prescriptionFileType,
    this.patientName,
    this.prescriptionFileName,
    this.requestedTests = const [],
    this.notes,
    this.myQuotation,
    this.selectedLabId,
    this.createdAt,
  });

  final String id;
  final String? patientName;
  final String status;
  final String paymentStatus;
  final bool chatEnabled;
  final String prescriptionFileUrl;
  final String prescriptionFileType;
  final String? prescriptionFileName;
  final List<String> requestedTests;
  final String? notes;
  final LabPrescriptionQuotation? myQuotation;
  final String? selectedLabId;
  final DateTime? createdAt;

  bool get canChat =>
      chatEnabled && paymentStatus == 'PAID' && selectedLabId != null;

  factory LabPrescriptionRequestItem.fromJson(Map<String, dynamic> json) {
    final tests = (json['requestedTests'] as List?)
            ?.map((e) {
              if (e is Map) return e['name']?.toString() ?? '';
              return e.toString();
            })
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    return LabPrescriptionRequestItem(
      id: json['id']?.toString() ?? '',
      patientName: json['patientName']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
      chatEnabled: json['chatEnabled'] == true,
      prescriptionFileUrl: json['prescriptionFileUrl']?.toString() ?? '',
      prescriptionFileType: json['prescriptionFileType']?.toString() ?? '',
      prescriptionFileName: json['prescriptionFileName']?.toString(),
      requestedTests: tests,
      notes: json['notes']?.toString(),
      myQuotation: json['myQuotation'] is Map
          ? LabPrescriptionQuotation.fromJson(
              Map<String, dynamic>.from(json['myQuotation'] as Map),
            )
          : null,
      selectedLabId: json['selectedLabId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class LabPrescriptionRepository {
  LabPrescriptionRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<ApiResponse<List<LabPrescriptionRequestItem>>> listInbox() async {
    try {
      final response =
          await _dio.get(AppConstants.endpointLabPrescriptionInbox);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      return ApiResponse(
        success: true,
        data: data
            .whereType<Map>()
            .map((e) => LabPrescriptionRequestItem.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList(),
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, error: _msg(e));
    }
  }

  Future<ApiResponse<LabPrescriptionRequestItem>> getById(String id) async {
    try {
      final response =
          await _dio.get(AppConstants.endpointLabPrescriptionById(id));
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return ApiResponse(
          success: false,
          error: body['error']?.toString() ?? 'Failed to load',
        );
      }
      return ApiResponse(
        success: true,
        data: LabPrescriptionRequestItem.fromJson(
          Map<String, dynamic>.from(body['data'] as Map? ?? {}),
        ),
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, error: _msg(e));
    }
  }

  Future<ApiResponse<LabPrescriptionQuotation>> submitQuote({
    required String requestId,
    required double quotedAmount,
    String? estimatedCompletionTime,
    String? labNotes,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointLabPrescriptionQuote(requestId),
        data: {
          'quotedAmount': quotedAmount,
          if (estimatedCompletionTime != null)
            'estimatedCompletionTime': estimatedCompletionTime,
          if (labNotes != null) 'labNotes': labNotes,
        },
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return ApiResponse(
          success: false,
          error: body['error']?.toString() ?? 'Failed to submit',
        );
      }
      return ApiResponse(
        success: true,
        data: LabPrescriptionQuotation.fromJson(
          Map<String, dynamic>.from(body['data'] as Map? ?? {}),
        ),
        message: body['message']?.toString(),
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, error: _msg(e));
    }
  }

  Future<ApiResponse<LabPrescriptionQuotation>> reject({
    required String requestId,
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointLabPrescriptionReject(requestId),
        data: {if (reason != null) 'reason': reason},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return ApiResponse(
          success: false,
          error: body['error']?.toString() ?? 'Failed to reject',
        );
      }
      return ApiResponse(
        success: true,
        data: LabPrescriptionQuotation.fromJson(
          Map<String, dynamic>.from(body['data'] as Map? ?? {}),
        ),
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, error: _msg(e));
    }
  }

  String _msg(DioException error) {
    if (error.type == DioExceptionType.badResponse) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return (data['error'] ?? data['message'] ?? 'Request failed').toString();
      }
    }
    return AppConstants.errorSomethingWentWrong;
  }
}