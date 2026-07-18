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

  // Doctor API Endpoints (patient discovery & booking)
  static const String endpointGetProfile = '/doctor/profile';
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

  // Patient notifications / favorites / booking lifecycle
  static const String endpointPatientNotifications = '/patient/notifications';
  static String endpointPatientNotificationRead(String id) =>
      '/patient/notifications/$id/read';
  static const String endpointPatientNotificationsReadAll =
      '/patient/notifications/read-all';
  static const String endpointPatientDeviceToken = '/patient/device-token';
  static const String endpointPatientFavorites = '/patient/favorites';
  static String endpointPatientFavoriteCheck(
          String providerType, String providerId) =>
      '/patient/favorites/check/$providerType/$providerId';
  static String endpointPatientFavoriteDelete(
          String providerType, String providerId) =>
      '/patient/favorites/$providerType/$providerId';
  static String endpointPatientBookingTimeline(String bookingId) =>
      '/patient/bookings/$bookingId/timeline';
  static String endpointPatientBookingCancel(String bookingId) =>
      '/patient/bookings/$bookingId/cancel';
  static String endpointPatientBookingReschedule(String bookingId) =>
      '/patient/bookings/$bookingId/reschedule';
  static String endpointPatientBookingCancellationPolicy(String bookingId) =>
      '/patient/bookings/$bookingId/cancellation-policy';
  static String endpointPatientBookingChat(String bookingId) =>
      '/patient/bookings/$bookingId/chat';
  static String endpointPatientVisitNote(String bookingId) =>
      '/patient/bookings/$bookingId/visit-note';

  // Nurse API Endpoints (patient discovery)
  static const String endpointGetNurseProfile = '/nurse/profile';
  static const String endpointVerifiedNurses = '/nurse/verified';
  static const String endpointNurseLiveStatus = '/nurse/live-status';
  static const String endpointNurseBookableSlots = '/nurse/bookable-slots';
  static const String endpointNurseSlotHold = '/nurse/slot-hold';
  static String endpointNurseSlotHoldRelease(String holdId) =>
      '/nurse/slot-hold/$holdId';
  static const String endpointNurseHomeVisitRequest = '/nurse/home-visit/request';
  static const String endpointNurseFeedback = '/nurse/feedback';

  // Ambulance API Endpoints (patient discovery & booking)
  static const String endpointVerifiedAmbulances = '/ambulance/verified';
  static const String endpointAmbulanceBookings = '/ambulance/bookings';
  static String endpointAmbulanceBooking(String bookingId) =>
      '/ambulance/bookings/$bookingId';
  static String endpointAmbulanceBookingLocation(String bookingId) =>
      '/ambulance/bookings/$bookingId/location';

  // Rewards / referrals
  static const String endpointPatientRewards = '/patient/rewards';
  static const String endpointPatientRewardsRedeem = '/patient/rewards/redeem';

  // CMS banners (public)
  static const String endpointCmsBanners = '/cms/banners';

  // Blood Bank API Endpoints (patient discovery & booking)
  static const String endpointVerifiedBloodBanks = '/blood-bank/verified';
  static const String endpointBloodBankBookings = '/blood-bank/bookings';
  static const String endpointBloodBankReviews = '/blood-bank/reviews';
  static const String endpointBloodBankEmergency = '/blood-bank/emergency';
  static const String endpointBloodBankCatalog = '/blood-bank/catalog';
  static const String endpointBloodBankPaymentCreateOrder = '/blood-bank/payments/create-order';
  static const String endpointBloodBankPaymentVerify = '/blood-bank/payments/verify';

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

  // Cache
  static const int cacheDurationMinutes = 30;

  // Pagination
  static const int defaultPageSize = 20;
  static const int defaultInitialPage = 1;

  // Animation
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // Routes — user app
  static const String routeUserHome = '/user-home';
  static const String routeUserLogin = '/user-login';
  static const String routeUserRegister = '/user-register';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeHealthProfile = '/user/health-profile';
  static const String routeSupportTickets = '/user/support';
  static const String routeUserRewards = '/user/rewards';
  static const String routeUserDashboard = '/user/dashboard';
  static const String routeUserEditProfile = '/user/edit-profile';
  /// Legacy hyphen paths (redirect to slash paths).
  static const String routeUserDashboardLegacy = '/user-dashboard';
  static const String routeUserEditProfileLegacy = '/user-edit-profile';

  // Routes — patient marketplace
  static const String routeGlobalSearch = '/search';
  static const String routeDoctorSearch = '/doctor-search';
  static const String routeDoctorProfile = '/doctor-profile';
  static const String routeNurseSearch = '/nurse-search';
  static const String routeNurseProfile = '/nurse-profile';
  static const String routeAmbulanceSearch = '/ambulance-search';
  static const String routeAmbulanceTrack = '/ambulance-track';
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
  static const String routeLabSearch = '/lab-search';
  static const String routeConsultationDemo = '/consultation-demo';
  static const String routeOnlineConsultBooking = '/online-consult';
  static const String routeHospitalVisitBooking = '/hospital-visit';
  static const String routeHomeVisitBooking = '/home-visit';
  static const String routeNurseHomeVisitBooking = '/nurse-home-visit';
  static const String routeVideoConsult = '/video-consult';
  static const String routeNotifications = '/notifications';
  static const String routeFavorites = '/favorites';
  static const String routeBookingChat = '/booking-chat';
  static const String routeBookingTimeline = '/booking-timeline';
  static const String routeVisitNote = '/visit-note';

  // Lab API Endpoints (patient discovery & booking)
  static const String endpointGetLabProfile = '/lab/profile';
  static const String endpointVerifiedLabs = '/lab/verified';
  static const String endpointLabBookings = '/lab/bookings';

  // Patient password recovery
  static const String endpointPatientForgotPassword = '/patient/forgot-password';
  static const String endpointPatientResetPassword = '/patient/reset-password';
  static const String endpointPatientMedicalProfile = '/patient/medical-profile';
  static const String endpointPatientFamilyMembers = '/patient/family-members';
  static String endpointPatientFamilyMember(String id) =>
      '/patient/family-members/$id';
  static const String endpointPatientAddresses = '/patient/addresses';
  static String endpointPatientAddress(String id) => '/patient/addresses/$id';
  static const String endpointPatientSupportTickets = '/patient/support-tickets';
  static const String endpointPatientValidateCoupon = '/patient/coupons/validate';
  static const String endpointLabPaymentsCreateOrder = '/lab/payments/create-order';
  static const String endpointLabPaymentsVerify = '/lab/payments/verify';
  static const String endpointScanBookings = '/scan/bookings';
  static const String endpointScanPaymentsCreateOrder =
      '/scan/payments/create-order';
  static const String endpointScanPaymentsVerify = '/scan/payments/verify';

  // Scan API Endpoints (patient discovery)
  static const String endpointGetScanCenterProfile = '/scan/profile';
  static const String endpointVerifiedScanCenters = '/scan/verified';

  // Blood bank profile (patient discovery)
  static const String endpointGetBloodBankProfile = '/blood-bank/profile';

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
