import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/device_push_service.dart';
import 'core/services/socket_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_back_navigation.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/upcoming_meeting/presentation/widgets/floating_meeting_timer_overlay.dart';
import 'features/user_auth/provider/patient_auth_provider.dart';
import 'features/user_dashboard/provider/patient_dashboard_provider.dart';
import 'router/user_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: UserApp()));
}

class UserApp extends ConsumerStatefulWidget {
  const UserApp({super.key});

  @override
  ConsumerState<UserApp> createState() => _UserAppState();
}

class _UserAppState extends ConsumerState<UserApp> {
  bool _inboxBound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRegisterPush());
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
    }
    await SocketService.instance.connectIfAuthenticated();
  }

  void _onAppNotification(dynamic data) {
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : const <String, dynamic>{};
    DevicePushService.instance.showLocalAlert(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Update',
      body: map['body']?.toString() ?? '',
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
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: '1mg Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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
