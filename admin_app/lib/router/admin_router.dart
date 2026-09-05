import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/router/router_transitions.dart';
import '../core/services/token_storage.dart';
import '../features/admin/presentation/screens/admin_ambulance_details_screen.dart';
import '../features/admin/presentation/screens/admin_ambulance_list_screen.dart';
import '../features/admin/presentation/screens/admin_ambulance_ops_screen.dart';
import '../features/admin/presentation/screens/admin_ambulance_live_screen.dart';
import '../features/admin/presentation/screens/admin_ambulance_pricing_screen.dart';
import '../features/ambulance_dashboard/presentation/screens/ambulance_dashboard_screen.dart';
import '../features/ambulance_dashboard/presentation/screens/ambulance_operations_screen.dart';
import '../features/ambulance_dashboard/presentation/screens/ambulance_driver_mode_screen.dart';
import '../features/admin/presentation/screens/admin_blood_bank_details_screen.dart';
import '../features/admin/presentation/screens/admin_blood_bank_list_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/admin_ops_screens.dart';
import '../features/admin/presentation/screens/admin_patient_details_screen.dart';
import '../features/admin/presentation/screens/admin_service_provider_management_screen.dart';
import '../features/admin/presentation/screens/admin_doctor_sessions_screen.dart';
import '../features/admin/presentation/screens/admin_doctor_session_details_screen.dart';
import '../features/admin/presentation/screens/admin_diagnostic_sessions_screen.dart';
import '../features/admin/presentation/screens/admin_diagnostic_session_details_screen.dart';
import '../data/models/doctor_model.dart';
import '../data/models/doctor_booking_model.dart';
import '../features/admin/presentation/screens/admin_doctor_details_screen.dart';
import '../features/admin/presentation/screens/admin_doctor_list_screen.dart';
import '../features/admin/presentation/screens/admin_login_screen.dart';
import '../features/admin/presentation/screens/admin_nurse_details_screen.dart';
import '../features/admin/presentation/screens/admin_nurse_list_screen.dart';
import '../features/ambulance_registration/presentation/screens/ambulance_application_submitted_screen.dart';
import '../features/ambulance_registration/presentation/screens/ambulance_registration_screen.dart';
import '../features/admin/presentation/screens/admin_lab_details_screen.dart';
import '../features/admin/presentation/screens/admin_lab_list_screen.dart';
import '../features/admin/presentation/screens/admin_scan_details_screen.dart';
import '../features/admin/presentation/screens/admin_scan_list_screen.dart';
import '../features/admin/presentation/screens/approval_management_screen.dart';
import '../features/blood_bank_registration/presentation/screens/blood_bank_application_submitted_screen.dart';
import '../features/blood_bank_registration/presentation/screens/blood_bank_registration_screen.dart';
import '../features/lab_registration/presentation/screens/lab_application_submitted_screen.dart';
import '../features/lab_registration/presentation/screens/lab_registration_screen.dart';
import '../features/scan_registration/presentation/screens/scan_application_submitted_screen.dart';
import '../features/scan_registration/presentation/screens/scan_registration_screen.dart';
import '../features/scan_dashboard/presentation/screens/scan_dashboard_screen.dart';
import '../features/lab_dashboard/presentation/screens/lab_dashboard_screen.dart';
import '../features/lab_dashboard/presentation/screens/lab_prescription_inbox_screen.dart';
import '../features/blood_bank_dashboard/presentation/screens/blood_bank_dashboard_screen.dart';
import '../features/blood_bank_dashboard/presentation/screens/blood_bank_operations_screen.dart';
import '../features/admin/presentation/screens/admin_blood_analytics_screen.dart';
import '../features/doctor_dashboard/presentation/screens/doctor_dashboard_screen.dart';
import '../features/receptionist/presentation/screens/receptionist_dashboard_screen.dart';
import '../features/receptionist/presentation/screens/receptionist_login_screen.dart';
import '../features/receptionist/presentation/screens/receptionist_management_screen.dart';
import '../features/doctor_registration/presentation/screens/application_submitted_screen.dart';
import '../features/doctor_registration/presentation/screens/registration_form_screen.dart';
import '../features/nurse_registration/presentation/screens/nurse_application_submitted_screen.dart';
import '../features/nurse_dashboard/presentation/screens/nurse_dashboard_screen.dart';
import '../features/nurse_dashboard/presentation/screens/nurse_visit_assessment_screen.dart';
import '../features/nurse_dashboard/presentation/screens/nurse_visit_otp_screen.dart';
import '../features/home_visit_tracking/presentation/screens/provider_trip_screen.dart';
import '../features/earnings/presentation/screens/provider_earnings_screen.dart';
import '../features/notifications/presentation/screens/provider_notifications_screen.dart';
import '../features/booking_chat/presentation/screens/provider_booking_chat_screen.dart';
import '../features/nurse_registration/presentation/screens/nurse_registration_screen.dart';
import '../features/auth/presentation/screens/provider_auth_gate_screen.dart';
import '../features/auth/presentation/screens/provider_forgot_password_screen.dart';
import '../features/auth/presentation/screens/provider_login_screen.dart';
import '../core/models/provider_type.dart';
import '../features/provider/presentation/screens/provider_landing_screen.dart';
import '../features/video_consult/presentation/screens/video_consult_screen.dart';
import '../features/provider/presentation/screens/provider_profile_screen.dart';
import '../features/auth/provider/provider_auth_provider.dart';
import '../features/receptionist/provider/receptionist_providers.dart';
import '../features/admin/provider/admin_auth_provider.dart';
import '../features/select_location/select_location_screen.dart';
import '../features/select_location/selected_location.dart';

bool _isAdminProtectedRoute(String location) {
  return location.startsWith(AppConstants.routeAdminDashboard) ||
      location.startsWith(AppConstants.routeApprovalManagement) ||
      location.startsWith(AppConstants.routeAdminServiceProviderManagement) ||
      location.startsWith(AppConstants.routeAdminDoctorSessions) ||
      location.startsWith(AppConstants.routeAdminDoctorSessionDetails) ||
      location.startsWith(AppConstants.routeAdminDiagnosticSessions) ||
      location.startsWith(AppConstants.routeAdminDiagnosticSessionDetails) ||
      location.startsWith(AppConstants.routeAdminOverview) ||
      location.startsWith(AppConstants.routeAdminBookings) ||
      location.startsWith(AppConstants.routeAdminPatients) ||
      location.startsWith(AppConstants.routeAdminPatientDetails) ||
      location.startsWith(AppConstants.routeAdminCoupons) ||
      location.startsWith(AppConstants.routeAdminCmsBanners) ||
      location.startsWith(AppConstants.routeAdminSupportTickets) ||
      location.startsWith(AppConstants.routeAdminRefunds) ||
      location.startsWith(AppConstants.routeAdminDoctorList) ||
      location.startsWith(AppConstants.routeAdminDoctorDetails) ||
      location.startsWith(AppConstants.routeAdminNurseList) ||
      location.startsWith(AppConstants.routeAdminNurseDetails) ||
      location.startsWith(AppConstants.routeAdminAmbulanceList) ||
      location.startsWith(AppConstants.routeAdminAmbulanceDetails) ||
      location.startsWith(AppConstants.routeAdminBloodBankList) ||
      location.startsWith(AppConstants.routeAdminBloodBankDetails) ||
      location.startsWith(AppConstants.routeAdminBloodAnalytics) ||
      location.startsWith(AppConstants.routeAdminAmbulanceOps) ||
      location.startsWith(AppConstants.routeAdminAmbulanceLive) ||
      location.startsWith(AppConstants.routeAdminAmbulancePricing) ||
      location.startsWith(AppConstants.routeAdminLabList) ||
      location.startsWith(AppConstants.routeAdminLabDetails) ||
      location.startsWith(AppConstants.routeAdminScanList) ||
      location.startsWith(AppConstants.routeAdminScanDetails);
}

bool _isAdminOnlyRoute(String location) {
  return location.startsWith(AppConstants.routeAdminDashboard) ||
      location.startsWith(AppConstants.routeAdminServiceProviderManagement) ||
      location.startsWith(AppConstants.routeAdminDoctorSessions) ||
      location.startsWith(AppConstants.routeAdminDoctorSessionDetails) ||
      location.startsWith(AppConstants.routeAdminDiagnosticSessions) ||
      location.startsWith(AppConstants.routeAdminDiagnosticSessionDetails) ||
      location.startsWith(AppConstants.routeAdminOverview) ||
      location.startsWith(AppConstants.routeAdminBookings) ||
      location.startsWith(AppConstants.routeAdminPatients) ||
      location.startsWith(AppConstants.routeAdminPatientDetails) ||
      location.startsWith(AppConstants.routeAdminCoupons) ||
      location.startsWith(AppConstants.routeAdminCmsBanners) ||
      location.startsWith(AppConstants.routeAdminSupportTickets) ||
      location.startsWith(AppConstants.routeAdminRefunds) ||
      location == AppConstants.routeAdminDoctorList ||
      location == AppConstants.routeAdminNurseList ||
      location == AppConstants.routeAdminAmbulanceList ||
      location == AppConstants.routeAdminBloodBankList ||
      location.startsWith(AppConstants.routeAdminBloodAnalytics) ||
      location.startsWith(AppConstants.routeAdminAmbulanceOps) ||
      location.startsWith(AppConstants.routeAdminAmbulanceLive) ||
      location.startsWith(AppConstants.routeAdminAmbulancePricing) ||
      location == AppConstants.routeAdminLabList ||
      location == AppConstants.routeAdminScanList;
}

bool _isApproverKycDetailRoute(String location) {
  return location.startsWith('${AppConstants.routeAdminDoctorDetails}/') ||
      location.startsWith('${AppConstants.routeAdminNurseDetails}/') ||
      location.startsWith('${AppConstants.routeAdminAmbulanceDetails}/') ||
      location.startsWith('${AppConstants.routeAdminBloodBankDetails}/') ||
      location.startsWith('${AppConstants.routeAdminLabDetails}/') ||
      location.startsWith('${AppConstants.routeAdminScanDetails}/');
}

/// Admin app — provider registration + admin verification.
final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.routeProviderLanding,
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final loc = state.matchedLocation;

      final storedProviderType = await TokenStorage.instance.getProviderType();
      final receptionistToken = await TokenStorage.instance.getToken();
      final hasReceptionistToken =
          receptionistToken != null && receptionistToken.isNotEmpty;
      final isReceptionistSession =
          (storedProviderType == 'receptionist' && hasReceptionistToken) ||
          ref.read(receptionistAuthProvider).isAuthenticated;
      if (isReceptionistSession) {
        if (loc == AppConstants.routeProviderLanding) {
          return null;
        }
        if (loc == AppConstants.routeReceptionistLogin ||
            loc == AppConstants.routeReceptionistDashboard) {
          if (loc == AppConstants.routeReceptionistLogin) {
            return AppConstants.routeReceptionistDashboard;
          }
          return null;
        }
        return AppConstants.routeReceptionistDashboard;
      }

      if (loc == AppConstants.routeReceptionistDashboard) {
        return AppConstants.routeProviderLanding;
      }

      if (loc == AppConstants.routeDoctorDashboard ||
          loc == AppConstants.routeDoctorReceptionists ||
          loc == AppConstants.routeNurseDashboard ||
          loc == AppConstants.routeProviderHomeVisitTrip ||
          loc == AppConstants.routeScanDashboard ||
          loc == AppConstants.routeLabDashboard ||
          loc == AppConstants.routeLabPrescriptionInbox ||
          loc == AppConstants.routeLabPrescriptionDetail ||
          loc == AppConstants.routeBloodBankDashboard ||
          loc.startsWith(AppConstants.routeBloodBankOperations) ||
          loc == AppConstants.routeAmbulanceDashboard ||
          loc.startsWith(AppConstants.routeAmbulanceOperations) ||
          loc == AppConstants.routeAmbulanceDriverMode ||
          loc == AppConstants.routeProviderProfile) {
        if (ref.read(providerAuthProvider).isAuthenticated) {
          return null;
        }
        final token = await TokenStorage.instance.getToken();
        if (token == null || token.isEmpty) {
          return AppConstants.routeProviderLanding;
        }
      }

      if (_isAdminProtectedRoute(loc)) {
        final auth = ref.read(adminAuthProvider);
        if (!auth.isAuthenticated) {
          final adminToken = await TokenStorage.instance.getAdminToken();
          if (adminToken == null || adminToken.isEmpty) {
            return AppConstants.routeAdminLogin;
          }
        }
        final role =
            auth.role ?? await TokenStorage.instance.getAdminRole() ?? 'admin';
        final isApprover = role == 'approver';
        if (isApprover) {
          if (loc.startsWith(AppConstants.routeApprovalManagement) ||
              _isApproverKycDetailRoute(loc)) {
            return null;
          }
          if (_isAdminOnlyRoute(loc) ||
              loc.startsWith(AppConstants.routeAdminDoctorList) ||
              loc.startsWith(AppConstants.routeAdminNurseList) ||
              loc.startsWith(AppConstants.routeAdminAmbulanceList) ||
              loc.startsWith(AppConstants.routeAdminBloodBankList) ||
              loc.startsWith(AppConstants.routeAdminLabList) ||
              loc.startsWith(AppConstants.routeAdminScanList)) {
            return AppConstants.routeApprovalManagement;
          }
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.routeProviderLanding,
        name: 'providerLanding',
        pageBuilder: (context, state) => fadePage(
          state,
          const ProviderLandingScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeSelectLocation,
        name: 'selectLocation',
        pageBuilder: (context, state) => fadePage(
          state,
          SelectLocationScreen(
            args: state.extra is SelectLocationArgs
                ? state.extra as SelectLocationArgs
                : null,
          ),
        ),
      ),
      GoRoute(
        path: '${AppConstants.routeProviderAuthGate}/:type',
        name: 'providerAuthGate',
        pageBuilder: (context, state) {
          final type = ProviderType.fromRouteParam(state.pathParameters['type']);
          if (type == null) {
            return fadePage(state, const ProviderLandingScreen());
          }
          return fadePage(state, ProviderAuthGateScreen(providerType: type));
        },
      ),
      GoRoute(
        path: '${AppConstants.routeProviderLogin}/:type',
        name: 'providerLogin',
        pageBuilder: (context, state) {
          final type = ProviderType.fromRouteParam(state.pathParameters['type']);
          if (type == null) {
            return fadePage(state, const ProviderLandingScreen());
          }
          return slidePage(state, ProviderLoginScreen(providerType: type));
        },
      ),
      GoRoute(
        path: '${AppConstants.routeProviderForgotPassword}/:type',
        name: 'providerForgotPassword',
        pageBuilder: (context, state) {
          final type = ProviderType.fromRouteParam(state.pathParameters['type']);
          if (type == null) {
            return fadePage(state, const ProviderLandingScreen());
          }
          return slidePage(
            state,
            ProviderForgotPasswordScreen(providerType: type),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeProviderProfile,
        name: 'providerProfile',
        pageBuilder: (context, state) => fadePage(
          state,
          const ProviderProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeRegistrationForm,
        name: 'registrationForm',
        pageBuilder: (context, state) => slidePage(
          state,
          const RegistrationFormScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeNurseRegistration,
        name: 'nurseRegistration',
        pageBuilder: (context, state) => slidePage(
          state,
          const NurseRegistrationScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAmbulanceRegistration,
        name: 'ambulanceRegistration',
        pageBuilder: (context, state) => slidePage(
          state,
          const AmbulanceRegistrationScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeBloodBankRegistration,
        name: 'bloodBankRegistration',
        pageBuilder: (context, state) => slidePage(
          state,
          const BloodBankRegistrationScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeLabRegistration,
        name: 'labRegistration',
        pageBuilder: (context, state) => slidePage(
          state,
          const LabRegistrationScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeScanRegistration,
        name: 'scanRegistration',
        pageBuilder: (context, state) => slidePage(
          state,
          const ScanRegistrationScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeApplicationSubmitted,
        name: 'applicationSubmitted',
        pageBuilder: (context, state) => fadePage(
          state,
          const ApplicationSubmittedScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeNurseApplicationSubmitted,
        name: 'nurseApplicationSubmitted',
        pageBuilder: (context, state) => fadePage(
          state,
          const NurseApplicationSubmittedScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAmbulanceApplicationSubmitted,
        name: 'ambulanceApplicationSubmitted',
        pageBuilder: (context, state) => fadePage(
          state,
          const AmbulanceApplicationSubmittedScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeBloodBankApplicationSubmitted,
        name: 'bloodBankApplicationSubmitted',
        pageBuilder: (context, state) => fadePage(
          state,
          const BloodBankApplicationSubmittedScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeLabApplicationSubmitted,
        name: 'labApplicationSubmitted',
        pageBuilder: (context, state) => fadePage(
          state,
          const LabApplicationSubmittedScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeScanApplicationSubmitted,
        name: 'scanApplicationSubmitted',
        pageBuilder: (context, state) => fadePage(
          state,
          const ScanApplicationSubmittedScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeVideoConsult,
        name: 'videoConsult',
        pageBuilder: (context, state) {
          final extra = state.extra;
          var bookingId = state.uri.queryParameters['bookingId'] ?? '';
          String? peerName = state.uri.queryParameters['peerName'];
          if (extra is Map<String, dynamic>) {
            bookingId = extra['bookingId']?.toString() ?? bookingId;
            peerName = extra['peerName']?.toString() ?? peerName;
          }
          return slidePage(
            state,
            VideoConsultScreen(
              bookingId: bookingId,
              peerName: peerName,
            ),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeDoctorDashboard,
        name: 'doctorDashboard',
        pageBuilder: (context, state) => fadePage(
          state,
          const DoctorDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeDoctorReceptionists,
        name: 'doctorReceptionists',
        pageBuilder: (context, state) => slidePage(
          state,
          const ReceptionistManagementScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeReceptionistLogin,
        name: 'receptionistLogin',
        pageBuilder: (context, state) => fadePage(
          state,
          const ReceptionistLoginScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeReceptionistDashboard,
        name: 'receptionistDashboard',
        pageBuilder: (context, state) => fadePage(
          state,
          const ReceptionistDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeNurseDashboard,
        name: 'nurseDashboard',
        pageBuilder: (context, state) => fadePage(
          state,
          const NurseDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeProviderHomeVisitTrip,
        name: 'providerHomeVisitTrip',
        pageBuilder: (context, state) {
          final q = state.uri.queryParameters;
          return slidePage(
            state,
            ProviderTripScreen(
              bookingId: q['bookingId'] ?? '',
              role: q['role'] ?? 'doctor',
              patientName: q['patientName'],
              patientAddress: q['address'],
              patientLatitude: double.tryParse(q['lat'] ?? ''),
              patientLongitude: double.tryParse(q['lng'] ?? ''),
            ),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeNurseVisitAssessment,
        name: 'nurseVisitAssessment',
        pageBuilder: (context, state) {
          final booking = state.extra;
          if (booking is! DoctorBookingModel) {
            return fadePage(
              state,
              const Scaffold(
                body: Center(child: Text('Booking not found')),
              ),
            );
          }
          return slidePage(
            state,
            NurseVisitAssessmentScreen(booking: booking),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeNurseVisitOtp,
        name: 'nurseVisitOtp',
        pageBuilder: (context, state) {
          final booking = state.extra;
          if (booking is! DoctorBookingModel) {
            return fadePage(
              state,
              const Scaffold(
                body: Center(child: Text('Booking not found')),
              ),
            );
          }
          return slidePage(
            state,
            NurseVisitOtpScreen(booking: booking),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeProviderEarnings,
        name: 'providerEarnings',
        pageBuilder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'doctor';
          return slidePage(
            state,
            ProviderEarningsScreen(role: role),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeProviderNotifications,
        name: 'providerNotifications',
        pageBuilder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'doctor';
          return slidePage(
            state,
            ProviderNotificationsScreen(role: role),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeProviderBookingChat,
        name: 'providerBookingChat',
        pageBuilder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'doctor';
          final bookingId = state.uri.queryParameters['bookingId'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'Chat';
          return slidePage(
            state,
            ProviderBookingChatScreen(
              bookingId: bookingId,
              role: role,
              title: title,
              chatEndpoint: state.uri.queryParameters['chatPath'],
            ),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeScanDashboard,
        name: 'scanDashboard',
        pageBuilder: (context, state) => fadePage(
          state,
          const ScanDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeLabDashboard,
        name: 'labDashboard',
        pageBuilder: (context, state) => fadePage(
          state,
          const LabDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeLabPrescriptionInbox,
        name: 'labPrescriptionInbox',
        pageBuilder: (context, state) => slidePage(
          state,
          const LabPrescriptionInboxScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeLabPrescriptionDetail,
        name: 'labPrescriptionDetail',
        pageBuilder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          return slidePage(
            state,
            LabPrescriptionDetailScreen(requestId: id),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeAmbulanceDashboard,
        name: 'ambulanceDashboard',
        pageBuilder: (context, state) => fadePage(
          state,
          const AmbulanceDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAmbulanceOperations,
        name: 'ambulanceOperations',
        pageBuilder: (context, state) => slidePage(
          state,
          AmbulanceOperationsScreen(
            initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAmbulanceDriverMode,
        name: 'ambulanceDriverMode',
        pageBuilder: (context, state) => slidePage(
          state,
          const AmbulanceDriverModeScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminAmbulanceOps,
        name: 'adminAmbulanceOps',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminAmbulanceOpsScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminAmbulanceLive,
        name: 'adminAmbulanceLive',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminAmbulanceLiveScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminAmbulancePricing,
        name: 'adminAmbulancePricing',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminAmbulancePricingScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeBloodBankDashboard,
        name: 'bloodBankDashboard',
        pageBuilder: (context, state) => fadePage(
          state,
          const BloodBankDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeBloodBankOperations,
        name: 'bloodBankOperations',
        pageBuilder: (context, state) => slidePage(
          state,
          BloodBankOperationsScreen(
            initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminBloodAnalytics,
        name: 'adminBloodAnalytics',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminBloodAnalyticsScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminLogin,
        name: 'adminLogin',
        pageBuilder: (context, state) => fadePage(
          state,
          const AdminLoginScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminDashboard,
        name: 'adminDashboard',
        pageBuilder: (context, state) => fadePage(
          state,
          const AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeApprovalManagement,
        name: 'approvalManagement',
        pageBuilder: (context, state) => slidePage(
          state,
          const ApprovalManagementScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminServiceProviderManagement,
        name: 'adminServiceProviderManagement',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminServiceProviderManagementScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminDoctorSessions,
        name: 'adminDoctorSessions',
        pageBuilder: (context, state) => slidePage(
          state,
          AdminDoctorSessionsScreen(
            serviceType:
                state.uri.queryParameters['service'] ?? 'online',
            providerType:
                state.uri.queryParameters['provider'] ?? 'doctor',
          ),
        ),
      ),
      GoRoute(
        path: '${AppConstants.routeAdminDoctorSessionDetails}/:bookingId',
        name: 'adminDoctorSessionDetails',
        pageBuilder: (context, state) => slidePage(
          state,
          AdminDoctorSessionDetailsScreen(
            bookingId: state.pathParameters['bookingId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminDiagnosticSessions,
        name: 'adminDiagnosticSessions',
        pageBuilder: (context, state) => slidePage(
          state,
          AdminDiagnosticSessionsScreen(
            kind: state.uri.queryParameters['kind'] ?? 'lab',
          ),
        ),
      ),
      GoRoute(
        path:
            '${AppConstants.routeAdminDiagnosticSessionDetails}/:kind/:bookingId',
        name: 'adminDiagnosticSessionDetails',
        pageBuilder: (context, state) => slidePage(
          state,
          AdminDiagnosticSessionDetailsScreen(
            kind: state.pathParameters['kind'] ?? 'lab',
            bookingId: state.pathParameters['bookingId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminOverview,
        name: 'adminOverview',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminOverviewScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminBookings,
        name: 'adminBookings',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminBookingsScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminPatients,
        name: 'adminPatients',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminPatientsScreen(),
        ),
      ),
      GoRoute(
        path: '${AppConstants.routeAdminPatientDetails}/:patientId',
        name: 'adminPatientDetails',
        pageBuilder: (context, state) {
          final patientId = state.pathParameters['patientId'] ?? '';
          final initial = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : null;
          return slidePage(
            state,
            AdminPatientDetailsScreen(
              patientId: patientId,
              initialPatient: initial,
            ),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeAdminSupportTickets,
        name: 'adminSupportTickets',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminSupportTicketsScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminCoupons,
        name: 'adminCoupons',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminCouponsScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminCmsBanners,
        name: 'adminCmsBanners',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminCmsScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminRefunds,
        name: 'adminRefunds',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminRefundsScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdminDoctorList,
        name: 'adminDoctorList',
        pageBuilder: (context, state) => slidePage(
          state,
          AdminDoctorListScreen(
            serviceType: state.uri.queryParameters['service'],
          ),
        ),
      ),
      GoRoute(
        path: '${AppConstants.routeAdminDoctorDetails}/:doctorId',
        name: 'adminDoctorDetails',
        pageBuilder: (context, state) {
          final doctorId = state.pathParameters['doctorId'] ?? '';
          final initialDoctor = state.extra is DoctorModel
              ? state.extra as DoctorModel
              : null;
          return slidePage(
            state,
            AdminDoctorDetailsScreen(
              doctorId: doctorId,
              initialDoctor: initialDoctor,
            ),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeAdminNurseList,
        name: 'adminNurseList',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminNurseListScreen(),
        ),
      ),
      GoRoute(
        path: '${AppConstants.routeAdminNurseDetails}/:nurseId',
        name: 'adminNurseDetails',
        pageBuilder: (context, state) {
          final nurseId = state.pathParameters['nurseId'] ?? '';
          return slidePage(
            state,
            AdminNurseDetailsScreen(nurseId: nurseId),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeAdminAmbulanceList,
        name: 'adminAmbulanceList',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminAmbulanceListScreen(),
        ),
      ),
      GoRoute(
        path: '${AppConstants.routeAdminAmbulanceDetails}/:ambulanceId',
        name: 'adminAmbulanceDetails',
        pageBuilder: (context, state) {
          final ambulanceId = state.pathParameters['ambulanceId'] ?? '';
          return slidePage(
            state,
            AdminAmbulanceDetailsScreen(ambulanceId: ambulanceId),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeAdminBloodBankList,
        name: 'adminBloodBankList',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminBloodBankListScreen(),
        ),
      ),
      GoRoute(
        path: '${AppConstants.routeAdminBloodBankDetails}/:bloodBankId',
        name: 'adminBloodBankDetails',
        pageBuilder: (context, state) {
          final bloodBankId = state.pathParameters['bloodBankId'] ?? '';
          return slidePage(
            state,
            AdminBloodBankDetailsScreen(bloodBankId: bloodBankId),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeAdminLabList,
        name: 'adminLabList',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminLabListScreen(),
        ),
      ),
      GoRoute(
        path: '${AppConstants.routeAdminLabDetails}/:labId',
        name: 'adminLabDetails',
        pageBuilder: (context, state) {
          final labId = state.pathParameters['labId'] ?? '';
          return slidePage(
            state,
            AdminLabDetailsScreen(labId: labId),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeAdminScanList,
        name: 'adminScanList',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminScanListScreen(),
        ),
      ),
      GoRoute(
        path: '${AppConstants.routeAdminScanDetails}/:scanCenterId',
        name: 'adminScanDetails',
        pageBuilder: (context, state) {
          final scanCenterId = state.pathParameters['scanCenterId'] ?? '';
          return slidePage(
            state,
            AdminScanDetailsScreen(scanCenterId: scanCenterId),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Text(state.error?.toString() ?? 'Unknown route'),
      ),
    ),
  );
});
