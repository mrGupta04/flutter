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
      if (nurse.gender != null && nurse.gender!.trim().isNotEmpty)
        nurse.gender!.trim(),
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
    this.onTap,
    this.onOrder,
    this.distanceLabel,
  });

  final BloodBankModel bloodBank;
  final bool showBottomDivider;
  final VoidCallback? onTap;
  final VoidCallback? onOrder;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    final groups = bloodBank.bloodGroupsAvailable ?? [];
    final features = <String>[
      if (bloodBank.available24x7 == true) '24×7',
      if (bloodBank.emergencyBloodSupply == true) 'Emergency',
      if (bloodBank.homeDeliveryAvailable == true) 'Home delivery',
    ];
    final subtitleParts = <String>[
      if (bloodBank.address != null && bloodBank.address!.isNotEmpty)
        bloodBank.address!
      else if (bloodBank.city != null && bloodBank.city!.isNotEmpty)
        bloodBank.city!,
    ];
    final distance = distanceLabel ??
        (bloodBank.distanceKm != null
            ? '${bloodBank.distanceKm!.toStringAsFixed(1)} km'
            : null);
    final footerParts = <String>[
      if (distance != null) distance,
      ...features,
      if (bloodBank.startingPrice != null)
        'From ₹${bloodBank.startingPrice}',
    ];

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFB71C1C).withValues(alpha: 0.12),
                    backgroundImage: MediaUrlUtils.resolve(
                              bloodBank.logoUrl ?? bloodBank.profilePicture) !=
                            null
                        ? CachedNetworkImageProvider(
                            MediaUrlUtils.resolve(
                                bloodBank.logoUrl ?? bloodBank.profilePicture)!,
                          )
                        : null,
                    child: bloodBank.logoUrl == null &&
                            bloodBank.profilePicture == null
                        ? const Icon(Icons.bloodtype_rounded,
                            color: Color(0xFFB71C1C), size: 28)
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
                                bloodBank.institutionName ?? 'Blood bank',
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Icon(Icons.verified_rounded,
                                color: AppColors.primary, size: 18),
                          ],
                        ),
                        if (subtitleParts.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitleParts.join(' · '),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 14),
                            Text(
                              ' ${bloodBank.averageRating?.toStringAsFixed(1) ?? '4.5'}',
                              style: AppTextStyles.labelSmall,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: bloodBank.isOpenNow
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                bloodBank.isOpenNow ? 'Open' : 'Closed',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: bloodBank.isOpenNow
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFC62828),
                                ),
                              ),
                            ),
                            if (bloodBank.activeOffer != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.offerLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Offer',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.offer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (groups.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: groups
                      .take(6)
                      .map((g) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Text(g,
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700)),
                          ))
                      .toList(),
                ),
              ],
              if (footerParts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  footerParts.join(' · '),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      child: const Text('View details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onOrder ?? onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Order blood'),
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
