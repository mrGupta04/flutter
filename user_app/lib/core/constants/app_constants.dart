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

  // Doctor API Endpoints
  static const String endpointRegisterDoctor = '/doctor/register';
  static const String endpointUploadDocument = '/doctor/upload-document';
  static const String endpointUploadProfile = '/doctor/upload-profile';
  static const String endpointGetProfile = '/doctor/profile';
  static const String endpointUpdateProfile = '/doctor/profile';
  static const String endpointPatientRegister = '/patient/register';
  static const String endpointPatientLogin = '/patient/login';
  static const String endpointPatientProfile = '/patient/profile';
  static const String endpointPatientBookings = '/patient/bookings';
  static String endpointPatientBookingPreviousReport(String bookingId) =>
      '/patient/bookings/$bookingId/previous-reports';
  static const String endpointVerifiedDoctors = '/doctor/verified';
  static const String endpointDoctorLiveStatus = '/doctor/live-status';
  static const String endpointDoctorFeedback = '/doctor/feedback';
  static const String endpointDoctorBookableSlots = '/doctor/bookable-slots';
  static const String endpointDoctorSlotHold = '/doctor/slot-hold';
  static String endpointDoctorSlotHoldRelease(String holdId) =>
      '/doctor/slot-hold/$holdId';
  static const String endpointOnlineConsultBook = '/doctor/online-consult';
  static const String endpointHospitalVisitBook = '/doctor/hospital-visit';
  static const String endpointHomeVisitBook = '/doctor/home-visit';
  static const String endpointHomeVisitRequest = '/doctor/home-visit/request';
  static String endpointDoctorApproveHomeVisit(String bookingId) =>
      '/doctor/bookings/$bookingId/approve-home-visit';
  static String endpointDoctorRejectHomeVisit(String bookingId) =>
      '/doctor/bookings/$bookingId/reject-home-visit';
  static const String endpointPaymentCreateOrder = '/payments/create-order';
  static const String endpointPaymentVerify = '/payments/verify';
  static String endpointConsultationVideoSession(String bookingId) =>
      '/consultations/$bookingId/video-session';
  static String endpointConsultationVideoJoin(String bookingId) =>
      '/consultations/$bookingId/video-session/join';
  static String endpointConsultationVideoEnd(String bookingId) =>
      '/consultations/$bookingId/video-session/end';
  static String endpointConsultationFeedback(String bookingId) =>
      '/consultations/$bookingId/feedback';
  static String endpointConsultationFeedbackDismiss(String bookingId) =>
      '/consultations/$bookingId/feedback/dismiss';
  static String endpointConsultationPrescription(String bookingId) =>
      '/consultations/$bookingId/prescription';
  static const String endpointAadhaarConfig = '/doctor/aadhaar/config';
  static const String endpointAadhaarSendOtp = '/doctor/aadhaar/send-otp';
  static const String endpointAadhaarVerifyOtp = '/doctor/aadhaar/verify-otp';

  // Nurse API Endpoints (patient discovery)
  static const String endpointGetNurseProfile = '/nurse/profile';
  static const String endpointVerifiedNurses = '/nurse/verified';
  static const String endpointNurseLiveStatus = '/nurse/live-status';
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
  static const String endpointVerifiedAmbulances = '/ambulance/verified';

  // Blood Bank API Endpoints
  static const String endpointRegisterBloodBank = '/blood-bank/register';
  static const String endpointBloodBankUploadProfile = '/blood-bank/upload-profile';
  static const String endpointGetBloodBankProfile = '/blood-bank/profile';
  static const String endpointVerifiedBloodBanks = '/blood-bank/verified';
  static const String endpointBloodBankBookings = '/blood-bank/bookings';
  static const String endpointBloodBankReviews = '/blood-bank/reviews';
  static const String endpointBloodBankEmergency = '/blood-bank/emergency';
  static const String endpointBloodBankCatalog = '/blood-bank/catalog';
  static const String endpointBloodBankPaymentCreateOrder = '/blood-bank/payments/create-order';
  static const String endpointBloodBankPaymentVerify = '/blood-bank/payments/verify';

  // Admin API Endpoints
  static const String endpointAdminLogin = '/admin/login';
  static const String endpointAdminDoctors = '/admin/doctors';
  static String endpointAdminDoctor(String id) => '/admin/doctors/$id';
  static String endpointAdminDoctorDocuments(String id) =>
      '/admin/doctors/$id/documents';
  static String endpointAdminApprove(String id) => '/admin/doctors/$id/approve';
  static String endpointAdminReject(String id) => '/admin/doctors/$id/reject';
  static const String endpointAdminNurses = '/admin/nurses';
  static String endpointAdminNurse(String id) => '/admin/nurses/$id';
  static String endpointAdminNurseApprove(String id) => '/admin/nurses/$id/approve';
  static String endpointAdminNurseReject(String id) => '/admin/nurses/$id/reject';

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
  static const int totalRegistrationSteps = 6;

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
  static const String routeUserLogin = '/user-login';
  static const String routeUserRegister = '/user-register';
  static const String routeUserDashboard = '/user/dashboard';
  static const String routeUserEditProfile = '/user/edit-profile';
  /// Legacy hyphen paths (redirect to slash paths).
  static const String routeUserDashboardLegacy = '/user-dashboard';
  static const String routeUserEditProfileLegacy = '/user-edit-profile';

  // Routes — provider registration app
  static const String routeProviderLanding = '/provider-landing';

  // Routes — shared / legacy
  static const String routeGlobalSearch = '/search';
  static const String routeDoctorSearch = '/doctor-search';
  static const String routeDoctorProfile = '/doctor-profile';
  static const String routeNurseSearch = '/nurse-search';
  static const String routeNurseProfile = '/nurse-profile';
  static const String routeAmbulanceSearch = '/ambulance-search';
  static const String routeBloodBankSearch = '/blood-bank-search';
  static const String routeBloodBanks = '/blood-banks';
  static const String routeBloodBankDetail = '/blood-bank';
  static const String routeEmergencyBloodRequest = '/emergency-blood-request';
  static const String routeBloodOrderConfirmation = '/blood-order';
  static const String routeCareListing = '/care-listing';
  static const String routeLabs = '/labs';
  static const String routeLabDetail = '/lab';
  static const String routeLabCart = '/lab-cart';
  static const String routeLabBookingConfirmation = '/lab-booking-confirmation';
  static const String routeScans = '/scans';
  static const String routeScanSearch = '/scan-search';
  static const String routeScanCenterDetail = '/scan-center';
  static const String routeScanRegistration = '/scan-registration';
  static const String routeScanApplicationSubmitted = '/scan-application-submitted';
  static const String routeLabSearch = '/lab-search';
  static const String routeLabRegistration = '/lab-registration';
  static const String routeLabApplicationSubmitted = '/lab-application-submitted';
  static const String routeConsultationDemo = '/consultation-demo';
  static const String routeOnlineConsultBooking = '/online-consult';
  static const String routeHospitalVisitBooking = '/hospital-visit';
  static const String routeHomeVisitBooking = '/home-visit';
  static const String routeNurseHomeVisitBooking = '/nurse-home-visit';
  static const String routeVideoConsult = '/video-consult';
  static const String routeRegistrationLanding = '/registration-landing';
  static const String routeRegistrationForm = '/registration-form';
  static const String routeAmbulanceRegistration = '/ambulance-registration';
  static const String routeBloodBankRegistration = '/blood-bank-registration';
  static const String routeAmbulanceApplicationSubmitted =
      '/ambulance-application-submitted';
  static const String routeBloodBankApplicationSubmitted =
      '/blood-bank-application-submitted';
  static const String routeApplicationSubmitted = '/application-submitted';
  static const String routeDoctorDashboard = '/doctor-dashboard';
  static const String routeAdminLogin = '/admin-login';
  static const String routeAdminDashboard = '/admin-dashboard';
  static const String routeAdminDoctorList = '/admin-doctor-list';
  static const String routeAdminDoctorDetails = '/admin-doctor-details';
  static const String routeAdminNurseList = '/admin-nurse-list';
  static const String routeAdminNurseDetails = '/admin-nurse-details';

  // Lab API Endpoints
  static const String endpointRegisterLab = '/lab/register';
  static const String endpointLabUploadProfile = '/lab/upload-profile';
  static const String endpointLabUploadDocument = '/lab/upload-document';
  static const String endpointLabUploadImage = '/lab/upload-image';
  static const String endpointGetLabProfile = '/lab/profile';
  static const String endpointVerifiedLabs = '/lab/verified';

  // Scan API Endpoints
  static const String endpointRegisterScanCenter = '/scan/register';
  static const String endpointScanUploadProfile = '/scan/upload-profile';
  static const String endpointScanUploadDocument = '/scan/upload-document';
  static const String endpointScanUploadImage = '/scan/upload-image';
  static const String endpointGetScanCenterProfile = '/scan/profile';
  static const String endpointVerifiedScanCenters = '/scan/verified';

  static const String mockImageUrl =
      'https://images.unsplash.com/photo-1612349317228-cc624a92fc4d?w=400&h=400&fit=crop';

  static const String errorNetworkException =
      'Network error. Please check your connection and ensure the API server is running.';
  static const String errorServerException = 'Server error. Please try again later.';
  static const String errorTimeoutException = 'Request timeout. Please try again.';
  static const String errorInvalidInput = 'Please enter valid information.';
  static const String errorSomethingWentWrong = 'Something went wrong. Please try again.';

  static const String successDocumentUploaded = 'Document uploaded successfully.';
  static const String successApplicationSubmitted = 'Application submitted successfully.';
  static const String successProfileUpdated = 'Profile updated successfully.';
}
