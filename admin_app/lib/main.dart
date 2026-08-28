import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/models/provider_type.dart';
import 'core/services/device_push_service.dart';
import 'core/services/doctor_presence_lifecycle.dart';
import 'core/services/socket_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_back_navigation.dart';
import 'features/auth/provider/provider_auth_provider.dart';
import 'features/doctor_dashboard/provider/dashboard_provider.dart';
import 'features/incoming_booking/incoming_booking_alert_controller.dart';
import 'features/incoming_booking/incoming_booking_alert_overlay.dart';
import 'features/notifications/presentation/notification_routes.dart';
import 'features/nurse_dashboard/provider/nurse_dashboard_provider.dart';
import 'router/admin_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DoctorPresenceLifecycleObserver.instance.register();
  await DevicePushService.instance.bootstrap();
  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends ConsumerStatefulWidget {
  const AdminApp({super.key});

  @override
  ConsumerState<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends ConsumerState<AdminApp> with WidgetsBindingObserver {
  bool _inboxBound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DevicePushService.instance.promptOsPermission();
      await _registerPushIfNeeded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SocketService.instance.connectIfAuthenticated();
      _reloadProviderBookings();
    }
  }

  String? _roleFor(ProviderType? type) {
    if (type == ProviderType.nurse) return 'nurse';
    if (type == ProviderType.doctor) return 'doctor';
    return null;
  }

  Future<void> _registerPushIfNeeded() async {
    final auth = ref.read(providerAuthProvider);
    if (!auth.isAuthenticated) return;
    final role = _roleFor(auth.providerType);
    if (role == null) return;
    await DevicePushService.instance.init(
      deviceTokenEndpoint: DevicePushService.endpointForRole(role),
    );
    await _bindRealtimeInbox(role);
  }

  Future<void> _bindRealtimeInbox(String role) async {
    if (!_inboxBound) {
      _inboxBound = true;
      SocketService.instance.on('app_notification', _onAppNotification);
      DevicePushService.instance.onIncomingBooking = (payload) {
        ref.read(incomingBookingAlertProvider.notifier).handleNotification(payload);
      };
      DevicePushService.instance.onNotificationTap = (payload) {
        final currentRole = _roleFor(ref.read(providerAuthProvider).providerType) ??
            role;
        ref.read(incomingBookingAlertProvider.notifier).handleNotification(payload);
        openProviderNotificationFromPayload(
          ref.read(adminRouterProvider),
          currentRole,
          payload,
        );
      };
    }
    try {
      await SocketService.instance.connectIfAuthenticated();
    } catch (_) {}
  }

  void _onAppNotification(dynamic data) {
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : const <String, dynamic>{};
    final nested = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : const <String, dynamic>{};
    ref.read(incomingBookingAlertProvider.notifier).handleNotification(map);
    DevicePushService.instance.showRealtimeAlert(
      id: map['id']?.toString() ?? nested['notificationId']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Update',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? nested['type']?.toString() ?? '',
      extra: {
        ...nested,
        if (map['id'] != null) 'notificationId': map['id'],
      },
    );
    _reloadProviderBookings();
  }

  void _reloadProviderBookings() {
    final type = ref.read(providerAuthProvider).providerType;
    try {
      if (type == ProviderType.nurse) {
        ref.read(nurseDashboardProvider.notifier).loadBookings();
      } else if (type == ProviderType.doctor) {
        ref.read(doctorDashboardProvider.notifier).loadBookings();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(providerAuthProvider, (prev, next) {
      if (!next.isAuthenticated) {
        ref.read(incomingBookingAlertProvider.notifier).clearSession();
        return;
      }
      if (next.isAuthenticated &&
          (next.providerType == ProviderType.doctor ||
              next.providerType == ProviderType.nurse) &&
          !(prev?.isAuthenticated == true &&
              prev?.providerType == next.providerType)) {
        final role =
            next.providerType == ProviderType.nurse ? 'nurse' : 'doctor';
        DevicePushService.instance.init(
          deviceTokenEndpoint: DevicePushService.endpointForRole(role),
        );
        _bindRealtimeInbox(role);
      }
    });

    ref.listen(doctorDashboardProvider, (prev, next) {
      if (ref.read(providerAuthProvider).providerType != ProviderType.doctor) {
        return;
      }
      if (next.isLoadingBookings) return;
      ref.read(incomingBookingAlertProvider.notifier).syncPendingBookings(
            next.pendingHomeVisitRequests,
            providerRole: 'doctor',
            listIsFresh: next.bookingsError == null,
          );
    });
    ref.listen(nurseDashboardProvider, (prev, next) {
      if (ref.read(providerAuthProvider).providerType != ProviderType.nurse) {
        return;
      }
      if (next.isLoadingBookings) return;
      ref.read(incomingBookingAlertProvider.notifier).syncPendingBookings(
            next.pendingHomeVisitRequests,
            providerRole: 'nurse',
            listIsFresh: next.bookingsError == null,
          );
    });

    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: '1mg Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        return AppBackButtonScope(
          router: router,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              const IncomingBookingAlertOverlay(),
            ],
          ),
        );
      },
    );
  }
}
