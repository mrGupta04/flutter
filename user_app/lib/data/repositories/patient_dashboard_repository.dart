import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/nursing_report_model.dart';
import '../models/patient_booking_model.dart';
import '../models/patient_user_model.dart';
import '../services/dio_service.dart';

class PatientDashboardRepository {
  PatientDashboardRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<PatientBookingsResponse> fetchBookings({
    String scope = 'current',
    int page = 1,
    int limit = 20,
    String status = 'all',
    String? q,
    PatientBookingCategory? service,
  }) async {
    try {
      final response = await _dio.get(
        AppConstants.endpointPatientBookings,
        queryParameters: {
          'scope': scope,
          'page': page,
          'limit': limit,
          if (status != 'all') 'status': status,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (service?.apiServiceType != null) 'serviceType': service!.apiServiceType,
          if (service?.apiConsultationType != null)
            'consultationType': service!.apiConsultationType,
        },
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(
          (body['error'] ?? body['message'] ?? 'Failed to load bookings')
              as String,
        );
      }

      return PatientBookingsResponse.fromJson(_extractBookingsPayload(body));
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  /// Supports `{ data: { bookings, stats } }` and accidental double nesting.
  static Map<String, dynamic> _extractBookingsPayload(
    Map<String, dynamic> body,
  ) {
    dynamic payload = body['data'];

    if (payload is Map<String, dynamic>) {
      if (payload['bookings'] is List) {
        if (payload['pagination'] == null && body['pagination'] is Map) {
          return {
            ...payload,
            'pagination': body['pagination'],
          };
        }
        return payload;
      }
      final nested = payload['data'];
      if (nested is Map<String, dynamic> && nested['bookings'] is List) {
        return nested;
      }
    }

    if (body['bookings'] is List) {
      return {
        'bookings': body['bookings'],
        'stats': body['stats'] ?? <String, dynamic>{},
      };
    }

    return <String, dynamic>{};
  }

  Future<PatientUserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? mobileNumber,
    int? age,
    String? gender,
    String? aadhaarNumber,
    String? password,
    Uint8List? profilePictureBytes,
    String? profilePictureFileName,
    Uint8List? aadhaarCardBytes,
    String? aadhaarCardFileName,
    String? dateOfBirth,
    String? bloodGroup,
    String? addressLine,
    String? city,
    String? addressState,
    String? pincode,
    bool removeProfilePicture = false,
  }) async {
    try {
      final formData = FormData();
      void addField(String key, String value) {
        formData.fields.add(MapEntry(key, value));
      }

      if (firstName != null) addField('firstName', firstName);
      if (lastName != null) addField('lastName', lastName);
      if (email != null) addField('email', email);
      if (mobileNumber != null) addField('mobileNumber', mobileNumber);
      if (age != null) addField('age', age.toString());
      if (gender != null) addField('gender', gender);
      if (aadhaarNumber != null) addField('aadhaarNumber', aadhaarNumber);
      if (password != null && password.isNotEmpty) {
        addField('password', password);
      }
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        addField('dateOfBirth', dateOfBirth);
      }
      if (bloodGroup != null) addField('bloodGroup', bloodGroup);
      if (addressLine != null) addField('addressLine', addressLine);
      if (city != null) addField('city', city);
      if (addressState != null) addField('state', addressState);
      if (pincode != null) addField('pincode', pincode);
      if (removeProfilePicture) addField('removeProfilePicture', 'true');

      if (profilePictureBytes != null) {
        formData.files.add(
          MapEntry(
            'profilePicture',
            MultipartFile.fromBytes(
              profilePictureBytes,
              filename: profilePictureFileName ?? 'profile.jpg',
            ),
          ),
        );
      }
      if (aadhaarCardBytes != null) {
        formData.files.add(
          MapEntry(
            'aadhaarCard',
            MultipartFile.fromBytes(
              aadhaarCardBytes,
              filename: aadhaarCardFileName ?? 'aadhaar.jpg',
            ),
          ),
        );
      }

      final response = await _dio.putFormData(
        AppConstants.endpointPatientProfile,
        data: formData,
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return PatientUserModel.fromJson(data);
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

  Future<PatientBookingModel?> fetchBookingById(String bookingId) async {
    try {
      final response = await _dio.get(
        AppConstants.endpointPatientBooking(bookingId),
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return PatientBookingModel.fromJson(data);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<String?> fetchReceiptPdfUrl(String bookingId) async {
    try {
      final response = await _dio.get(
        AppConstants.endpointPatientBookingReceipt(bookingId),
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(
          (body['error'] ?? body['message'] ?? 'Receipt unavailable') as String,
        );
      }
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        final url = data['pdfUrl'] as String?;
        return url?.trim().isNotEmpty == true ? url!.trim() : null;
      }
      return null;
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<String?> fetchPrescriptionPdfUrl(String bookingId) async {
    try {
      final response = await _dio.get(
        AppConstants.endpointConsultationPrescription(bookingId),
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == false) {
        return null;
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) return null;
      final pdfUrl = data['pdfUrl'] as String?;
      return pdfUrl?.trim().isNotEmpty == true ? pdfUrl!.trim() : null;
    } on DioException {
      return null;
    }
  }

  Future<List<NursingReportModel>> fetchNursingReports() async {
    try {
      final response = await _dio.get(AppConstants.endpointPatientNursingReports);
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(
          (body['error'] ?? body['message'] ?? 'Failed to load nursing reports')
              as String,
        );
      }
      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => NursingReportModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<String?> fetchNursingReportPdfUrl(String bookingId) async {
    try {
      final response = await _dio.get(
        AppConstants.endpointPatientNursingReport(bookingId),
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == false) return null;
      final data = body['data'];
      if (data is! Map<String, dynamic>) return null;
      final note = data['note'];
      if (note is! Map<String, dynamic>) return null;
      final pdfUrl = note['pdfUrl'] as String?;
      return pdfUrl?.trim().isNotEmpty == true ? pdfUrl!.trim() : null;
    } on DioException {
      return null;
    }
  }

  Future<String> regenerateClinicOtp(String bookingId) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointPatientBookingVerificationRegen(bookingId),
        data: const {},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(
          (body['error'] ?? body['message'] ?? 'Could not generate a new code')
              as String,
        );
      }
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        final code = data['appointmentCode'] as String?;
        if (code != null && code.isNotEmpty) return code;
      }
      throw Exception('Could not generate a new code');
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }
}
