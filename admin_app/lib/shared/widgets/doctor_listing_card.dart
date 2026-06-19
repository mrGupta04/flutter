import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validation_utils.dart';
import '../../data/models/consultation_type.dart';
import '../../data/models/doctor_model.dart';

/// Action button layout for [DoctorListingCard].
enum DoctorCardActionStyle {
  /// Three buttons: Online Consult, Book Home, Visit Site.
  patient,

  /// Single full-width review button (admin lists).
  admin,
}

/// Gap between stacked doctor cards in lists.
const double kDoctorCardSpacing = 10;

/// 1mg-style vertical doctor listing card (search, home, admin lists).
class DoctorListingCard extends StatelessWidget {
  const DoctorListingCard({
    super.key,
    required this.doctor,
    this.onTap,
    this.onOnlineConsultTap,
    this.onBookHomeTap,
    this.onVisitSiteTap,
    this.showActionButtons = true,
    this.fadeUnavailableConsultationButtons = false,
    this.actionStyle = DoctorCardActionStyle.patient,
    this.adminActionLabel = 'Verify doctor',
    this.adminActionSubtitle = 'Review & publish on user app',
    this.onAdminActionTap,
    this.showVerifiedIcon = true,
    this.trailing,
    this.footerNote,
    this.showBottomDivider = true,
  });

  final DoctorModel doctor;
  final VoidCallback? onTap;
  final VoidCallback? onOnlineConsultTap;
  final VoidCallback? onBookHomeTap;
  final VoidCallback? onVisitSiteTap;
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
        ? doctor.qualification!.trim().toUpperCase()
        : 'MBBS';
    final experienceYears = doctor.yearsOfExperience;
    final experienceLine = experienceYears != null
        ? '${experienceYears} ${experienceYears == 1 ? 'YEAR' : 'YEARS'} EXP • $qualification'
        : qualification;
    final languages = doctor.languagesSpoken ?? [];
    final city = doctor.city?.trim();
    final locationLine = city != null && city.isNotEmpty ? '• $city' : null;
    final clinic = doctor.clinicName?.trim().toUpperCase() ?? '';
    final fee = doctor.lowestConsultationFee != null
        ? FormattingUtils.formatConsultationFee(doctor.lowestConsultationFee!)
        : null;
    final displayName = doctor.fullName.isNotEmpty
        ? (doctor.fullName.startsWith('Dr.')
            ? doctor.fullName
            : 'Dr. ${doctor.fullName}')
        : 'Doctor';

    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: showBottomDivider
                ? const Border(
                    bottom: BorderSide(color: AppColors.divider, width: 1),
                  )
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DoctorPhoto(doctor: doctor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            if (trailing != null) trailing!,
                            if (trailing == null &&
                                showVerifiedIcon &&
                                doctor.verificationStatus ==
                                    VerificationStatus.verified)
                              const Padding(
                                padding: EdgeInsets.only(left: 4, top: 2),
                                child: Icon(
                                  Icons.verified_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specialty,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          experienceLine,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            height: 1.3,
                          ),
                        ),
                        if (languages.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            languages.join(', '),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (locationLine != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            locationLine,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                        if (clinic.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            clinic,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (footerNote != null && footerNote!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            footerNote!,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (fee != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    fee,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
              if (showActionButtons) ...[
                const SizedBox(height: 12),
                if (actionStyle == DoctorCardActionStyle.patient)
                  _PatientActionButtonRow(
                    doctor: doctor,
                    fadeUnavailable: fadeUnavailableConsultationButtons,
                    onOnlineConsult: onOnlineConsultTap ?? onTap,
                    onBookHome: onBookHomeTap ?? onTap,
                    onVisitSite: onVisitSiteTap ?? onTap,
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
      ),
    );
  }
}

class _PatientActionButtonRow extends StatelessWidget {
  const _PatientActionButtonRow({
    required this.doctor,
    this.fadeUnavailable = false,
    this.onOnlineConsult,
    this.onBookHome,
    this.onVisitSite,
  });

  final DoctorModel doctor;
  final bool fadeUnavailable;
  final VoidCallback? onOnlineConsult;
  final VoidCallback? onBookHome;
  final VoidCallback? onVisitSite;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ConsultationActionButton(
            label: ConsultationType.onlineConsult.label,
            available: doctor.offersOnlineConsult,
            fadeUnavailable: fadeUnavailable,
            onPressed: onOnlineConsult,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ConsultationActionButton(
            label: ConsultationType.bookHome.label,
            available: doctor.offersBookHome,
            fadeUnavailable: fadeUnavailable,
            onPressed: onBookHome,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ConsultationActionButton(
            label: ConsultationType.visitSite.label,
            available: doctor.offersVisitSite,
            fadeUnavailable: fadeUnavailable,
            onPressed: onVisitSite,
          ),
        ),
      ],
    );
  }
}

class _ConsultationActionButton extends StatelessWidget {
  const _ConsultationActionButton({
    required this.label,
    required this.available,
    required this.fadeUnavailable,
    this.onPressed,
  });

  final String label;
  final bool available;
  final bool fadeUnavailable;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !fadeUnavailable || available;
    final child = _ActionChipButton(
      label: label,
      onPressed: isEnabled ? onPressed : null,
    );

    if (!fadeUnavailable || available) {
      return child;
    }

    return Opacity(opacity: 0.35, child: child);
  }
}

/// Matches [OneMgHeader] gradient (`AppColors.gradientHero`).
class _HeaderGradientButton extends StatelessWidget {
  const _HeaderGradientButton({
    required this.child,
    this.onPressed,
    this.height = 48,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.gradientHero,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _HeaderGradientButton(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              height: 1.15,
              fontSize: 11,
            ),
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
    return _HeaderGradientButton(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w400,
                height: 1.1,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorPhoto extends StatelessWidget {
  const _DoctorPhoto({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final hasImage = doctor.profilePicture != null &&
        doctor.profilePicture!.startsWith('http');

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 72,
        height: 72,
        child: hasImage
            ? Image.network(
                doctor.profilePicture!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppColors.grey100,
      child: const Icon(
        Icons.person_rounded,
        size: 36,
        color: AppColors.grey400,
      ),
    );
  }
}
