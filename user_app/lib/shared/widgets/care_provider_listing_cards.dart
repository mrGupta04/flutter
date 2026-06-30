import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/media_url_utils.dart';
import '../../data/models/ambulance_model.dart';
import '../../data/models/blood_bank_model.dart';
import '../../data/models/nurse_model.dart';

class NurseListingCard extends StatelessWidget {
  const NurseListingCard({
    super.key,
    required this.nurse,
    this.showBottomDivider = false,
    this.onTap,
    this.distanceLabel,
  });

  final NurseModel nurse;
  final bool showBottomDivider;
  final VoidCallback? onTap;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    final qualification = nurse.qualification?.trim();
    final specialization = nurse.specialization?.trim();
    final experience = nurse.yearsOfExperience;
    final subtitleParts = <String>[
      if (qualification != null && qualification.isNotEmpty) qualification,
      if (specialization != null && specialization.isNotEmpty) specialization,
      if (experience != null) '$experience yrs exp',
      if (nurse.city != null && nurse.city!.isNotEmpty) nurse.city!,
    ];
    final services = <String>[
      if (nurse.availableForHomeVisit == true) 'Home visit',
      if (nurse.shiftAvailability != null && nurse.shiftAvailability!.isNotEmpty)
        nurse.shiftAvailability!,
    ];
    final footerParts = <String>[
      if (distanceLabel != null && distanceLabel!.isNotEmpty) distanceLabel!,
      ...services,
    ];

    return _CareListingShell(
      title: nurse.displayName,
      subtitle: subtitleParts.join(' · '),
      footer: footerParts.isEmpty ? null : footerParts.join(' · '),
      icon: Icons.health_and_safety_rounded,
      iconColor: AppColors.secondary,
      imageUrl: MediaUrlUtils.resolve(nurse.profilePicture),
      showBottomDivider: showBottomDivider,
      trailing: nurse.mobileNumber,
      onTap: onTap,
    );
  }
}

class AmbulanceListingCard extends StatelessWidget {
  const AmbulanceListingCard({
    super.key,
    required this.ambulance,
    this.showBottomDivider = false,
  });

  final AmbulanceModel ambulance;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    final vehicles = ambulance.vehicleTypes ?? [];
    final subtitleParts = <String>[
      if (ambulance.city != null && ambulance.city!.isNotEmpty) ambulance.city!,
      if (vehicles.isNotEmpty) vehicles.join(', '),
      if (ambulance.serviceArea != null && ambulance.serviceArea!.isNotEmpty)
        'Area: ${ambulance.serviceArea}',
    ];

    return _CareListingShell(
      title: ambulance.serviceName ?? 'Ambulance service',
      subtitle: subtitleParts.join(' · '),
      footer: ambulance.available24x7 == true ? '24x7 emergency' : 'Limited hours',
      icon: Icons.local_shipping_rounded,
      iconColor: const Color(0xFF1565C0),
      imageUrl: MediaUrlUtils.resolve(ambulance.profilePicture),
      showBottomDivider: showBottomDivider,
      trailing: ambulance.emergencyContact ?? ambulance.mobileNumber,
    );
  }
}

class BloodBankListingCard extends StatelessWidget {
  const BloodBankListingCard({
    super.key,
    required this.bloodBank,
    this.showBottomDivider = false,
  });

  final BloodBankModel bloodBank;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    final groups = bloodBank.bloodGroupsAvailable ?? [];
    final features = <String>[
      if (bloodBank.available24x7 == true) '24x7',
      if (bloodBank.hasApheresis == true) 'Apheresis',
      if (bloodBank.hasComponentSeparation == true) 'Component separation',
    ];
    final subtitleParts = <String>[
      if (bloodBank.city != null && bloodBank.city!.isNotEmpty) bloodBank.city!,
      if (groups.isNotEmpty) groups.join(', '),
    ];

    return _CareListingShell(
      title: bloodBank.institutionName ?? 'Blood bank',
      subtitle: subtitleParts.join(' · '),
      footer: features.isEmpty ? null : features.join(' · '),
      icon: Icons.bloodtype_rounded,
      iconColor: const Color(0xFFB71C1C),
      imageUrl: MediaUrlUtils.resolve(bloodBank.profilePicture),
      showBottomDivider: showBottomDivider,
      trailing: bloodBank.emergencyContact ?? bloodBank.mobileNumber,
    );
  }
}

class _CareListingShell extends StatelessWidget {
  const _CareListingShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.footer,
    this.trailing,
    this.imageUrl,
    this.showBottomDivider = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? footer;
  final String? trailing;
  final String? imageUrl;
  final IconData icon;
  final Color iconColor;
  final bool showBottomDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: iconColor.withValues(alpha: 0.12),
                backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(imageUrl!)
                    : null,
                child: imageUrl == null || imageUrl!.isEmpty
                    ? Icon(icon, color: iconColor, size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (footer != null && footer!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        footer!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (trailing != null && trailing!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Contact: $trailing',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (onTap != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Tap to view full profile',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.grey400,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
