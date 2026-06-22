import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/doctor_availability_constants.dart';
import '../models/models.dart';

/// In-memory mock database for demo purposes
class MockDatabase {
  MockDatabase._internal();

  static final MockDatabase instance = MockDatabase._internal();

  final Uuid _uuid = const Uuid();
  final List<DoctorModel> _doctors = [];
  final Map<String, List<DoctorDocumentModel>> _documentsByDoctor = {};
  final List<Map<String, dynamic>> _consultationBookings = [];

  final List<SpecializationModel> _specializations = const [
    SpecializationModel(id: 'spec_1', name: 'Cardiology'),
    SpecializationModel(id: 'spec_2', name: 'Dermatology'),
    SpecializationModel(id: 'spec_3', name: 'Pediatrics'),
    SpecializationModel(id: 'spec_4', name: 'Orthopedics'),
    SpecializationModel(id: 'spec_5', name: 'Neurology'),
    SpecializationModel(id: 'spec_6', name: 'General Medicine'),
    SpecializationModel(id: 'spec_7', name: 'Gynecology'),
    SpecializationModel(id: 'spec_8', name: 'ENT'),
  ];

  List<SpecializationModel> getSpecializations() => _specializations;

  DoctorModel? get latestDoctor => _doctors.isEmpty ? null : _doctors.last;

  void seedIfEmpty() {
    if (_doctors.isNotEmpty) return;

    for (var i = 0; i < 5; i++) {
      _doctors.add(
        DoctorModel(
          id: 'doc_seed_$i',
          firstName: 'Dr. Alex',
          lastName: 'Verma $i',
          email: 'doctor$i@example.com',
          mobileNumber: '98765432${i.toString().padLeft(2, '0')}',
          profilePicture: AppConstants.mockImageUrl,
          medicalRegistrationNumber: 'MR/2024/00$i',
          medicalCouncilName: 'Medical Council of India',
          specializations: const ['Cardiology'],
          yearsOfExperience: 3 + i,
          clinicName: 'Health Clinic $i',
          address: '${12 + i} Medical Lane, Connaught Place',
          city: 'Delhi',
          state: 'Delhi',
          pincode: '11000${i + 1}',
          consultationFee: 300 + (i * 100),
          onlineConsultFee: 250 + (i * 80),
          homeVisitFee: 400 + (i * 100),
          visitSiteFee: 300 + (i * 100),
          offersOnlineConsult: i % 3 != 1,
          offersBookHome: i % 3 != 2,
          offersVisitSite: i % 3 != 0,
          qualification: 'MBBS',
          isLiveNow: i == 2,
          verificationStatus: switch (i % 4) {
              0 => VerificationStatus.pending,
              1 => VerificationStatus.underReview,
              2 => VerificationStatus.verified,
              _ => VerificationStatus.rejected,
            },
          createdAt: DateTime.now().subtract(Duration(days: i + 1)),
          updatedAt: DateTime.now().subtract(Duration(days: i)),
        ),
      );
    }
  }

  DoctorModel registerDoctor(DoctorModel doctor) {
    final created = doctor.copyWith(
      id: doctor.id ?? 'doc_${_uuid.v4()}',
      verificationStatus: VerificationStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _doctors.add(created);
    return created;
  }

  DoctorModel updateDoctor(DoctorModel doctor) {
    final index = _doctors.indexWhere((d) => d.id == doctor.id);
    if (index == -1) {
      _doctors.add(doctor);
      return doctor;
    }
    final updated = doctor.copyWith(updatedAt: DateTime.now());
    _doctors[index] = updated;
    return updated;
  }

  DoctorModel? getDoctorById(String doctorId) {
    return _doctors.firstWhere(
      (d) => d.id == doctorId,
      orElse: () => DoctorModel(id: doctorId),
    );
  }

  List<DoctorModel> getDoctors({String? status}) {
    if (status == null || status.isEmpty) {
      return List<DoctorModel>.from(_doctors);
    }
    return _doctors
        .where(
          (doctor) =>
              _statusToString(doctor.verificationStatus) == status,
        )
        .toList();
  }

  DoctorDocumentModel addDocument({
    required String doctorId,
    required DocumentType documentType,
    required String fileName,
    required String mimeType,
    required int fileSize,
  }) {
    final document = DoctorDocumentModel(
      id: 'doc_${_uuid.v4()}',
      doctorId: doctorId,
      documentType: documentType,
      fileUrl: 'https://example.com/documents/${_uuid.v4()}',
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      status: DocumentStatus.pending,
      uploadedAt: DateTime.now(),
    );
    final list = _documentsByDoctor.putIfAbsent(doctorId, () => []);
    list.add(document);
    return document;
  }

  List<DoctorDocumentModel> getDocuments(String doctorId) {
    return List<DoctorDocumentModel>.from(
      _documentsByDoctor[doctorId] ?? [],
    );
  }

  List<DoctorModel> getVerifiedDoctors({String? consultationType}) {
    var doctors = _doctors
        .where((d) => d.verificationStatus == VerificationStatus.verified)
        .toList();
    if (consultationType == 'online_consult') {
      doctors = doctors.where((d) => d.offersOnlineConsult).toList();
    } else if (consultationType == 'visit_site') {
      doctors = doctors.where((d) => d.offersVisitSite).toList();
    } else if (consultationType == 'book_home') {
      doctors = doctors.where((d) => d.offersBookHome).toList();
    }
    return doctors;
  }

  DateTime _weekStart(DateTime reference) {
    final d = DateTime(reference.year, reference.month, reference.day);
    return d.subtract(Duration(days: d.weekday % 7));
  }

  DateTime _weekEnd(DateTime weekStart) {
    return DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 6,
      23,
      59,
      59,
      999,
    );
  }

  DateTime _slotStart(DateTime weekStart, int dayOfWeek, int startHour) {
    return DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + dayOfWeek,
      startHour,
    );
  }

  String _slotLabel(DateTime start, DateTime end) {
    String fmt(DateTime dt) {
      final hour = dt.hour;
      final suffix = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour % 12 == 0 ? 12 : hour % 12;
      return '$h12:00 $suffix';
    }
    return '${fmt(start)} – ${fmt(end)}';
  }

  Map<String, dynamic> getBookableSlots({
    required String doctorId,
    required String consultationType,
  }) {
    final doctor = getDoctorById(doctorId);
    if (doctor == null || doctor.id == null) {
      throw Exception('Doctor not found');
    }
    if (consultationType == 'visit_site' && !doctor.offersVisitSite) {
      throw Exception('This doctor does not offer hospital visits');
    }
    if (consultationType != 'visit_site' && !doctor.offersOnlineConsult) {
      throw Exception('This doctor does not offer online consultation');
    }

    final now = DateTime.now();
    final weekStart = _weekStart(now);
    final weekEnd = _weekEnd(weekStart);
    final bookedKeys = _consultationBookings
        .where(
          (b) =>
              b['doctorId'] == doctorId &&
              b['consultationType'] == consultationType &&
              _isActiveReservation(b),
        )
        .map((b) => '${b['dayOfWeek']}_${b['startHour']}')
        .toSet();

    final slots = <Map<String, dynamic>>[];
    for (var day = 1; day <= 5; day++) {
      for (
        var hour = DoctorAvailabilityConstants.slotStartHour + 1;
        hour <= DoctorAvailabilityConstants.slotEndHour;
        hour++
      ) {
        final key = '${day}_$hour';
        if (bookedKeys.contains(key)) continue;
        final slotStart = _slotStart(weekStart, day, hour);
        final slotEnd = slotStart.add(const Duration(hours: 1));
        if (!slotStart.isAfter(now)) continue;
        slots.add({
          'dayOfWeek': day,
          'startHour': hour,
          'slotStart': slotStart.toIso8601String(),
          'slotEnd': slotEnd.toIso8601String(),
          'label': _slotLabel(slotStart, slotEnd),
        });
      }
    }

    final data = <String, dynamic>{
      'doctorId': doctorId,
      'consultationType': consultationType,
      'weekStartDate': weekStart.toIso8601String(),
      'weekEndDate': weekEnd.toIso8601String(),
      'consultationFee': doctor.consultationFee,
      'slots': slots,
      'totalBookable': slots.length,
    };

    if (consultationType == 'visit_site') {
      data['clinicName'] = doctor.clinicName;
      data['clinicAddress'] = [
        doctor.address,
        doctor.city,
        doctor.state,
        doctor.pincode,
      ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');
      data['clinicCity'] = doctor.city;
      data['clinicState'] = doctor.state;
      data['clinicPincode'] = doctor.pincode;
    }

    return data;
  }

  bool _isActiveReservation(Map<String, dynamic> booking) {
    final status = booking['status'] as String? ?? '';
    if (status == 'confirmed') return true;
    if (status == 'held' || status == 'pending') {
      final expiresAt = DateTime.tryParse(
        booking['paymentExpiresAt'] as String? ?? '',
      );
      return expiresAt == null || expiresAt.isAfter(DateTime.now());
    }
    return false;
  }

  Map<String, dynamic> holdSlot({
    required String doctorId,
    required String consultationType,
    required int dayOfWeek,
    required int startHour,
    required DateTime slotStart,
    String? holdId,
  }) {
    if (holdId != null) {
      _consultationBookings.removeWhere(
        (b) => b['id'] == holdId && b['status'] == 'held',
      );
    }

    final key = '${dayOfWeek}_$startHour';
    final duplicate = _consultationBookings.any(
      (b) =>
          b['doctorId'] == doctorId &&
          b['consultationType'] == consultationType &&
          '${b['dayOfWeek']}_${b['startHour']}' == key &&
          _isActiveReservation(b),
    );
    if (duplicate) {
      throw Exception('This slot was just booked. Please choose another time.');
    }

    final weekStart = _weekStart(DateTime.now());
    final slotEnd = slotStart.add(const Duration(hours: 1));
    final hold = {
      'id': 'mock-hold-${_uuid.v4()}',
      'doctorId': doctorId,
      'consultationType': consultationType,
      'dayOfWeek': dayOfWeek,
      'startHour': startHour,
      'slotStart': slotStart.toIso8601String(),
      'slotEnd': slotEnd.toIso8601String(),
      'weekStartDate': weekStart.toIso8601String(),
      'status': 'held',
      'paymentExpiresAt':
          DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
    };
    _consultationBookings.add(hold);
    return {
      'holdId': hold['id'],
      'expiresAt': hold['paymentExpiresAt'],
    };
  }

  void releaseSlotHold(String holdId) {
    _consultationBookings.removeWhere(
      (b) => b['id'] == holdId && b['status'] == 'held',
    );
  }

  Map<String, dynamic> createBooking({
    required String doctorId,
    required String consultationType,
    required Map<String, dynamic> payload,
  }) {
    final doctor = getDoctorById(doctorId);
    if (doctor == null || doctor.id == null) {
      throw Exception('Doctor not found');
    }

    final dayOfWeek = payload['dayOfWeek'] as int? ?? 0;
    final startHour = payload['startHour'] as int? ?? 8;
    final weekStart = _weekStart(DateTime.now());
    final slotStart = DateTime.tryParse(payload['slotStart'] as String? ?? '') ??
        _slotStart(weekStart, dayOfWeek, startHour);
    final slotEnd = slotStart.add(const Duration(hours: 1));
    final key = '${dayOfWeek}_$startHour';

    final duplicate = _consultationBookings.any(
      (b) =>
          b['doctorId'] == doctorId &&
          b['consultationType'] == consultationType &&
          '${b['dayOfWeek']}_${b['startHour']}' == key &&
          _isActiveReservation(b),
    );
    if (duplicate) {
      throw Exception('This slot was just booked. Please choose another time.');
    }

    _consultationBookings.removeWhere(
      (b) =>
          b['doctorId'] == doctorId &&
          b['consultationType'] == consultationType &&
          '${b['dayOfWeek']}_${b['startHour']}' == key &&
          b['status'] == 'held',
    );

    final appointmentCode = consultationType == 'visit_site'
        ? (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString()
        : null;

    final booking = {
      'id': 'mock-booking-${_uuid.v4()}',
      'doctorId': doctorId,
      'consultationType': consultationType,
      if (appointmentCode != null) 'appointmentCode': appointmentCode,
      'patientName': payload['patientName'],
      'patientMobile': payload['patientMobile'],
      'patientEmail': payload['patientEmail'],
      'patientNotes': payload['patientNotes'],
      'patientAddress': payload['patientAddress'],
      'patientCity': payload['patientCity'],
      'patientState': payload['patientState'],
      'patientPincode': payload['patientPincode'],
      'visitReason': payload['visitReason'],
      'dayOfWeek': dayOfWeek,
      'startHour': startHour,
      'slotStart': slotStart.toIso8601String(),
      'slotEnd': slotEnd.toIso8601String(),
      'weekStartDate': weekStart.toIso8601String(),
      'consultationFee': doctor.consultationFee,
      'status': 'confirmed',
      'label': _slotLabel(slotStart, slotEnd),
      'doctorName': doctor.fullName,
      'clinicName': doctor.clinicName,
      'clinicAddress': [
        doctor.address,
        doctor.city,
        doctor.state,
        doctor.pincode,
      ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', '),
      'createdAt': DateTime.now().toIso8601String(),
    };
    _consultationBookings.add(booking);
    return booking;
  }

  String _statusToString(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.pending:
        return 'pending';
      case VerificationStatus.underReview:
        return 'under_review';
      case VerificationStatus.verified:
        return 'verified';
      case VerificationStatus.rejected:
        return 'rejected';
      default:
        return 'pending';
    }
  }
}
