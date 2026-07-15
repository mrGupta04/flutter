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
  /// Patient-facing card with Select Slot CTA.
  patient,

  /// Admin review button (admin lists).
  admin,
}

/// Gap between stacked doctor cards in lists.
const double kDoctorCardSpacing = 12;

/// Marketplace card for verified doctors (home, search, listings).
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
    this.treatmentTags,
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
  final List<String>? treatmentTags;

  @override
  Widget build(BuildContext context) {
    final specs = doctor.specializations ?? const <String>[];
    final specialty = _primarySpecialtyLabel(specs);
    final qualification = (doctor.qualification?.trim().isNotEmpty == true)
        ? doctor.qualification!.trim()
        : 'MBBS';
    final experienceYears = doctor.yearsOfExperience;
    final metaLine = experienceYears != null
        ? '$experienceYears+ years exp. • $qualification'
        : qualification;
    final displayName = doctor.fullName.isNotEmpty
        ? (doctor.fullName.startsWith('Dr.')
            ? doctor.fullName
            : 'Dr. ${doctor.fullName}')
        : 'Doctor';
    final isVerified =
        doctor.verificationStatus == VerificationStatus.verified;
    final fee = _displayFee;
    final slotAction = _slotAction;
    final slotAvailable = _slotAvailable;
    final languages = doctor.languagesSpoken ?? const <String>[];
    final languagesLine = languages.isNotEmpty
        ? 'Speaks: ${languages.join(', ')}'
        : null;
    final tags = _resolveTreatmentTags(specs, specialty);
    final happyPercent = _happyPatientsPercent;
    final consultCount = doctor.ratingCount ?? 0;
    final availabilityText = _formatAvailabilityLabel(availabilityLabel);

    Widget? headerTrailing = trailing;
    if (headerTrailing == null && showVerifiedIcon && isVerified) {
      headerTrailing = const Icon(
        Icons.verified_rounded,
        size: 16,
        color: AppColors.primary,
      );
    }

    return MarketplaceCardShell(
      onTap: null,
      borderColor: showBottomDivider
          ? AppColors.divider
          : const Color(0xFFE8E8EC),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MarketplaceProviderHeader(
                  name: displayName,
                  specialty: specialty,
                  metaLine: metaLine,
                  tags: tags,
                  languagesLine: languagesLine,
                  trailing: headerTrailing,
                  avatar: _DoctorAvatar(
                    doctor: doctor,
                    showLiveBadge: doctor.isLiveNow,
                  ),
                ),
                if (footerNote != null && footerNote!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    footerNote!.trim(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                MarketplaceStatsBar(
                  leftIcon: Icons.thumb_up_outlined,
                  leftLabel: '${happyPercent ?? 96}% Happy Patients',
                  rightIcon: Icons.chat_bubble_outline_rounded,
                  rightLabel: consultCount > 0
                      ? '$consultCount Consults'
                      : 'New on platform',
                ),
              ],
            ),
          ),
          if (showActionButtons) ...[
            const SizedBox(height: 14),
            if (actionStyle == DoctorCardActionStyle.admin)
              MarketplacePriceActionRow(
                useAdminButton: true,
                adminButtonLabel: adminActionLabel,
                adminButtonSubtitle: adminActionSubtitle,
                onAdminPressed: onAdminActionTap ?? onTap,
              )
            else
              MarketplacePriceActionRow(
                price: fee,
                originalPrice: originalFee,
                availabilityLabel: availabilityText,
                onButtonPressed: slotAction,
                buttonEnabled:
                    !fadeUnavailableConsultationButtons || slotAvailable,
                showButton: slotAction != null || fee != null,
              ),
          ] else if (fee != null && fee > 0) ...[
            const SizedBox(height: 14),
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

  int? get _happyPatientsPercent {
    if (!doctor.hasRating) return null;
    return ((doctor.averageRating! / 5) * 100).round().clamp(0, 100);
  }

  List<String> _resolveTreatmentTags(List<String> specs, String specialty) {
    if (treatmentTags != null && treatmentTags!.isNotEmpty) {
      return treatmentTags!;
    }
    if (specs.length <= 1) return const [];
    return specs
        .where((spec) => spec.trim().toLowerCase() != specialty.toLowerCase())
        .map((spec) => spec.trim())
        .where((spec) => spec.isNotEmpty)
        .toList();
  }

  String? _formatAvailabilityLabel(String? label) {
    final trimmed = label?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed.toLowerCase().startsWith('available')) return trimmed;
    return 'Available: $trimmed';
  }

  static String _primarySpecialtyLabel(List<String> specs) {
    if (specs.isEmpty) return 'General Physician';
    for (final spec in specs) {
      final lower = spec.toLowerCase();
      if (lower.contains('physician') ||
          lower.contains('medicine') ||
          lower.contains('surgeon') ||
          lower.contains('surgery') ||
          lower.contains('general')) {
        return spec;
      }
    }
    return specs.first;
  }

  int? get _displayFee {
    if (consultationFilter != null) {
      return doctor.feeForConsultationType(consultationFilter!);
    }
    return doctor.lowestConsultationFee;
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

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({
    required this.doctor,
    required this.showLiveBadge,
  });

  final DoctorModel doctor;
  final bool showLiveBadge;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(doctor.primaryPortraitUrl);
    final hasImage = imageUrl.isNotEmpty;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          MarketplaceSquareAvatar(
            size: 96,
            borderRadius: 12,
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    placeholder: (_, __) => _placeholder(),
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          if (showLiveBadge)
            const Positioned(
              top: 6,
              left: 6,
              child: LiveAvailableBadge(),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppColors.grey100,
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
