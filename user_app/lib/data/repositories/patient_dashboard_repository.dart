import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/patient_booking_model.dart';
import '../models/patient_user_model.dart';
import '../services/dio_service.dart';

class PatientDashboardRepository {
  PatientDashboardRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<PatientBookingsResponse> fetchBookings() async {
    try {
      final response = await _dio.get(AppConstants.endpointPatientBookings);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return PatientBookingsResponse.fromJson(data);
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
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
}
