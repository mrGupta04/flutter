import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/user_location_provider.dart';
import 'core/services/device_push_service.dart';
import 'core/services/socket_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_back_navigation.dart';
import 'features/notifications/presentation/notification_routes.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/upcoming_meeting/presentation/widgets/floating_meeting_timer_overlay.dart';
import 'features/user_auth/provider/patient_auth_provider.dart';
import 'features/user_dashboard/provider/patient_dashboard_provider.dart';
import 'router/user_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DevicePushService.instance.bootstrap();
  runApp(const ProviderScope(child: UserApp()));
}

class UserApp extends ConsumerStatefulWidget {
  const UserApp({super.key});

  @override
  ConsumerState<UserApp> createState() => _UserAppState();
}

class _UserAppState extends ConsumerState<UserApp> with WidgetsBindingObserver {
  bool _inboxBound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DevicePushService.instance.promptOsPermission();
      await _maybeRegisterPush();
      await _promptLocationOnColdStart();
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
      // Location is requested only on a fresh process start, never on resume.
    }
  }

  Future<void> _promptLocationOnColdStart() async {
    BuildContext? navContext;
    for (var i = 0; i < 10; i++) {
      navContext = ref
          .read(userRouterProvider)
          .routerDelegate
          .navigatorKey
          .currentContext;
      if (navContext != null && navContext.mounted) break;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (navContext == null || !navContext.mounted) return;
    await ref.read(userLocationProvider.notifier).ensureResolved(navContext);
  }

  Future<void> _maybeRegisterPush() async {
    final auth = ref.read(patientAuthProvider);
    if (auth.user != null) {
      await DevicePushService.instance.init(
        deviceTokenEndpoint: PushEndpoints.patient,
      );
      await _bindRealtimeInbox();
    }
  }

  Future<void> _bindRealtimeInbox() async {
    if (!_inboxBound) {
      _inboxBound = true;
      SocketService.instance.on('app_notification', _onAppNotification);
      DevicePushService.instance.onNotificationTap = (payload) {
        final router = ref.read(userRouterProvider);
        openPatientNotificationFromPayload(router, payload);
      };
    }
    await SocketService.instance.connectIfAuthenticated();
  }

  void _onAppNotification(dynamic data) {
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : const <String, dynamic>{};
    final nested = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : const <String, dynamic>{};
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
    ref.invalidate(notificationsProvider);
    try {
      ref.read(patientDashboardProvider.notifier).loadBookings();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(patientAuthProvider, (prev, next) {
      if (next.user != null && prev?.user == null) {
        DevicePushService.instance.init(
          deviceTokenEndpoint: PushEndpoints.patient,
        );
        _bindRealtimeInbox();
        ref.invalidate(notificationsProvider);
      }
    });

    final router = ref.watch(userRouterProvider);
    return MaterialApp.router(
      title: '1mg Care',
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
              const Align(
                alignment: Alignment.bottomCenter,
                child: FloatingMeetingTimerOverlay(),
              ),
            ],
          ),
        );
      },
    );
  }
}
