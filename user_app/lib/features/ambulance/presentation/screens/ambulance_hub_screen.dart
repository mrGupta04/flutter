import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../../../data/models/ambulance_booking_model.dart';
import '../../../../data/repositories/ambulance_repository.dart';
import '../../../../shared/widgets/healthcare_ui.dart';

class AmbulanceHubScreen extends ConsumerStatefulWidget {
  const AmbulanceHubScreen({super.key});

  @override
  ConsumerState<AmbulanceHubScreen> createState() => _AmbulanceHubScreenState();
}

class _AmbulanceHubScreenState extends ConsumerState<AmbulanceHubScreen> {
  AmbulanceBookingModel? _active;
  bool _loadingActive = true;

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  Future<void> _loadActive() async {
    try {
      final response = await AmbulanceRepository().listMyBookings(group: 'active');
      if (!mounted) return;
      AmbulanceBookingModel? active;
      for (final item in response.data ?? <AmbulanceBookingModel>[]) {
        if (item.isActive) {
          active = item;
          break;
        }
      }
      setState(() {
        _active = active;
        _loadingActive = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingActive = false);
    }
  }

  Future<void> _openEmergency() async {
    final loggedIn = await ensureUserLoggedIn(
      context,
      message: 'Please log in before requesting an emergency ambulance.',
    );
    if (loggedIn && mounted) {
      context.push(AppConstants.routeAmbulanceEmergency);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ambulance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need an ambulance now?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Request emergency transportation. This is not medical advice and does not replace 112 / 108.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFB71C1C),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _openEmergency,
                    child: const Text(
                      'Request Emergency Ambulance',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const MarketplaceSectionTitle(title: 'How can we help?'),
          const SizedBox(height: 12),
          ServiceBenefitCard(
            title: 'Book Ambulance',
            subtitle: 'Schedule non-emergency transport',
            icon: Icons.event_available_rounded,
            color: AppColors.primary,
            onTap: () async {
              final loggedIn = await ensureUserLoggedIn(context);
              if (loggedIn && mounted) {
                context.push(AppConstants.routeAmbulanceScheduled);
              }
            },
          ),
          const SizedBox(height: 10),
          if (!_loadingActive && _active != null)
            ServiceBenefitCard(
              title: 'Track Active Trip',
              subtitle: _active!.statusLabel ?? 'Ambulance assigned',
              icon: Icons.near_me_rounded,
              color: const Color(0xFF1565C0),
              onTap: () => context.push(
                '${AppConstants.routeAmbulanceTrack}?bookingId=${_active!.id}',
              ),
            ),
          if (!_loadingActive && _active != null) const SizedBox(height: 10),
          ServiceBenefitCard(
            title: 'My Ambulance Bookings',
            subtitle: 'Active, upcoming and completed trips',
            icon: Icons.history_rounded,
            color: AppColors.info,
            onTap: () async {
              final loggedIn = await ensureUserLoggedIn(context);
              if (loggedIn && mounted) {
                context.push(AppConstants.routeMyAmbulanceBookings);
              }
            },
          ),
          const SizedBox(height: 10),
          ServiceBenefitCard(
            title: 'Find ambulance providers',
            subtitle: 'Browse verified services nearby',
            icon: Icons.search_rounded,
            color: AppColors.secondary,
            onTap: () => context.push(AppConstants.routeAmbulanceSearch),
          ),
          const SizedBox(height: 20),
          Text(
            'This platform arranges ambulance transportation only. '
            'It does not diagnose patients or replace professional emergency services.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
