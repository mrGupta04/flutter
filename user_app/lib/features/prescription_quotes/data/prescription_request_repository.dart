import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/api_response_model.dart';
import '../../../../data/services/dio_service.dart';
import 'models/prescription_request_model.dart';

class PrescriptionUploadResult {
  const PrescriptionUploadResult({
    required this.prescriptionFileUrl,
    required this.prescriptionFileType,
    this.prescriptionFileName,
    this.size,
  });

  final String prescriptionFileUrl;
  final String prescriptionFileType;
  final String? prescriptionFileName;
  final int? size;
}

class PrescriptionRequestRepository {
  PrescriptionRequestRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  static const maxLabs = 4;
  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

  Future<ApiResponse<PrescriptionUploadResult>> uploadPrescription({
    String? filePath,
    Uint8List? bytes,
    required String filename,
  }) async {
    try {
      final ext = filename.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(ext)) {
        return ApiResponse(
          success: false,
          error:
              'Invalid prescription format. Allowed: JPG, JPEG, PNG, PDF.',
        );
      }
      if (bytes != null && bytes.isEmpty) {
        return ApiResponse(
          success: false,
          error: 'Uploaded prescription file is empty',
        );
      }

      final response = await _dio.uploadFile(
        AppConstants.endpointPrescriptionUpload,
        filePath: filePath,
        bytes: bytes,
        filename: filename,
        fieldName: 'prescription',
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return ApiResponse(
          success: false,
          error: body['error']?.toString() ?? 'Upload failed',
        );
      }
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: true,
        message: body['message']?.toString(),
        data: PrescriptionUploadResult(
          prescriptionFileUrl: data['prescriptionFileUrl']?.toString() ?? '',
          prescriptionFileType: data['prescriptionFileType']?.toString() ?? ext,
          prescriptionFileName: data['prescriptionFileName']?.toString(),
          size: (data['size'] as num?)?.toInt(),
        ),
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, error: _messageFromDio(e));
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<PrescriptionRequestModel>> createRequest({
    required String prescriptionFileUrl,
    required String prescriptionFileType,
    String? prescriptionFileName,
    required List<String> labIds,
    List<Map<String, String>>? requestedTests,
    String? notes,
    Map<String, double>? distanceByLabId,
  }) async {
    try {
      if (labIds.length > maxLabs) {
        return ApiResponse(
          success: false,
          error:
              'You can send a prescription request to a maximum of 4 labs.',
        );
      }
      final response = await _dio.post(
        AppConstants.endpointPrescriptionRequest,
        data: {
          'prescriptionFileUrl': prescriptionFileUrl,
          'prescriptionFileType': prescriptionFileType,
          if (prescriptionFileName != null)
            'prescriptionFileName': prescriptionFileName,
          'labIds': labIds,
          if (requestedTests != null) 'requestedTests': requestedTests,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (distanceByLabId != null) 'distanceByLabId': distanceByLabId,
        },
      );
      return _parseRequest(response);
    } on DioException catch (e) {
      return ApiResponse(success: false, error: _messageFromDio(e));
    }
  }

  Future<ApiResponse<List<PrescriptionRequestModel>>> listMyRequests() async {
    try {
      final response =
          await _dio.get(AppConstants.endpointPrescriptionMyRequests);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      final list = data
          .whereType<Map>()
          .map((e) => PrescriptionRequestModel.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
      return ApiResponse(success: true, data: list);
    } on DioException catch (e) {
      return ApiResponse(success: false, error: _messageFromDio(e));
    }
  }

  Future<ApiResponse<PrescriptionRequestModel>> getById(String id) async {
    try {
      final response =
          await _dio.get(AppConstants.endpointPrescriptionById(id));
      return _parseRequest(response);
    } on DioException catch (e) {
      return ApiResponse(success: false, error: _messageFromDio(e));
    }
  }

  Future<ApiResponse<PrescriptionRequestModel>> selectLab({
    required String requestId,
    required String quotationId,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointPrescriptionSelectLab(requestId),
        data: {'quotationId': quotationId},
      );
      return _parseRequest(response);
    } on DioException catch (e) {
      return ApiResponse(success: false, error: _messageFromDio(e));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createPaymentOrder(
    String requestId,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointPrescriptionPaymentCreate(requestId),
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        return ApiResponse(
          success: false,
          error: body['error']?.toString() ?? 'Could not start payment',
        );
      }
      return ApiResponse(
        success: true,
        data: Map<String, dynamic>.from(body['data'] as Map? ?? {}),
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, error: _messageFromDio(e));
    }
  }

  Future<ApiResponse<PrescriptionRequestModel>> verifyPayment({
    required String requestId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointPrescriptionPaymentVerify(requestId),
        data: {
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      );
      return _parseRequest(response);
    } on DioException catch (e) {
      return ApiResponse(success: false, error: _messageFromDio(e));
    }
  }

  Future<ApiResponse<PrescriptionRequestModel>> markPaymentFailed(
    String requestId,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointPrescriptionPaymentFailed(requestId),
      );
      return _parseRequest(response);
    } on DioException catch (e) {
      return ApiResponse(success: false, error: _messageFromDio(e));
    }
  }

  ApiResponse<PrescriptionRequestModel> _parseRequest(Response response) {
    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      return ApiResponse(
        success: false,
        error: body['error']?.toString() ?? 'Request failed',
      );
    }
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return ApiResponse(
      success: true,
      message: body['message']?.toString(),
      data: PrescriptionRequestModel.fromJson(data),
    );
  }

  String _messageFromDio(DioException error) {
    if (error.type == DioExceptionType.badResponse) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return (data['error'] ?? data['message'] ?? 'Request failed').toString();
      }
    }
    if (error.type == DioExceptionType.connectionError) {
      return AppConstants.errorNetworkException;
    }
    return AppConstants.errorSomethingWentWrong;
  }
}