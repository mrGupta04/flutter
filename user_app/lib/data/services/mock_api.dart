import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/models.dart';
import 'mock_database.dart';

/// Mock API handler for Dio service
class MockApi {
  MockApi._();

  static final MockDatabase _db = MockDatabase.instance;

  static bool _pathMatches(String path, String endpoint) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    final expected =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return normalized == expected;
  }

  static Future<Response> handleRequest({
    required String path,
    required String method,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    _db.seedIfEmpty();

    await Future.delayed(const Duration(milliseconds: 500));

    if (path == AppConstants.endpointGetProfile && method == 'GET') {
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

    if (path == AppConstants.endpointPatientRegister && method == 'POST') {
      return _ok(
        path,
        method,
        {
          'success': true,
          'message': 'Account created successfully',
          'statusCode': 201,
          'token': 'mock-patient-token',
          'data': {
            'id': 'mock-patient-1',
            'firstName': data?['firstName'] ?? 'Demo',
            'lastName': data?['lastName'],
            'email': data?['email'] ?? 'patient@example.com',
            'mobileNumber': data?['mobileNumber'] ?? '9876543210',
            'age': int.tryParse('${data?['age']}') ?? 30,
            'gender': data?['gender'] ?? 'Male',
            'aadhaarLast4': '1234',
            'profilePicture': 'https://i.pravatar.cc/150?img=12',
            'aadhaarCardUrl': 'https://example.com/aadhaar.jpg',
          },
        },
      );
    }

    if (path == AppConstants.endpointPatientLogin && method == 'POST') {
      return _ok(
        path,
        method,
        {
          'success': true,
          'message': 'Login successful',
          'statusCode': 200,
          'token': 'mock-patient-token',
          'data': {
            'id': 'mock-patient-1',
            'firstName': 'Demo',
            'lastName': 'Patient',
            'email': data?['email'] ?? 'patient@example.com',
            'mobileNumber': '9876543210',
            'age': 30,
            'gender': 'Male',
            'aadhaarLast4': '1234',
            'profilePicture': 'https://i.pravatar.cc/150?img=12',
          },
        },
      );
    }

    if (path == AppConstants.endpointPatientProfile &&
        (method == 'GET' || method == 'PUT')) {
      return _ok(
        path,
        method,
        {
          'success': true,
          'statusCode': 200,
          'message': method == 'PUT' ? 'Profile updated successfully' : null,
          'data': {
            'id': 'mock-patient-1',
            'firstName': data?['firstName'] ?? 'Demo',
            'lastName': data?['lastName'] ?? 'Patient',
            'email': data?['email'] ?? 'patient@example.com',
            'mobileNumber': data?['mobileNumber'] ?? '9876543210',
            'age': int.tryParse('${data?['age']}') ?? 30,
            'gender': data?['gender'] ?? 'Male',
            'aadhaarLast4': '1234',
            'profilePicture': 'https://i.pravatar.cc/150?img=12',
            'aadhaarCardUrl': 'https://example.com/aadhaar.jpg',
          },
        },
      );
    }

    if (path == AppConstants.endpointVerifiedDoctors && method == 'GET') {
      final consultationType = queryParameters?['consultationType'] as String?;
      final doctors = _db.getVerifiedDoctors(consultationType: consultationType);
      return _ok(
        path,
        method,
        {
          'success': true,
          'statusCode': 200,
          'data': doctors.map((d) => d.toJson()).toList(),
        },
      );
    }

    if (path == AppConstants.endpointDoctorBookableSlots && method == 'GET') {
      final doctorId = queryParameters?['doctorId'] as String? ?? '';
      final consultationType =
          queryParameters?['type'] as String? ?? 'online_consult';
      try {
        final data = _db.getBookableSlots(
          doctorId: doctorId,
          consultationType: consultationType,
        );
        return _ok(path, method, {'success': true, 'statusCode': 200, 'data': data});
      } catch (e) {
        return _error(path, method, e.toString(), 404);
      }
    }

    if (path == AppConstants.endpointDoctorSlotHold && method == 'POST') {
      try {
        final doctorId = data?['doctorId'] as String? ?? '';
        final consultationType =
            data?['consultationType'] as String? ?? 'online_consult';
        final dayOfWeek = (data?['dayOfWeek'] as num?)?.toInt() ?? 0;
        final startHour = (data?['startHour'] as num?)?.toInt() ?? 8;
        final slotStart = DateTime.tryParse(data?['slotStart'] as String? ?? '') ??
            DateTime.now().add(const Duration(days: 1));
        final hold = _db.holdSlot(
          doctorId: doctorId,
          consultationType: consultationType,
          dayOfWeek: dayOfWeek,
          startHour: startHour,
          slotStart: slotStart,
          holdId: data?['holdId'] as String?,
        );
        return _ok(
          path,
          method,
          {
            'success': true,
            'statusCode': 201,
            'message': 'Slot reserved',
            'data': hold,
          },
        );
      } catch (e) {
        return _error(path, method, e.toString(), 409);
      }
    }

    if (path.startsWith('${AppConstants.endpointDoctorSlotHold}/') &&
        method == 'DELETE') {
      final holdId = path.split('/').last;
      _db.releaseSlotHold(holdId);
      return _ok(
        path,
        method,
        {
          'success': true,
          'statusCode': 200,
          'message': 'Slot hold released',
          'data': {'released': true},
        },
      );
    }

    if (path == AppConstants.endpointOnlineConsultBook && method == 'POST') {
      final doctorId = data?['doctorId'] as String? ?? '';
      try {
        final booking = _db.createBooking(
          doctorId: doctorId,
          consultationType: 'online_consult',
          payload: data ?? {},
        );
        return _ok(
          path,
          method,
          {
            'success': true,
            'message': 'Online consultation booked',
            'statusCode': 201,
            'data': booking,
          },
        );
      } catch (e) {
        return _error(path, method, e.toString(), 409);
      }
    }

    if (path == AppConstants.endpointHospitalVisitBook && method == 'POST') {
      final doctorId = data?['doctorId'] as String? ?? '';
      try {
        final booking = _db.createBooking(
          doctorId: doctorId,
          consultationType: 'visit_site',
          payload: data ?? {},
        );
        return _ok(
          path,
          method,
          {
            'success': true,
            'message': 'Hospital visit booked',
            'statusCode': 201,
            'data': booking,
          },
        );
      } catch (e) {
        return _error(path, method, e.toString(), 409);
      }
    }

    if (path == AppConstants.endpointHomeVisitBook && method == 'POST') {
      final doctorId = data?['doctorId'] as String? ?? '';
      try {
        final booking = _db.createBooking(
          doctorId: doctorId,
          consultationType: 'book_home',
          payload: data ?? {},
        );
        return _ok(
          path,
          method,
          {
            'success': true,
            'message': 'Home visit booked',
            'statusCode': 201,
            'data': booking,
          },
        );
      } catch (e) {
        return _error(path, method, e.toString(), 409);
      }
    }

    if (_pathMatches(path, AppConstants.endpointPatientBookings) &&
        method == 'GET') {
      final now = DateTime.now();
      final upcoming = now.add(const Duration(days: 2));
      final past = now.subtract(const Duration(days: 3));
      return _ok(
        path,
        method,
        {
          'success': true,
          'statusCode': 200,
          'data': {
            'stats': {'total': 2, 'upcoming': 1, 'past': 1},
            'bookings': [
              {
                'id': 'mock-booking-1',
                'doctorId': 'mock-doctor-1',
                'doctorName': 'Dr. Demo Sharma',
                'consultationType': 'online_consult',
                'typeLabel': 'Online consult',
                'slotStart': upcoming.toIso8601String(),
                'slotEnd': upcoming.add(const Duration(hours: 1)).toIso8601String(),
                'label': '10:00 AM – 11:00 AM',
                'consultationFee': 500,
                'status': 'confirmed',
                'isUpcoming': true,
              },
              {
                'id': 'mock-booking-2',
                'doctorId': 'mock-doctor-2',
                'doctorName': 'Dr. Priya Patel',
                'consultationType': 'visit_site',
                'typeLabel': 'Clinic visit',
                'slotStart': upcoming.toIso8601String(),
                'slotEnd': upcoming.add(const Duration(hours: 1)).toIso8601String(),
                'label': '2:00 PM – 3:00 PM',
                'consultationFee': 800,
                'status': 'confirmed',
                'clinicName': 'City Care Clinic',
                'clinicAddress': 'MG Road, Mumbai',
                'appointmentCode': '4829',
                'isUpcoming': true,
              },
            ],
          },
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

    return _error(path, 'POST', 'Endpoint not found', 404);
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
