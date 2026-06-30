import '../config/api_config.dart';

/// Constants used throughout the app
class AppConstants {
  AppConstants._();

  // API Configuration
  static String get apiBaseUrl => ApiConfig.baseUrl;
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
  static bool get useMockApi => ApiConfig.useMockApi;
  static String get adminApiKey => ApiConfig.adminApiKey;

  // Provider auth
  static const String endpointDoctorLogin = '/doctor/login';
  static const String endpointNurseLogin = '/nurse/login';
  static const String endpointAmbulanceLogin = '/ambulance/login';
  static const String endpointBloodBankLogin = '/blood-bank/login';
  static const String endpointDoctorBookings = '/doctor/bookings';
  static String endpointDoctorApproveHomeVisit(String bookingId) =>
      '/doctor/bookings/$bookingId/approve-home-visit';
  static String endpointDoctorRejectHomeVisit(String bookingId) =>
      '/doctor/bookings/$bookingId/reject-home-visit';
  static String endpointNurseApproveHomeVisit(String bookingId) =>
      '/nurse/bookings/$bookingId/approve-home-visit';
  static String endpointNurseRejectHomeVisit(String bookingId) =>
      '/nurse/bookings/$bookingId/reject-home-visit';
  static const String endpointDoctorVerifyAppointment = '/doctor/verify-appointment';
  static String endpointConsultationVideoSession(String bookingId) =>
      '/consultations/$bookingId/video-session';
  static String endpointConsultationVideoJoin(String bookingId) =>
      '/consultations/$bookingId/video-session/join';
  static String endpointConsultationVideoEnd(String bookingId) =>
      '/consultations/$bookingId/video-session/end';
  static String endpointConsultationPrescriptionContext(String bookingId) =>
      '/consultations/$bookingId/prescription/context';
  static String endpointConsultationPrescription(String bookingId) =>
      '/consultations/$bookingId/prescription';
  static const String endpointNurseBookings = '/nurse/bookings';
  static const String endpointAmbulanceBookings = '/ambulance/bookings';
  static const String endpointBloodBankBookings = '/blood-bank/bookings';

  // Doctor API Endpoints
  static const String endpointRegisterDoctor = '/doctor/register';
  static const String endpointUploadDocument = '/doctor/upload-document';
  static const String endpointUploadProfile = '/doctor/upload-profile';
  static const String endpointUploadHospitalPhoto = '/doctor/upload-hospital-photo';
  static const String endpointGetProfile = '/doctor/profile';
  static const String endpointUpdateProfile = '/doctor/profile';
  static const String endpointDoctorAvailability = '/doctor/availability';
  static const String endpointDoctorPresenceHeartbeat = '/doctor/presence/heartbeat';
  static const String endpointDoctorPresenceOffline = '/doctor/presence/offline';
  static const String endpointVerifiedDoctors = '/doctor/verified';
  static const String endpointDoctorEmailSendOtp = '/doctor/email/send-otp';
  static const String endpointDoctorEmailVerifyOtp = '/doctor/email/verify-otp';
  static const String endpointDoctorEmailConfig = '/doctor/email/config';

  // Nurse API Endpoints
  static const String endpointRegisterNurse = '/nurse/register';
  static const String endpointNurseUploadProfile = '/nurse/upload-profile';
  static const String endpointNurseUploadDocument = '/nurse/upload-document';
  static const String endpointGetNurseProfile = '/nurse/profile';
  static const String endpointUpdateNurseProfile = '/nurse/profile';
  static const String endpointVerifiedNurses = '/nurse/verified';
  static const String endpointNurseAvailability = '/nurse/availability';
  static const String endpointNurseBookableSlots = '/nurse/bookable-slots';
  static const String endpointNurseSlotHold = '/nurse/slot-hold';
  static String endpointNurseSlotHoldRelease(String holdId) =>
      '/nurse/slot-hold/$holdId';
  static const String endpointNurseHomeVisitRequest = '/nurse/home-visit/request';

  // Ambulance API Endpoints
  static const String endpointRegisterAmbulance = '/ambulance/register';
  static const String endpointAmbulanceUploadProfile = '/ambulance/upload-profile';
  static const String endpointAmbulanceUploadDocument = '/ambulance/upload-document';
  static const String endpointGetAmbulanceProfile = '/ambulance/profile';
  static const String endpointUpdateAmbulanceProfile = '/ambulance/profile';
  static const String endpointVerifiedAmbulances = '/ambulance/verified';

  // Blood Bank API Endpoints
  static const String endpointRegisterBloodBank = '/blood-bank/register';
  static const String endpointBloodBankUploadProfile = '/blood-bank/upload-profile';
  static const String endpointGetBloodBankProfile = '/blood-bank/profile';
  static const String endpointUpdateBloodBankProfile = '/blood-bank/profile';
  static const String endpointVerifiedBloodBanks = '/blood-bank/verified';

  // Lab API Endpoints
  static const String endpointRegisterLab = '/lab/register';
  static const String endpointLabLogin = '/lab/login';
  static const String endpointLabUploadProfile = '/lab/upload-profile';
  static const String endpointLabUploadDocument = '/lab/upload-document';
  static const String endpointLabUploadImage = '/lab/upload-image';
  static const String endpointGetLabProfile = '/lab/profile';
  static const String endpointUpdateLabProfile = '/lab/profile';
  static const String endpointVerifiedLabs = '/lab/verified';

  // Admin API Endpoints
  static const String endpointAdminLogin = '/admin/login';
  static const String endpointAdminDoctors = '/admin/doctors';
  static String endpointAdminDoctor(String id) => '/admin/doctors/$id';
  static String endpointAdminDoctorDocuments(String id) =>
      '/admin/doctors/$id/documents';
  static String endpointAdminDoctorDocumentVerify(String providerId, String documentId) =>
      '/admin/doctors/$providerId/documents/$documentId/verify';
  static String endpointAdminDoctorDocumentReject(String providerId, String documentId) =>
      '/admin/doctors/$providerId/documents/$documentId/reject';
  static String endpointAdminApprove(String id) => '/admin/doctors/$id/approve';
  static String endpointAdminReject(String id) => '/admin/doctors/$id/reject';
  static const String endpointAdminNurses = '/admin/nurses';
  static String endpointAdminNurse(String id) => '/admin/nurses/$id';
  static String endpointAdminNurseDocuments(String id) => '/admin/nurses/$id/documents';
  static String endpointAdminNurseDocumentVerify(String providerId, String documentId) =>
      '/admin/nurses/$providerId/documents/$documentId/verify';
  static String endpointAdminNurseDocumentReject(String providerId, String documentId) =>
      '/admin/nurses/$providerId/documents/$documentId/reject';
  static String endpointAdminNurseApprove(String id) => '/admin/nurses/$id/approve';
  static String endpointAdminNurseReject(String id) => '/admin/nurses/$id/reject';
  static const String endpointAdminAmbulances = '/admin/ambulances';
  static String endpointAdminAmbulance(String id) => '/admin/ambulances/$id';
  static String endpointAdminAmbulanceDocuments(String id) =>
      '/admin/ambulances/$id/documents';
  static String endpointAdminAmbulanceDocumentVerify(
    String providerId,
    String documentId,
  ) =>
      '/admin/ambulances/$providerId/documents/$documentId/verify';
  static String endpointAdminAmbulanceDocumentReject(
    String providerId,
    String documentId,
  ) =>
      '/admin/ambulances/$providerId/documents/$documentId/reject';
  static String endpointAdminAmbulanceApprove(String id) =>
      '/admin/ambulances/$id/approve';
  static String endpointAdminAmbulanceReject(String id) =>
      '/admin/ambulances/$id/reject';
  static const String endpointDoctorDocuments = '/doctor/documents';
  static const String endpointNurseDocuments = '/nurse/documents';
  static const String endpointAmbulanceDocuments = '/ambulance/documents';
  static const String endpointAdminBloodBanks = '/admin/blood-banks';
  static String endpointAdminBloodBank(String id) => '/admin/blood-banks/$id';
  static String endpointAdminBloodBankApprove(String id) =>
      '/admin/blood-banks/$id/approve';
  static String endpointAdminBloodBankReject(String id) =>
      '/admin/blood-banks/$id/reject';
  static const String endpointAdminLabs = '/admin/labs';
  static String endpointAdminLab(String id) => '/admin/labs/$id';
  static String endpointAdminLabApprove(String id) => '/admin/labs/$id/approve';
  static String endpointAdminLabReject(String id) => '/admin/labs/$id/reject';
  static String endpointAdminLabSuspend(String id) => '/admin/labs/$id/suspend';
  static String endpointAdminLabRequestDocuments(String id) =>
      '/admin/labs/$id/request-documents';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 20;
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int minBioLength = 10;
  static const int maxBioLength = 500;
  static const int maxConsultationFee = 9999;
  static const int minYearsOfExperience = 0;
  static const int maxYearsOfExperience = 80;

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024;
  static const int maxProfileImageSize = 5 * 1024 * 1024;
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedDocumentFormats = [
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
  ];

  // Maps
  static const double defaultMapLat = 28.6139;
  static const double defaultMapLng = 77.2090;
  static const double defaultMapZoom = 13;

  // Registration Steps
  static const int totalRegistrationSteps = 7;

  // Cache
  static const int cacheDurationMinutes = 30;

  // Pagination
  static const int defaultPageSize = 20;
  static const int defaultInitialPage = 1;

  // Animation
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // Database
  static const String hiveBoxName = 'doctor_registration_box';

  // Routes — user app
  static const String routeUserHome = '/user-home';

  // Routes — provider registration app
  static const String routeProviderLanding = '/provider-landing';
  static const String routeProviderAuthGate = '/provider-auth';
  static const String routeProviderLogin = '/provider-login';
  static const String routeProviderProfile = '/provider-profile';
  static const String routeNurseApplicationSubmitted = '/nurse-application-submitted';

  // Routes — shared / legacy
  static const String routeDoctorSearch = '/doctor-search';
  static const String routeCareListing = '/care-listing';
  static const String routeConsultationDemo = '/consultation-demo';
  static const String routeRegistrationLanding = '/registration-landing';
  static const String routeRegistrationForm = '/registration-form';
  static const String routeNurseRegistration = '/nurse-registration';
  static const String routeAmbulanceRegistration = '/ambulance-registration';
  static const String routeBloodBankRegistration = '/blood-bank-registration';
  static const String routeApplicationSubmitted = '/application-submitted';
  static const String routeAmbulanceApplicationSubmitted =
      '/ambulance-application-submitted';
  static const String routeBloodBankApplicationSubmitted =
      '/blood-bank-application-submitted';
  static const String routeLabRegistration = '/lab-registration';
  static const String routeLabApplicationSubmitted = '/lab-application-submitted';
  static const String routeDoctorDashboard = '/doctor-dashboard';
  static const String routeNurseDashboard = '/nurse-dashboard';
  static const String routeVideoConsult = '/video-consult';
  static const String routeAdminLogin = '/admin-login';
  static const String routeAdminDashboard = '/admin-dashboard';
  static const String routeAdminDoctorList = '/admin-doctor-list';
  static const String routeAdminDoctorDetails = '/admin-doctor-details';
  static const String routeAdminNurseList = '/admin-nurse-list';
  static const String routeAdminNurseDetails = '/admin-nurse-details';
  static const String routeAdminAmbulanceList = '/admin-ambulance-list';
  static const String routeAdminAmbulanceDetails = '/admin-ambulance-details';
  static const String routeAdminBloodBankList = '/admin-blood-bank-list';
  static const String routeAdminBloodBankDetails = '/admin-blood-bank-details';
  static const String routeAdminLabList = '/admin-lab-list';
  static const String routeAdminLabDetails = '/admin-lab-details';

  static const String mockImageUrl =
      'https://images.unsplash.com/photo-1612349317228-cc624a92fc4d?w=400&h=400&fit=crop';

  static const String errorNetworkException =
      'Network error. Please check your connection and ensure the API server is running.';
  static const String errorServerException = 'Server error. Please try again later.';
  static const String errorTimeoutException = 'Request timeout. Please try again.';
  static const String errorInvalidInput = 'Please enter valid information.';
  static const String errorSomethingWentWrong = 'Something went wrong. Please try again.';

  static const String successDocumentUploaded = 'Document uploaded successfully.';
  static const String successApplicationSubmitted =
      'Application sent to admin for review.';
  static const String successProfileUpdated = 'Profile updated successfully.';
}
