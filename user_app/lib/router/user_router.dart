import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/router/router_transitions.dart';
import '../data/models/consultation_type.dart';
import '../features/doctor_registration/presentation/screens/care_listing_screen.dart';
import '../features/doctor_registration/presentation/screens/doctor_consultation_demo_screen.dart';
import '../features/doctor_registration/presentation/screens/ambulance_search_screen.dart';
import '../features/doctor_registration/presentation/screens/blood_bank_search_screen.dart';
import '../features/blood_bank/presentation/screens/blood_banks_screen.dart';
import '../features/blood_bank/presentation/screens/blood_bank_detail_screen.dart';
import '../features/blood_bank/presentation/screens/emergency_blood_request_screen.dart';
import '../features/blood_bank/presentation/screens/blood_order_confirmation_screen.dart';
import '../features/doctor_registration/presentation/screens/doctor_search_screen.dart';
import '../features/hospital_visit/presentation/screens/hospital_visit_booking_screen.dart';
import '../features/nurse_home_visit/presentation/screens/nurse_home_visit_booking_screen.dart';
import '../features/home_visit/presentation/screens/home_visit_booking_screen.dart';
import '../features/online_consult/presentation/screens/online_consult_booking_screen.dart';
import '../features/doctor_registration/presentation/screens/global_search_screen.dart';
import '../features/doctor_registration/presentation/screens/doctor_profile_screen.dart';
import '../features/doctor_registration/presentation/screens/nurse_profile_screen.dart';
import '../features/doctor_registration/presentation/screens/nurse_search_screen.dart';
import '../features/ambulance_registration/presentation/screens/ambulance_application_submitted_screen.dart';
import '../features/ambulance_registration/presentation/screens/ambulance_registration_screen.dart';
import '../features/blood_bank_registration/presentation/screens/blood_bank_application_submitted_screen.dart';
import '../features/blood_bank_registration/presentation/screens/blood_bank_registration_screen.dart';
import '../features/provider/presentation/screens/provider_landing_screen.dart';
import '../features/user_auth/presentation/screens/user_login_screen.dart';
import '../features/user_auth/presentation/screens/user_register_screen.dart';
import '../features/user_dashboard/presentation/screens/edit_patient_profile_screen.dart';
import '../features/user_dashboard/presentation/screens/user_dashboard_screen.dart';
import '../features/video_consult/presentation/screens/video_consult_screen.dart';
import '../features/labs/presentation/screens/labs_screen.dart';
import '../features/labs/presentation/screens/lab_search_screen.dart';
import '../features/scans/presentation/screens/scans_screen.dart';
import '../features/scans/presentation/screens/scan_search_screen.dart';
import '../features/scans/presentation/screens/scan_center_detail_screen.dart';
import '../features/scans/data/models/scan_procedure_model.dart';
import '../features/scan_registration/presentation/screens/scan_registration_screen.dart';
import '../features/scan_registration/presentation/screens/scan_application_submitted_screen.dart';
import '../features/lab_registration/presentation/screens/lab_registration_screen.dart';
import '../features/lab_registration/presentation/screens/lab_application_submitted_screen.dart';
import '../features/labs/data/models/lab_test_model.dart';
import '../screens/user_home_screen.dart';

/// Patient marketplace - browse verified providers only.
final userRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.routeUserHome,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppConstants.routeUserLogin,
        name: 'userLogin',
        pageBuilder: (context, state) => slidePage(
          state,
          UserLoginScreen(
            redirect: state.uri.queryParameters['redirect'],
          ),
        ),
      ),
      GoRoute(
        path: AppConstants.routeUserRegister,
        name: 'userRegister',
        pageBuilder: (context, state) => slidePage(
          state,
          UserRegisterScreen(
            redirect: state.uri.queryParameters['redirect'],
          ),
        ),
      ),
      GoRoute(
        path: AppConstants.routeUserDashboard,
        name: 'userDashboard',
        pageBuilder: (context, state) => slidePage(
          state,
          const UserDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeUserEditProfile,
        name: 'userEditProfile',
        pageBuilder: (context, state) => slidePage(
          state,
          const EditPatientProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeUserDashboardLegacy,
        redirect: (context, state) => AppConstants.routeUserDashboard,
      ),
      GoRoute(
        path: AppConstants.routeUserEditProfileLegacy,
        redirect: (context, state) => AppConstants.routeUserEditProfile,
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
        path: AppConstants.routeUserHome,
        name: 'userHome',
        pageBuilder: (context, state) => fadePage(
          state,
          const UserHomeScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeProviderLanding,
        name: 'providerLanding',
        pageBuilder: (context, state) => slidePage(
          state,
          const ProviderLandingScreen(),
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
        path: AppConstants.routeAmbulanceApplicationSubmitted,
        name: 'ambulanceApplicationSubmitted',
        pageBuilder: (context, state) => slidePage(
          state,
          const AmbulanceApplicationSubmittedScreen(),
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
        path: AppConstants.routeBloodBankApplicationSubmitted,
        name: 'bloodBankApplicationSubmitted',
        pageBuilder: (context, state) => slidePage(
          state,
          const BloodBankApplicationSubmittedScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeCareListing,
        name: 'careListing',
        pageBuilder: (context, state) {
          final roleValue = state.uri.queryParameters['role'];
          final typeValue = state.uri.queryParameters['type'];
          ConsultationType? doctorType;
          if (typeValue == 'home') {
            doctorType = ConsultationType.bookHome;
          } else if (typeValue == 'online') {
            doctorType = ConsultationType.onlineConsult;
          } else if (typeValue == 'clinic' || typeValue == 'visit') {
            doctorType = ConsultationType.visitSite;
          }
          return slidePage(
            state,
            CareListingScreen(
              initialRole: careRoleFromValue(roleValue),
              initialDoctorType: doctorType,
            ),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeConsultationDemo,
        name: 'consultationDemo',
        pageBuilder: (context, state) => slidePage(
          state,
          const DoctorConsultationDemoScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeGlobalSearch,
        name: 'globalSearch',
        pageBuilder: (context, state) => slidePage(
          state,
          GlobalSearchScreen(
            initialQuery: state.uri.queryParameters['q'],
          ),
        ),
      ),
      GoRoute(
        path: AppConstants.routeNurseHomeVisitBooking,
        name: 'nurseHomeVisitBooking',
        pageBuilder: (context, state) {
          final nurseId = state.uri.queryParameters['nurseId'] ?? '';
          return slidePage(
            state,
            NurseHomeVisitBookingScreen(nurseId: nurseId),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeHomeVisitBooking,
        name: 'homeVisitBooking',
        pageBuilder: (context, state) {
          final doctorId = state.uri.queryParameters['doctorId'] ?? '';
          return slidePage(
            state,
            HomeVisitBookingScreen(doctorId: doctorId),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeHospitalVisitBooking,
        name: 'hospitalVisitBooking',
        pageBuilder: (context, state) {
          final doctorId = state.uri.queryParameters['doctorId'] ?? '';
          return slidePage(
            state,
            HospitalVisitBookingScreen(doctorId: doctorId),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeOnlineConsultBooking,
        name: 'onlineConsultBooking',
        pageBuilder: (context, state) {
          final doctorId = state.uri.queryParameters['doctorId'] ?? '';
          return slidePage(
            state,
            OnlineConsultBookingScreen(doctorId: doctorId),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeDoctorSearch,
        name: 'doctorSearch',
        pageBuilder: (context, state) {
          final q = state.uri.queryParameters['q'];
          final city = state.uri.queryParameters['city'];
          final specialization = state.uri.queryParameters['specialization'];
          return slidePage(
            state,
            DoctorSearchScreen(
              initialQuery: q,
              initialCity: city,
              initialSpecialization: specialization,
            ),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeDoctorProfile,
        name: 'doctorProfile',
        pageBuilder: (context, state) {
          final doctorId = state.uri.queryParameters['id'] ?? '';
          return slidePage(
            state,
            DoctorProfileScreen(doctorId: doctorId),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeNurseProfile,
        name: 'nurseProfile',
        pageBuilder: (context, state) {
          final nurseId = state.uri.queryParameters['id'] ?? '';
          return slidePage(
            state,
            NurseProfileScreen(nurseId: nurseId),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeNurseSearch,
        name: 'nurseSearch',
        pageBuilder: (context, state) {
          final q = state.uri.queryParameters['q'];
          final city = state.uri.queryParameters['city'];
          final specialization = state.uri.queryParameters['specialization'];
          return slidePage(
            state,
            NurseSearchScreen(
              initialQuery: q,
              initialCity: city,
              initialSpecialization: specialization,
            ),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeAmbulanceSearch,
        name: 'ambulanceSearch',
        pageBuilder: (context, state) => slidePage(
          state,
          AmbulanceSearchScreen(
            initialQuery: state.uri.queryParameters['q'],
            initialCity: state.uri.queryParameters['city'],
            initialVehicleType: state.uri.queryParameters['vehicleType'],
          ),
        ),
      ),
      GoRoute(
        path: AppConstants.routeLabs,
        name: 'labs',
        pageBuilder: (context, state) {
          final categoryId = state.uri.queryParameters['category'];
          LabTestCategory? initialCategory;
          if (categoryId != null) {
            for (final c in LabTestCategory.values) {
              if (c.id == categoryId) {
                initialCategory = c;
                break;
              }
            }
          }
          return slidePage(
            state,
            LabsScreen(initialCategory: initialCategory),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeScans,
        name: 'scans',
        pageBuilder: (context, state) {
          final categoryId = state.uri.queryParameters['category'];
          ScanCategory? initialCategory;
          if (categoryId != null) {
            for (final c in ScanCategory.values) {
              if (c.id == categoryId) {
                initialCategory = c;
                break;
              }
            }
          }
          return slidePage(
            state,
            ScansScreen(initialCategory: initialCategory),
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeScanSearch,
        name: 'scanSearch',
        pageBuilder: (context, state) {
          final scanId = state.uri.queryParameters['scanId'] ?? '';
          final scanName = state.uri.queryParameters['scanName'] ?? 'Imaging scan';
          final categoryId = state.uri.queryParameters['category'];
          return slidePage(
            state,
            ScanSearchScreen(
              scanId: scanId,
              scanName: scanName,
              categoryId: categoryId,
            ),
          );
        },
      ),
      GoRoute(
        path: '${AppConstants.routeScanCenterDetail}/:centerId',
        name: 'scanCenterDetail',
        pageBuilder: (context, state) {
          final centerId = state.pathParameters['centerId'] ?? '';
          final scanId = state.uri.queryParameters['scanId'];
          return slidePage(
            state,
            ScanCenterDetailScreen(centerId: centerId, scanId: scanId),
          );
        },
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
        path: AppConstants.routeScanApplicationSubmitted,
        name: 'scanApplicationSubmitted',
        pageBuilder: (context, state) => slidePage(
          state,
          const ScanApplicationSubmittedScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeLabSearch,
        name: 'labSearch',
        pageBuilder: (context, state) {
          final testId = state.uri.queryParameters['testId'] ?? '';
          final testName = state.uri.queryParameters['testName'] ?? 'Diagnostic test';
          return slidePage(
            state,
            LabSearchScreen(testId: testId, testName: testName),
          );
        },
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
        path: AppConstants.routeLabApplicationSubmitted,
        name: 'labApplicationSubmitted',
        pageBuilder: (context, state) => slidePage(
          state,
          const LabApplicationSubmittedScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeBloodBanks,
        name: 'bloodBanks',
        pageBuilder: (context, state) => slidePage(
          state,
          BloodBanksScreen(
            initialBloodGroup: state.uri.queryParameters['bloodGroup'],
          ),
        ),
      ),
      GoRoute(
        path: AppConstants.routeBloodBankSearch,
        name: 'bloodBankSearch',
        pageBuilder: (context, state) => slidePage(
          state,
          BloodBankSearchScreen(
            initialQuery: state.uri.queryParameters['q'],
            initialCity: state.uri.queryParameters['city'],
            initialBloodGroup: state.uri.queryParameters['bloodGroup'],
            initialComponentType: state.uri.queryParameters['componentType'],
          ),
        ),
      ),
      GoRoute(
        path: '${AppConstants.routeBloodBankDetail}/:bloodBankId',
        name: 'bloodBankDetail',
        pageBuilder: (context, state) => slidePage(
          state,
          BloodBankDetailScreen(
            bloodBankId: state.pathParameters['bloodBankId']!,
            bloodGroup: state.uri.queryParameters['bloodGroup'],
          ),
        ),
      ),
      GoRoute(
        path: AppConstants.routeEmergencyBloodRequest,
        name: 'emergencyBloodRequest',
        pageBuilder: (context, state) => slidePage(
          state,
          const EmergencyBloodRequestScreen(),
        ),
      ),
      GoRoute(
        path: '${AppConstants.routeBloodOrderConfirmation}/:orderId',
        name: 'bloodOrderConfirmation',
        pageBuilder: (context, state) => slidePage(
          state,
          BloodOrderConfirmationScreen(
            orderId: state.pathParameters['orderId']!,
          ),
        ),
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
