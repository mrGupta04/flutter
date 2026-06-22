import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/upcoming_meeting/presentation/widgets/floating_meeting_timer_overlay.dart';
import 'router/user_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: UserApp()));
}

class UserApp extends ConsumerWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
