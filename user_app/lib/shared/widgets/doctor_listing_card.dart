import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/media_url_utils.dart';
import '../../data/models/consultation_type.dart';
import '../../data/models/doctor_model.dart';
import 'blinking_online_badge.dart';
import 'doctor_feedback_carousel.dart';

/// Action button layout for [DoctorListingCard].
enum DoctorCardActionStyle {
  /// Three buttons: Online, Clinic visit, Google Maps.
  patient,

  /// Single full-width review button (admin lists).
  admin,
}

/// Gap between stacked doctor cards in lists.
const double kDoctorCardSpacing = 12;

/// Polished marketplace card for verified doctors (home, search, listings).
class DoctorListingCard extends StatelessWidget {
  const DoctorListingCard({
    super.key,
    required this.doctor,
    this.onTap,
    this.onOnlineConsultTap,
    this.onClinicTap,
    this.onOpenMapTap,
    this.showActionButtons = true,
    this.fadeUnavailableConsultationButtons = false,
    this.actionStyle = DoctorCardActionStyle.patient,
    this.adminActionLabel = 'Review application',
    this.adminActionSubtitle = 'View profile & documents',
    this.onAdminActionTap,
    this.showVerifiedIcon = true,
    this.trailing,
    this.footerNote,
    this.showBottomDivider = true,
  });

  final DoctorModel doctor;
  final VoidCallback? onTap;
  final VoidCallback? onOnlineConsultTap;
  final VoidCallback? onClinicTap;
  final VoidCallback? onOpenMapTap;
  final bool showActionButtons;
  final bool fadeUnavailableConsultationButtons;
  final DoctorCardActionStyle actionStyle;
  final String adminActionLabel;
  final String adminActionSubtitle;
  final VoidCallback? onAdminActionTap;
  final bool showVerifiedIcon;
  final Widget? trailing;
  final String? footerNote;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    final specialty = doctor.specializations?.isNotEmpty == true
        ? doctor.specializations!.first
        : 'General Physician';
    final qualification = (doctor.qualification?.trim().isNotEmpty == true)
        ? doctor.qualification!.trim()
        : 'MBBS';
    final experienceYears = doctor.yearsOfExperience;
    final languages = doctor.languagesSpoken ?? [];
    final city = doctor.city?.trim();
    final clinic = doctor.clinicName?.trim();
    final displayName = doctor.fullName.isNotEmpty
        ? (doctor.fullName.startsWith('Dr.')
            ? doctor.fullName
            : 'Dr. ${doctor.fullName}')
        : 'Doctor';
    final isVerified =
        doctor.verificationStatus == VerificationStatus.verified;
    final cardSurface = Theme.of(context).colorScheme.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: showBottomDivider
                  ? AppColors.divider
                  : AppColors.primary.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  top: -24,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.12),
                          AppColors.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.gradientHero,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DoctorAvatar(doctor: doctor),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            displayName,
                                            style: AppTextStyles.titleSmall
                                                .copyWith(
                                              fontWeight: FontWeight.w800,
                                              height: 1.2,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ),
                                        if (trailing != null) trailing!,
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        if (doctor.isLiveNow)
                                          const BlinkingOnlineBadge(),
                                        if (doctor.hasRating)
                                          DoctorOverallRatingChip(
                                            rating: doctor.averageRating!,
                                            compact: true,
                                          ),
                                        if (showVerifiedIcon && isVerified)
                                          const _VerifiedBadge(),
                                        _SpecialtyChip(label: specialty),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _MetaRow(
                            icon: Icons.school_outlined,
                            text: experienceYears != null
                                ? '$experienceYears+ yrs · $qualification'
                                : qualification,
                          ),
                          if (city != null && city.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _MetaRow(
                              icon: Icons.location_on_outlined,
                              text: clinic != null && clinic.isNotEmpty
                                  ? '$city · $clinic'
                                  : city,
                            ),
                          ] else if (clinic != null && clinic.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _MetaRow(
                              icon: Icons.local_hospital_outlined,
                              text: clinic,
                            ),
                          ],
                          if (languages.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: languages.take(4).map((lang) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                  child: Text(
                                    lang,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          if (footerNote != null && footerNote!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              footerNote!,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          if (!showActionButtons) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: AppColors.divider),
                            const SizedBox(height: 8),
                            _ConsultationAvailabilityRow(doctor: doctor),
                          ],
                          if (showActionButtons) ...[
                            const SizedBox(height: 12),
                            if (actionStyle == DoctorCardActionStyle.patient)
                              _PatientActionButtonRow(
                                doctor: doctor,
                                fadeUnavailable:
                                    fadeUnavailableConsultationButtons,
                                onOnlineConsult: onOnlineConsultTap ?? onTap,
                                onClinic: onClinicTap ?? onTap,
                                onOpenMap: onOpenMapTap,
                              )
                            else
                              _AdminActionButton(
                                label: adminActionLabel,
                                subtitle: adminActionSubtitle,
                                onPressed: onAdminActionTap ?? onTap,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradientHero),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 12,
            color: AppColors.white.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary.withValues(alpha: 0.85)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsultationAvailabilityRow extends StatelessWidget {
  const _ConsultationAvailabilityRow({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ServicePill(
            icon: Icons.videocam_rounded,
            label: ConsultationType.onlineConsult.shortLabel,
            available: doctor.offersOnlineConsult,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ServicePill(
            icon: Icons.local_hospital_rounded,
            label: ConsultationType.visitSite.shortLabel,
            available: doctor.offersVisitSite,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ServicePill(
            icon: Icons.home_rounded,
            label: ConsultationType.bookHome.shortLabel,
            available: doctor.offersBookHome,
          ),
        ),
      ],
    );
  }
}

class _ServicePill extends StatelessWidget {
  const _ServicePill({
    required this.icon,
    required this.label,
    required this.available,
  });

  final IconData icon;
  final String label;
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      decoration: BoxDecoration(
        color: available
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: available
              ? AppColors.primary.withValues(alpha: 0.28)
              : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 13,
            color: available ? AppColors.primary : AppColors.grey600,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 9,
                height: 1.1,
                color: available
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientActionButtonRow extends StatelessWidget {
  const _PatientActionButtonRow({
    required this.doctor,
    this.fadeUnavailable = false,
    this.onOnlineConsult,
    this.onClinic,
    this.onOpenMap,
  });

  final DoctorModel doctor;
  final bool fadeUnavailable;
  final VoidCallback? onOnlineConsult;
  final VoidCallback? onClinic;
  final VoidCallback? onOpenMap;

  bool get _hasMapLocation =>
      doctor.latitude != null && doctor.longitude != null ||
      _hasAddress;

  bool get _hasAddress {
    return [
      doctor.address,
      doctor.city,
      doctor.clinicName,
    ].any((part) => part != null && part.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ConsultationActionButton(
            icon: Icons.videocam_rounded,
            label: ConsultationType.onlineConsult.shortLabel,
            available: doctor.offersOnlineConsult,
            fadeUnavailable: fadeUnavailable,
            onPressed: onOnlineConsult,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ConsultationActionButton(
            icon: Icons.local_hospital_rounded,
            label: ConsultationType.visitSite.shortLabel,
            available: doctor.offersVisitSite,
            fadeUnavailable: fadeUnavailable,
            onPressed: onClinic,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ConsultationActionButton(
            icon: Icons.map_rounded,
            label: 'Map',
            available: _hasMapLocation,
            fadeUnavailable: fadeUnavailable,
            onPressed: _hasMapLocation ? onOpenMap : null,
          ),
        ),
      ],
    );
  }
}

class _ConsultationActionButton extends StatelessWidget {
  const _ConsultationActionButton({
    required this.icon,
    required this.label,
    required this.available,
    required this.fadeUnavailable,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool available;
  final bool fadeUnavailable;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !fadeUnavailable || available;
    final child = _GradientActionButton(
      icon: icon,
      label: label,
      onPressed: isEnabled ? onPressed : null,
      filled: available,
    );

    if (!fadeUnavailable || available) {
      return child;
    }

    return Opacity(opacity: 0.4, child: child);
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.filled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            gradient: filled
                ? const LinearGradient(colors: AppColors.gradientHero)
                : null,
            color: filled ? null : AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: filled
                  ? Colors.transparent
                  : AppColors.primary.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: filled ? AppColors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: filled ? AppColors.white : AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  const _AdminActionButton({
    required this.label,
    required this.subtitle,
    this.onPressed,
  });

  final String label;
  final String subtitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.gradientHero),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(doctor.profilePicture);
    final hasImage = imageUrl.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (doctor.isLiveNow)
          BlinkingLiveAvatarBorder(
            child: _avatarImage(hasImage, imageUrl),
          )
        else
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: AppColors.gradientHero),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: _avatarImage(hasImage, imageUrl),
            ),
          ),
        if (doctor.isLiveNow)
          const Positioned(
            right: 2,
            bottom: 2,
            child: BlinkingOnlineAvatarBadge(),
          ),
      ],
    );
  }

  Widget _avatarImage(bool hasImage, String imageUrl) {
    return ClipOval(
      child: SizedBox(
        width: 64,
        height: 64,
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primarySoft.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: const Icon(
        Icons.medical_services_rounded,
        size: 32,
        color: AppColors.primary,
      ),
    );
  }
}
