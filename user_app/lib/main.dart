import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/device_push_service.dart';
import 'core/theme/app_theme.dart';
import 'features/upcoming_meeting/presentation/widgets/floating_meeting_timer_overlay.dart';
import 'features/user_auth/provider/patient_auth_provider.dart';
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
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(patientAuthProvider, (prev, next) {
      if (next.user != null && prev?.user == null) {
        DevicePushService.instance.init(
          deviceTokenEndpoint: PushEndpoints.patient,
        );
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
        return Stack(
          fit: StackFit.expand,
          children: [
            if (child != null) child,
            const Align(
              alignment: Alignment.bottomCenter,
              child: FloatingMeetingTimerOverlay(),
            ),
          ],
        );
      },
    );
  }
}
