import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/models.dart';
import 'mock_database.dart';

/// Mock API handler for Dio service
class MockApi {
  MockApi._();

  static final MockDatabase _db = MockDatabase.instance;

  static Future<Response> handleRequest({
    required String path,
    required String method,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    _db.seedIfEmpty();

    await Future.delayed(const Duration(milliseconds: 500));

    if (_matches(path, AppConstants.endpointDoctorLogin) && method == 'POST') {
      final doctor = _db.latestDoctor ?? _db.getDoctorById('mock-doctor-1');
      return _ok(
        path,
        method,
        {
          'success': true,
          'message': 'Login successful',
          'statusCode': 200,
          'token': 'mock-doctor-token',
          'data': doctor?.toJson() ?? {'id': 'mock-doctor-1', 'firstName': 'Demo', 'email': data?['email']},
        },
      );
    }

    if (_matches(path, AppConstants.endpointRegisterDoctor) && method == 'POST') {
      final doctor = DoctorModel.fromJson(data ?? {});
      final created = _db.registerDoctor(doctor);
      return _ok(
        path,
        method,
        {
          'success': true,
          'message': 'Doctor registered successfully',
          'statusCode': 200,
          'data': created.toJson(),
        },
      );
    }

    if (_matches(path, AppConstants.endpointDoctorEmailSendOtp) && method == 'POST') {
      return _ok(
        path,
        method,
        {
          'success': true,
          'message': 'Verification code sent (mock)',
          'statusCode': 200,
          'data': {
            'maskedEmail': 'de***@example.com',
            'expiresInSeconds': 600,
          },
        },
      );
    }

    if (_matches(path, AppConstants.endpointDoctorEmailVerifyOtp) && method == 'POST') {
      final otp = data?['otp'] as String? ?? '';
      if (otp != '123456') {
        return _error(path, method, 'Invalid verification code', 400);
      }
      return _ok(
        path,
        method,
        {
          'success': true,
          'message': 'Email verified successfully',
          'statusCode': 200,
          'data': {
            'verified': true,
            'email': data?['email'],
          },
        },
      );
    }

    if (_matches(path, AppConstants.endpointGetProfile) && method == 'GET') {
      final doctorId = queryParameters?['doctorId'] as String?;
      final doctor = doctorId != null
          ? _db.getDoctorById(doctorId)
          : _db.latestDoctor;
      return _ok(
        path,
        method,
        {
          'success': true,
          'statusCode': 200,
          'data': doctor?.toJson(),
        },
      );
    }

    if (_matches(path, AppConstants.endpointUpdateProfile) && method == 'PUT') {
      final doctor = DoctorModel.fromJson(data ?? {});
      final updated = _db.updateDoctor(doctor);
      return _ok(
        path,
        method,
        {
          'success': true,
          'message': 'Profile updated successfully',
          'statusCode': 200,
          'data': updated.toJson(),
        },
      );
    }

    return _error(path, method, 'Endpoint not found', 404);
  }

  static Future<Response> handleUpload({
    required String path,
    required String filePath,
    required Map<String, String> fields,
  }) async {
    _db.seedIfEmpty();

    await Future.delayed(const Duration(milliseconds: 800));

    if (path == AppConstants.endpointUploadDocument) {
      final doctorId = fields['doctorId'] ?? _db.latestDoctor?.id ?? '';
      final documentTypeValue = fields['documentType'];
      final documentType = _parseDocumentType(documentTypeValue) ??
          DocumentType.medicalLicense;
        final fileName = _fileNameFromPath(filePath);
      final mimeType = _guessMimeType(fileName);
        const fileSize = 1024 * 500;

      final document = _db.addDocument(
        doctorId: doctorId,
        documentType: documentType,
        fileName: fileName,
        mimeType: mimeType,
        fileSize: fileSize,
      );

      return _ok(
        path,
        'POST',
        {
          'success': true,
          'message': 'Document uploaded successfully',
          'statusCode': 200,
          'data': document.toJson(),
        },
      );
    }

    return _error(path, 'POST', 'Endpoint not found', 404);
  }

  static bool _matches(String requestPath, String endpoint) {
    String norm(String p) => p.startsWith('/') ? p.substring(1) : p;
    return norm(requestPath) == norm(endpoint);
  }

  static Response _ok(String path, String method, Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: path, method: method),
      data: data,
      statusCode: data['statusCode'] as int? ?? 200,
    );
  }

  static Response _error(
    String path,
    String method,
    String message,
    int statusCode,
  ) {
    return Response(
      requestOptions: RequestOptions(path: path, method: method),
      data: {
        'success': false,
        'error': message,
        'statusCode': statusCode,
      },
      statusCode: statusCode,
    );
  }

  static DocumentType? _parseDocumentType(String? value) {
    switch (value) {
      case 'medical_license':
        return DocumentType.medicalLicense;
      case 'government_id':
        return DocumentType.governmentId;
      case 'degree_certificate':
        return DocumentType.degreeCertificate;
      case 'clinic_proof':
        return DocumentType.clinicProof;
      case 'cancelled_cheque':
        return DocumentType.cancelledCheque;
      case 'aadhaar_card':
        return DocumentType.aadhaarCard;
      case 'hospital_photo_1':
        return DocumentType.hospitalPhoto1;
      case 'hospital_photo_2':
        return DocumentType.hospitalPhoto2;
      case 'hospital_photo_3':
        return DocumentType.hospitalPhoto3;
      case 'hospital_photo_4':
        return DocumentType.hospitalPhoto4;
      case 'hospital_photo_5':
        return DocumentType.hospitalPhoto5;
      default:
        return null;
    }
  }

  static String _guessMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      return 'image/$extension';
    }
    if (extension == 'pdf') return 'application/pdf';
    return 'application/octet-stream';
  }

  static String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isNotEmpty ? segments.last : 'document.pdf';
  }
}
