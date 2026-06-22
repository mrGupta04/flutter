import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/router/router_transitions.dart';
import '../core/services/token_storage.dart';
import '../features/admin/presentation/screens/admin_ambulance_details_screen.dart';
import '../features/admin/presentation/screens/admin_ambulance_list_screen.dart';
import '../features/admin/presentation/screens/admin_blood_bank_details_screen.dart';
import '../features/admin/presentation/screens/admin_blood_bank_list_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../data/models/doctor_model.dart';
import '../features/admin/presentation/screens/admin_doctor_details_screen.dart';
import '../features/admin/presentation/screens/admin_doctor_list_screen.dart';
import '../features/admin/presentation/screens/admin_login_screen.dart';
import '../features/admin/presentation/screens/admin_nurse_details_screen.dart';
import '../features/admin/presentation/screens/admin_nurse_list_screen.dart';
import '../features/ambulance_registration/presentation/screens/ambulance_application_submitted_screen.dart';
import '../features/ambulance_registration/presentation/screens/ambulance_registration_screen.dart';
import '../features/blood_bank_registration/presentation/screens/blood_bank_application_submitted_screen.dart';
import '../features/blood_bank_registration/presentation/screens/blood_bank_registration_screen.dart';
import '../features/doctor_dashboard/presentation/screens/doctor_dashboard_screen.dart';
import '../features/doctor_registration/presentation/screens/application_submitted_screen.dart';
import '../features/doctor_registration/presentation/screens/registration_form_screen.dart';
import '../features/nurse_registration/presentation/screens/nurse_application_submitted_screen.dart';
import '../features/nurse_registration/presentation/screens/nurse_registration_screen.dart';
import '../features/auth/presentation/screens/provider_auth_gate_screen.dart';
import '../features/auth/presentation/screens/provider_login_screen.dart';
import '../core/models/provider_type.dart';
import '../features/provider/presentation/screens/provider_landing_screen.dart';
import '../features/video_consult/presentation/screens/video_consult_screen.dart';
import '../features/provider/presentation/screens/provider_profile_screen.dart';
import '../features/auth/provider/provider_auth_provider.dart';
import '../features/admin/provider/admin_auth_provider.dart';

bool _isAdminProtectedRoute(String location) {
  return location.startsWith(AppConstants.routeAdminDashboard) ||
      location.startsWith(AppConstants.routeAdminDoctorList) ||
      location.startsWith(AppConstants.routeAdminDoctorDetails) ||
      location.startsWith(AppConstants.routeAdminNurseList) ||
      location.startsWith(AppConstants.routeAdminNurseDetails) ||
      location.startsWith(AppConstants.routeAdminAmbulanceList) ||
      location.startsWith(AppConstants.routeAdminAmbulanceDetails) ||
      location.startsWith(AppConstants.routeAdminBloodBankList) ||
      location.startsWith(AppConstants.routeAdminBloodBankDetails);
}

/// Admin app — provider registration + admin verification.
final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.routeProviderLanding,
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final loc = state.matchedLocation;

      if (loc == AppConstants.routeDoctorDashboard ||
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
        if (ref.read(adminAuthProvider).isAuthenticated) {
          return null;
        }
        final adminToken = await TokenStorage.instance.getAdminToken();
        if (adminToken == null || adminToken.isEmpty) {
          return AppConstants.routeAdminLogin;
        }
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
        path: AppConstants.routeAdminDoctorList,
        name: 'adminDoctorList',
        pageBuilder: (context, state) => slidePage(
          state,
          const AdminDoctorListScreen(),
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
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Text(state.error?.toString() ?? 'Unknown route'),
      ),
    ),
  );
});
