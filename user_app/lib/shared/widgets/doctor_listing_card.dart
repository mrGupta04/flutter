import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/media_url_utils.dart';
import '../../data/models/consultation_type.dart';
import '../../data/models/doctor_model.dart';
import 'blinking_online_badge.dart';
import 'marketplace_provider_card_ui.dart';

/// Action button layout for [DoctorListingCard].
enum DoctorCardActionStyle {
  /// Single "Select Slot" CTA with price row.
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
    this.onHomeVisitTap,
    this.onOpenMapTap,
    this.showActionButtons = true,
    this.fadeUnavailableConsultationButtons = false,
    this.actionStyle = DoctorCardActionStyle.patient,
    this.consultationFilter,
    this.adminActionLabel = 'Review application',
    this.adminActionSubtitle = 'View profile & documents',
    this.onAdminActionTap,
    this.showVerifiedIcon = true,
    this.trailing,
    this.footerNote,
    this.showBottomDivider = true,
    this.availabilityLabel,
    this.originalFee,
  });

  final DoctorModel doctor;
  final VoidCallback? onTap;
  final VoidCallback? onOnlineConsultTap;
  final VoidCallback? onClinicTap;
  final VoidCallback? onHomeVisitTap;
  final VoidCallback? onOpenMapTap;
  final bool showActionButtons;
  final bool fadeUnavailableConsultationButtons;
  final DoctorCardActionStyle actionStyle;
  final ConsultationType? consultationFilter;
  final String adminActionLabel;
  final String adminActionSubtitle;
  final VoidCallback? onAdminActionTap;
  final bool showVerifiedIcon;
  final Widget? trailing;
  final String? footerNote;
  final bool showBottomDivider;
  final String? availabilityLabel;
  final int? originalFee;

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
    final displayName = doctor.fullName.isNotEmpty
        ? (doctor.fullName.startsWith('Dr.')
            ? doctor.fullName
            : 'Dr. ${doctor.fullName}')
        : 'Doctor';
    final isVerified =
        doctor.verificationStatus == VerificationStatus.verified;
    final tags = doctor.specializations ?? const <String>[];
    final fee = _displayFee;
    final slotAction = _slotAction;
    final slotAvailable = _slotAvailable;

    return MarketplaceCardShell(
      onTap: onTap,
      borderColor: showBottomDivider
          ? AppColors.divider
          : AppColors.primary.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MarketplaceProviderHeader(
            name: displayName,
            specialty: specialty,
            metaLine: experienceYears != null
                ? '$experienceYears+ years exp. • $qualification'
                : qualification,
            tags: tags,
            languagesLine: languages.isNotEmpty
                ? 'Speaks: ${languages.join(', ')}'
                : null,
            avatar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DoctorAvatar(doctor: doctor),
                if (doctor.isLiveNow) ...[
                  const SizedBox(height: 6),
                  const BlinkingOnlineBadge(compact: true),
                ],
              ],
            ),
            trailing: trailing ??
                (showVerifiedIcon && isVerified
                    ? const _VerifiedIcon()
                    : null),
          ),
          if (footerNote != null && footerNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              footerNote!,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          MarketplaceStatsBar(
            leftIcon: Icons.thumb_up_alt_outlined,
            leftLabel: _happyPatientsLabel,
            rightIcon: Icons.chat_bubble_outline_rounded,
            rightLabel: _consultsLabel,
          ),
          if (showActionButtons) ...[
            const SizedBox(height: 12),
            MarketplacePriceActionRow(
              price: fee,
              originalPrice: originalFee,
              buttonLabel: 'Select Slot',
              onButtonPressed: slotAction,
              availabilityLabel: availabilityLabel ?? _defaultAvailabilityLabel,
              buttonEnabled: !fadeUnavailableConsultationButtons || slotAvailable,
              useAdminButton: actionStyle == DoctorCardActionStyle.admin,
              adminButtonLabel: adminActionLabel,
              adminButtonSubtitle: adminActionSubtitle,
              onAdminPressed: onAdminActionTap ?? onTap,
            ),
          ] else if (fee != null && fee > 0) ...[
            const SizedBox(height: 12),
            MarketplacePriceActionRow(
              price: fee,
              originalPrice: originalFee,
              showButton: false,
            ),
          ],
        ],
      ),
    );
  }

  int? get _displayFee {
    if (consultationFilter != null) {
      return doctor.feeForConsultationType(consultationFilter!);
    }
    return doctor.lowestConsultationFee;
  }

  String get _happyPatientsLabel {
    if (doctor.hasRating) {
      final percent = ((doctor.averageRating! / 5) * 100).round();
      return '$percent% Happy Patients';
    }
    return 'New on platform';
  }

  String get _consultsLabel {
    final count = doctor.ratingCount ?? 0;
    if (count > 0) return '$count Consults';
    return 'Book first consult';
  }

  String? get _defaultAvailabilityLabel {
    if (doctor.isLiveNow) return 'Available: Online now';
    return 'Available: Check slots';
  }

  bool get _slotAvailable {
    if (consultationFilter != null) {
      return doctor.offersConsultationType(consultationFilter!);
    }
    return doctor.hasAnyConsultationOption;
  }

  VoidCallback? get _slotAction {
    if (actionStyle == DoctorCardActionStyle.admin) {
      return onAdminActionTap ?? onTap;
    }

    if (consultationFilter != null) {
      switch (consultationFilter!) {
        case ConsultationType.onlineConsult:
          return doctor.offersOnlineConsult
              ? (onOnlineConsultTap ?? onTap)
              : null;
        case ConsultationType.bookHome:
          return doctor.offersBookHome ? (onHomeVisitTap ?? onTap) : null;
        case ConsultationType.visitSite:
          return doctor.offersVisitSite ? (onClinicTap ?? onTap) : null;
      }
    }

    if (doctor.offersOnlineConsult) return onOnlineConsultTap ?? onTap;
    if (doctor.offersVisitSite) return onClinicTap ?? onTap;
    if (doctor.offersBookHome) return onHomeVisitTap ?? onTap;
    if (_hasMapLocation) return onOpenMapTap ?? onTap;
    return onTap;
  }

  bool get _hasMapLocation =>
      doctor.latitude != null && doctor.longitude != null ||
      [
        doctor.address,
        doctor.city,
        doctor.clinicName,
      ].any((part) => part != null && part.trim().isNotEmpty);
}

class _VerifiedIcon extends StatelessWidget {
  const _VerifiedIcon();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 4),
      child: Icon(
        Icons.verified_rounded,
        size: 18,
        color: AppColors.primary,
      ),
    );
  }
}

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(doctor.primaryPortraitUrl);
    final hasImage = imageUrl.isNotEmpty;
    final image = hasImage
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => _placeholder(),
            errorWidget: (_, __, ___) => _placeholder(),
          )
        : _placeholder();

    final avatar = MarketplaceSquareAvatar(child: image);

    if (!doctor.isLiveNow) return avatar;

    return BlinkingLiveAvatarBorder(
      borderRadius: 10,
      child: avatar,
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
      child: const Center(
        child: Icon(
          Icons.medical_services_rounded,
          size: 32,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
