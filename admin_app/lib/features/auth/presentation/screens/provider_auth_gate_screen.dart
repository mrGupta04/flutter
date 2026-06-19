import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/provider_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../provider/provider_auth_provider.dart';

/// Login or register before accessing provider registration / profile.
class ProviderAuthGateScreen extends ConsumerWidget {
  const ProviderAuthGateScreen({super.key, required this.providerType});

  final ProviderType providerType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          OneMgHeader(
            locationLabel: 'Partner access',
            locationValue: providerType.label,
            searchHint: '',
            trailing: const Icon(Icons.arrow_back_rounded, size: 22),
            onTrailingTap: () => context.go(AppConstants.routeProviderLanding),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Welcome, ${providerType.label}',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to manage your profile and bookings, or register as a new partner.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    label: 'Login',
                    icon: Icons.login_rounded,
                    onPressed: () => context.push(
                      '${AppConstants.routeProviderLogin}/${providerType.routeParam}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomOutlineButton(
                    label: 'Register',
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: () => context.push(providerType.registerRoute),
                  ),
                  const SizedBox(height: 24),
                  const OfferPromoCard(
                    title: 'After verification',
                    subtitle:
                        'Edit your profile, view bookings, and appear in the patient app',
                    badge: 'PROFILE',
                    icon: Icons.verified_user_outlined,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigates to auth gate or profile if already signed in for this type.
Future<void> openProviderFlow(
  BuildContext context,
  WidgetRef ref,
  ProviderType type,
) async {
  final loggedIn = await ref.read(providerAuthProvider.notifier).isLoggedInAs(type);
  if (!context.mounted) return;
  if (loggedIn) {
    context.push(type.profileRoute);
    return;
  }
  context.push('${AppConstants.routeProviderAuthGate}/${type.routeParam}');
}
