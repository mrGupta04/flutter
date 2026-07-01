import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/provider_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/ambulance_model.dart';
import '../../../../data/models/blood_bank_model.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../auth/provider/provider_auth_provider.dart';
import '../../provider/provider_profile_provider.dart';
import '../../provider/provider_status_sync.dart';

class ProviderProfileScreen extends ConsumerStatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  ConsumerState<ProviderProfileScreen> createState() =>
      _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existing = ref.read(providerProfileProvider);
      final hasProfile = existing.doctor != null ||
          existing.nurse != null ||
          existing.ambulance != null ||
          existing.bloodBank != null;
      ref.read(providerProfileProvider.notifier).loadAll(silent: hasProfile);
    });
  }

  Future<void> _logout() async {
    await ref.read(providerAuthProvider.notifier).logout();
    if (mounted) context.go(AppConstants.routeProviderLanding);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerProfileProvider);
    final status = state.verificationStatus;
    final isVerified = status == VerificationStatus.verified;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${state.providerType?.label ?? 'Partner'} profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => refreshProviderApplicationStatus(ref),
            tooltip: 'Refresh status',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: state.isLoading &&
              state.doctor == null &&
              state.nurse == null &&
              state.ambulance == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null &&
                  state.doctor == null &&
                  state.nurse == null &&
                  state.ambulance == null
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(providerProfileProvider.notifier).loadAll(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(providerProfileProvider.notifier).loadAll(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHeader(
                          name: state.displayName,
                          email: _emailFor(state),
                          status: status,
                          profilePicture: _pictureFor(state),
                        ),
                        const SizedBox(height: 16),
                        if (!isVerified)
                          OfferPromoCard(
                            title: status == VerificationStatus.rejected
                                ? 'Application not approved'
                                : 'Verification pending',
                            subtitle: status == VerificationStatus.rejected
                                ? 'Your application was not approved by admin'
                                : 'Admin will review your application within 24–48 hours',
                            badge: status == VerificationStatus.rejected
                                ? 'REJECTED'
                                : 'PENDING',
                            icon: status == VerificationStatus.rejected
                                ? Icons.cancel_outlined
                                : Icons.hourglass_top_rounded,
                          ),
                        if (!isVerified) const SizedBox(height: 16),
                        if (state.providerType != null)
                          ServiceBenefitCard(
                            icon: Icons.track_changes_rounded,
                            title: 'Application status',
                            subtitle: 'View full verification timeline',
                            color: AppColors.secondary,
                            onTap: () => _openApplicationStatus(state.providerType!),
                          ),
                        if (state.providerType != null)
                          const SizedBox(height: 12),
                        if (state.needsAvailabilityUpdate) ...[
                          GestureDetector(
                            onTap: () => context.push(
                              AppConstants.routeDoctorDashboard,
                            ),
                            child: OfferPromoCard(
                              title: 'Update weekly availability',
                              subtitle: state.availabilityReminder?.message ??
                                  'Your schedule week has ended. Set slots for next week (Sunday–Saturday).',
                              badge: 'ACTION',
                              icon: Icons.calendar_month_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ServiceBenefitCard(
                          icon: Icons.edit_rounded,
                          title: 'Edit profile',
                          subtitle: 'Update your contact and professional details',
                          color: AppColors.primary,
                          onTap: () => _showEditSheet(state),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Bookings',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (state.bookings.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy_outlined,
                                  size: 40,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No bookings yet',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Patient bookings will appear here once you are verified and live on the user app.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...state.bookings.map(
                            (b) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                tileColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppColors.divider),
                                ),
                                title: Text(b.title),
                                subtitle: Text(b.subtitle),
                                trailing: Chip(
                                  label: Text(b.status),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String? _emailFor(ProviderProfileState state) {
    return state.doctor?.email ??
        state.nurse?.email ??
        state.ambulance?.email ??
        state.bloodBank?.email;
  }

  String? _pictureFor(ProviderProfileState state) {
    return state.doctor?.profilePicture ??
        state.nurse?.profilePicture ??
        state.ambulance?.profilePicture ??
        state.bloodBank?.profilePicture;
  }

  void _openApplicationStatus(ProviderType type) {
    final route = switch (type) {
      ProviderType.doctor => AppConstants.routeApplicationSubmitted,
      ProviderType.nurse => AppConstants.routeNurseApplicationSubmitted,
      ProviderType.ambulance => AppConstants.routeAmbulanceApplicationSubmitted,
      ProviderType.bloodBank => AppConstants.routeBloodBankApplicationSubmitted,
      ProviderType.lab => AppConstants.routeLabApplicationSubmitted,
      ProviderType.scanCenter => AppConstants.routeScanApplicationSubmitted,
    };
    context.push(route);
  }

  void _showEditSheet(ProviderProfileState state) {
    if (state.providerType == ProviderType.doctor) {
      context.push(AppConstants.routeDoctorDashboard);
      return;
    }
    if (state.providerType == ProviderType.nurse && state.nurse != null) {
      _editNurse(state.nurse!);
    } else if (state.providerType == ProviderType.ambulance &&
        state.ambulance != null) {
      _editAmbulance(state.ambulance!);
    } else if (state.providerType == ProviderType.bloodBank &&
        state.bloodBank != null) {
      _editBloodBank(state.bloodBank!);
    }
  }

  void _editNurse(NurseModel nurse) {
    final mobile = TextEditingController(text: nurse.mobileNumber ?? '');
    final city = TextEditingController(text: nurse.city ?? '');
    final spec = TextEditingController(text: nurse.specialization ?? '');
    _showEditDialog(
      title: 'Edit nurse profile',
      fields: [
        CustomTextField(
          controller: mobile,
          label: 'Mobile',
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: city,
          label: 'City',
          prefixIcon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: spec,
          label: 'Specialization',
          prefixIcon: Icons.medical_services_outlined,
        ),
      ],
      onSave: () async {
        final updated = nurse.copyWith(
          mobileNumber: mobile.text.trim(),
          city: city.text.trim(),
          specialization: spec.text.trim(),
        );
        final ok =
            await ref.read(providerProfileProvider.notifier).updateNurse(updated);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok ? AppConstants.successProfileUpdated : 'Update failed',
              ),
            ),
          );
        }
      },
    );
  }

  void _editAmbulance(AmbulanceModel ambulance) {
    final mobile = TextEditingController(text: ambulance.mobileNumber ?? '');
    final city = TextEditingController(text: ambulance.city ?? '');
    final area = TextEditingController(text: ambulance.serviceArea ?? '');
    _showEditDialog(
      title: 'Edit ambulance profile',
      fields: [
        CustomTextField(
          controller: mobile,
          label: 'Mobile',
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: city,
          label: 'City',
          prefixIcon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: area,
          label: 'Service area',
          prefixIcon: Icons.map_outlined,
        ),
      ],
      onSave: () async {
        final updated = ambulance.copyWith(
          mobileNumber: mobile.text.trim(),
          city: city.text.trim(),
          serviceArea: area.text.trim(),
        );
        final ok = await ref
            .read(providerProfileProvider.notifier)
            .updateAmbulance(updated);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok ? AppConstants.successProfileUpdated : 'Update failed',
              ),
            ),
          );
        }
      },
    );
  }

  void _editBloodBank(BloodBankModel bloodBank) {
    final mobile = TextEditingController(text: bloodBank.mobileNumber ?? '');
    final city = TextEditingController(text: bloodBank.city ?? '');
    final contact = TextEditingController(text: bloodBank.contactPerson ?? '');
    _showEditDialog(
      title: 'Edit blood bank profile',
      fields: [
        CustomTextField(
          controller: mobile,
          label: 'Mobile',
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: city,
          label: 'City',
          prefixIcon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: contact,
          label: 'Contact person',
          prefixIcon: Icons.person_outline_rounded,
        ),
      ],
      onSave: () async {
        final updated = bloodBank.copyWith(
          mobileNumber: mobile.text.trim(),
          city: city.text.trim(),
          contactPerson: contact.text.trim(),
        );
        final ok = await ref
            .read(providerProfileProvider.notifier)
            .updateBloodBank(updated);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok ? AppConstants.successProfileUpdated : 'Update failed',
              ),
            ),
          );
        }
      },
    );
  }

  void _showEditDialog({
    required String title,
    required List<Widget> fields,
    required Future<void> Function() onSave,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ...fields,
            const SizedBox(height: 20),
            CustomButton(
              label: 'Save changes',
              isLoading: ref.read(providerProfileProvider).isUpdating,
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.status,
    this.profilePicture,
  });

  final String name;
  final String? email;
  final VerificationStatus? status;
  final String? profilePicture;

  @override
  Widget build(BuildContext context) {
    final statusLabel = status == VerificationStatus.verified
        ? 'Verified'
        : 'Under review';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradientHero),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.white,
                backgroundImage: profilePicture != null && profilePicture!.startsWith('http')
                    ? NetworkImage(profilePicture!)
                    : null,
                child: profilePicture == null
                    ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 36)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    if (email != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.95),
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    VerificationBadge(
                      status: statusLabel,
                      backgroundColor: AppColors.white,
                      textColor: AppColors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
