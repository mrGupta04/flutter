import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../models/models.dart';

/// In-memory mock database for demo purposes
class MockDatabase {
  MockDatabase._internal();

  static final MockDatabase instance = MockDatabase._internal();

  final Uuid _uuid = const Uuid();
  final List<DoctorModel> _doctors = [];
  final Map<String, List<DoctorDocumentModel>> _documentsByDoctor = {};

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
          consultationFee: 300 + (i * 100),
          onlineConsultFee: 250 + (i * 80),
          homeVisitFee: 400 + (i * 100),
          visitSiteFee: 300 + (i * 100),
          offersOnlineConsult: i % 3 != 1,
          offersBookHome: i % 3 != 2,
          offersVisitSite: i % 3 != 0,
          city: 'Delhi',
          qualification: 'MBBS',
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
