import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/models/provider_type.dart';
import 'core/services/device_push_service.dart';
import 'core/services/doctor_presence_lifecycle.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/provider/provider_auth_provider.dart';
import 'router/admin_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DoctorPresenceLifecycleObserver.instance.register();
  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends ConsumerStatefulWidget {
  const AdminApp({super.key});

  @override
  ConsumerState<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends ConsumerState<AdminApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerPushIfNeeded());
  }

  Future<void> _registerPushIfNeeded() async {
    final auth = ref.read(providerAuthProvider);
    if (!auth.isAuthenticated) return;
    if (auth.providerType == ProviderType.doctor ||
        auth.providerType == ProviderType.nurse) {
      final role = auth.providerType == ProviderType.nurse ? 'nurse' : 'doctor';
      await DevicePushService.instance.init(
        deviceTokenEndpoint: DevicePushService.endpointForRole(role),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(providerAuthProvider, (prev, next) {
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
      }
    });

    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: '1mg Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
