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
  /// Patient-facing card with Consult Now CTA.
  patient,

  /// Admin review button (admin lists).
  admin,
}

/// Gap between stacked doctor cards in lists.
const double kDoctorCardSpacing = 12;

const Color _kDoctorOnlineBlue = Color(0xFF2563EB);
const Color _kDoctorOnlineBlueBg = Color(0xFFEFF6FF);
const Color _kDoctorHomeGreen = Color(0xFF16A34A);
const Color _kDoctorHomeGreenBg = Color(0xFFF0FDF4);
const Color _kDoctorHospitalPurple = Color(0xFF9333EA);
const Color _kDoctorHospitalPurpleBg = Color(0xFFF5F3FF);
const Color _kDoctorVerifiedPurple = Color(0xFF7C3AED);
const Color _kDoctorCtaBlue = Color(0xFF2563EB);
const Color _kDoctorCredentialBlue = Color(0xFF2563EB);

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
    this.showVerifiedIcon = false,
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
    final specs = doctor.specializations ?? const <String>[];
    final specialty =
        specs.isNotEmpty ? specs.first : 'General Physician';
    final qualification = (doctor.qualification?.trim().isNotEmpty == true)
        ? doctor.qualification!.trim()
        : 'MBBS';
    final experienceYears = doctor.yearsOfExperience;
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
    final locationLine = _locationLine;
    final timingLabel = availabilityLabel ?? 'Mon – Sat, 9:00 AM – 8:00 PM';
    final rating = doctor.hasRating ? doctor.averageRating! : 4.5;
    final reviewCount = doctor.ratingCount ?? 0;
    final reviewLabel =
        reviewCount > 0 ? '($reviewCount reviews)' : '(New)';

    return MarketplaceCardShell(
      onTap: null,
      borderColor: showBottomDivider
          ? AppColors.divider
          : const Color(0xFFE8E8EC),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DoctorProfilePhoto(
                          doctor: doctor,
                          showAvailable: doctor.isLiveNow,
                          rating: rating,
                          reviewLabel: reviewLabel,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: isVerified && trailing == null ? 92 : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1A1D26),
                                          height: 1.2,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    if (showVerifiedIcon && isVerified)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4, top: 2),
                                        child: Icon(
                                          Icons.verified_rounded,
                                          size: 18,
                                          color: _kDoctorCredentialBlue,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$qualification — $specialty',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kDoctorCredentialBlue,
                                    height: 1.25,
                                  ),
                                ),
                                if (experienceYears != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '$experienceYears+ Years Experience',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: const Color(0xFF6B7280),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                if (locationLine.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  _MetaRow(
                                    icon: Icons.local_hospital_outlined,
                                    label: locationLine,
                                    iconColor: _kDoctorCredentialBlue,
                                  ),
                                ],
                                if (footerNote != null &&
                                    footerNote!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    footerNote!,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_consultationBlocks.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _ConsultationModeRow(blocks: _consultationBlocks),
                    ],
                    if (specs.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SpecializationRow(specializations: specs),
                    ],
                  ],
                ),
              ),
              if (showActionButtons) ...[
                const SizedBox(height: 14),
                if (actionStyle == DoctorCardActionStyle.admin)
                  _AdminFooterButton(
                    label: adminActionLabel,
                    subtitle: adminActionSubtitle,
                    onPressed: onAdminActionTap ?? onTap,
                  )
                else
                  _DoctorCardFooter(
                    fee: fee,
                    timingLabel: timingLabel,
                    onConsult: slotAction,
                    enabled:
                        !fadeUnavailableConsultationButtons || slotAvailable,
                  ),
              ] else if (fee != null && fee > 0) ...[
                const SizedBox(height: 14),
                _DoctorPriceChip(fee: fee),
              ],
            ],
          ),
          if (isVerified && trailing == null)
            const Positioned(
              top: 0,
              right: 0,
              child: _VerifiedDoctorBadge(),
            ),
          if (trailing != null)
            Positioned(
              top: 0,
              right: 0,
              child: trailing!,
            ),
        ],
      ),
    );
  }

  List<_ConsultationBlockData> get _consultationBlocks {
    final blocks = <_ConsultationBlockData>[];

    if (doctor.offersOnlineConsult) {
      blocks.add(
        _ConsultationBlockData(
          icon: Icons.videocam_rounded,
          title: 'Online\nConsultation',
          subtitle: 'Video Call',
          color: _kDoctorOnlineBlue,
          backgroundColor: _kDoctorOnlineBlueBg,
          onTap: onOnlineConsultTap ?? onTap,
        ),
      );
    }
    if (doctor.offersBookHome) {
      blocks.add(
        _ConsultationBlockData(
          icon: Icons.home_rounded,
          title: 'Home\nVisit',
          subtitle: 'At Your Home',
          color: _kDoctorHomeGreen,
          backgroundColor: _kDoctorHomeGreenBg,
          onTap: onHomeVisitTap ?? onTap,
        ),
      );
    }
    if (doctor.offersVisitSite) {
      blocks.add(
        _ConsultationBlockData(
          icon: Icons.local_hospital_rounded,
          title: 'Hospital\nVisit',
          subtitle: 'At Hospital',
          color: _kDoctorHospitalPurple,
          backgroundColor: _kDoctorHospitalPurpleBg,
          onTap: onClinicTap ?? onTap,
        ),
      );
    }

    return blocks;
  }

  String get _locationLine {
    final clinic = doctor.clinicName?.trim();
    final city = doctor.city?.trim();
    if (clinic != null && clinic.isNotEmpty && city != null && city.isNotEmpty) {
      return '$clinic, $city';
    }
    if (clinic != null && clinic.isNotEmpty) return clinic;
    if (city != null && city.isNotEmpty) return city;
    return doctor.address?.trim() ?? '';
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

class _ConsultationBlockData {
  const _ConsultationBlockData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.backgroundColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onTap;
}

class _DoctorProfilePhoto extends StatelessWidget {
  const _DoctorProfilePhoto({
    required this.doctor,
    required this.showAvailable,
    required this.rating,
    required this.reviewLabel,
  });

  final DoctorModel doctor;
  final bool showAvailable;
  final double rating;
  final String reviewLabel;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(doctor.primaryPortraitUrl);
    final hasImage = imageUrl.isNotEmpty;

    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 118,
              height: 118,
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          if (showAvailable)
            const Positioned(
              top: 8,
              left: 8,
              child: LiveAvailableBadge(),
            ),
          Positioned(
            left: 8,
            bottom: 8,
            child: _PhotoRatingBadge(
              rating: rating,
              reviewLabel: reviewLabel,
            ),
          ),
        ],
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
      child: const Center(
        child: Icon(
          Icons.medical_services_rounded,
          size: 34,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _PhotoRatingBadge extends StatelessWidget {
  const _PhotoRatingBadge({
    required this.rating,
    required this.reviewLabel,
  });

  final double rating;
  final String reviewLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 14,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 3),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1D26),
                  height: 1,
                ),
              ),
            ],
          ),
          Text(
            reviewLabel,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedDoctorBadge extends StatelessWidget {
  const _VerifiedDoctorBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 14,
            color: _kDoctorVerifiedPurple,
          ),
          SizedBox(width: 4),
          Text(
            'Verified Doctor',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _kDoctorVerifiedPurple,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    this.iconColor = const Color(0xFF6B7280),
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsultationModeRow extends StatelessWidget {
  const _ConsultationModeRow({required this.blocks});

  final List<_ConsultationBlockData> blocks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _ConsultationModeBlock(data: blocks[i])),
        ],
      ],
    );
  }
}

class _ConsultationModeBlock extends StatelessWidget {
  const _ConsultationModeBlock({required this.data});

  final _ConsultationBlockData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: data.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 22, color: data.color),
              const SizedBox(height: 6),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: data.color,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: data.color.withValues(alpha: 0.85),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecializationRow extends StatelessWidget {
  const _SpecializationRow({required this.specializations});

  final List<String> specializations;

  static const _chipIcons = [
    Icons.monitor_heart_outlined,
    Icons.air_rounded,
    Icons.healing_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    const maxVisible = 3;
    final visible = specializations.take(maxVisible).toList();
    final remaining = specializations.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specializes In',
          style: AppTextStyles.labelSmall.copyWith(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < visible.length; i++)
              _SpecializationChip(
                label: visible[i],
                icon: _chipIcons[i % _chipIcons.length],
              ),
            if (remaining > 0)
              _SpecializationChip(
                label: '+$remaining more',
                icon: Icons.add_rounded,
                muted: true,
              ),
          ],
        ),
      ],
    );
  }
}

class _SpecializationChip extends StatelessWidget {
  const _SpecializationChip({
    required this.label,
    required this.icon,
    this.muted = false,
  });

  final String label;
  final IconData icon;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: muted ? _kDoctorOnlineBlueBg : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: muted
              ? _kDoctorOnlineBlue.withValues(alpha: 0.2)
              : _kDoctorOnlineBlue.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: muted ? _kDoctorOnlineBlue : _kDoctorOnlineBlue,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: muted ? _kDoctorOnlineBlue : const Color(0xFF1E40AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCardFooter extends StatelessWidget {
  const _DoctorCardFooter({
    required this.fee,
    required this.timingLabel,
    required this.onConsult,
    required this.enabled,
  });

  final int? fee;
  final String timingLabel;
  final VoidCallback? onConsult;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (fee != null && fee! > 0) ...[
          _DoctorPriceChip(fee: fee!),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: _kDoctorCredentialBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  timingLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: const Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FilledButton(
            onPressed: enabled ? onConsult : null,
            style: FilledButton.styleFrom(
              backgroundColor: _kDoctorCtaBlue,
              disabledBackgroundColor: _kDoctorCtaBlue.withValues(alpha: 0.4),
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Consult Now',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DoctorPriceChip extends StatelessWidget {
  const _DoctorPriceChip({required this.fee});

  final int fee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₹ $fee',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF059669),
              height: 1,
            ),
          ),
          Text(
            ' / Consultation',
            style: AppTextStyles.labelSmall.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminFooterButton extends StatelessWidget {
  const _AdminFooterButton({
    required this.label,
    required this.subtitle,
    this.onPressed,
  });

  final String label;
  final String subtitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
