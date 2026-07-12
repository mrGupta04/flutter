import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/media_url_utils.dart';
import '../../data/models/ambulance_model.dart';
import '../../data/models/blood_bank_model.dart';
import '../../data/models/doctor_model.dart';
import '../../data/models/nurse_model.dart';

import 'blinking_online_badge.dart';

/// Nurse profile card accent — app theme green.
const Color kNurseCardAccent = AppColors.primary;
const Color kNurseCardAccentDark = AppColors.primaryDark;
const Color kNurseCardAccentLight = AppColors.primaryLight;
const Color kNurseCardAccentChip = AppColors.secondaryLight;

/// Estimated height for nurse cards in home preview lists.
const double kNurseListingCardHeight = 340;

/// Nurse accent gradient for cards and profiles.
const List<Color> kNurseGradient = AppColors.gradientNurse;

class NurseListingCard extends StatelessWidget {
  const NurseListingCard({
    super.key,
    required this.nurse,
    this.showBottomDivider = false,
    this.showActionButtons = true,
    this.onTap,
    this.onBookHomeVisit,
    this.onOpenMapTap,
    this.distanceLabel,
    this.availabilityLabel,
    this.originalFee,
  });

  final NurseModel nurse;
  final bool showBottomDivider;
  final bool showActionButtons;
  final VoidCallback? onTap;
  final VoidCallback? onBookHomeVisit;
  final VoidCallback? onOpenMapTap;
  final String? distanceLabel;
  final String? availabilityLabel;
  final int? originalFee;

  @override
  Widget build(BuildContext context) {
    final qualification = nurse.qualification?.trim();
    final designation = nurse.specialization?.trim().isNotEmpty == true
        ? nurse.specialization!.trim()
        : 'Registered Nurse';
    final experience = nurse.yearsOfExperience;
    final city = nurse.city?.trim();
    final state = nurse.state?.trim();
    final isVerified =
        nurse.verificationStatus == VerificationStatus.verified;
    final isLiveNow = nurse.isLiveNow;
    final bookable = nurse.availableForHomeVisit != false;
    final skills = nurse.nursingSkills?.where((s) => s.trim().isNotEmpty).toList() ??
        const <String>[];
    final locationParts = <String>[
      if (city != null && city.isNotEmpty) city,
      if (state != null && state.isNotEmpty) state,
    ];
    final locationLine = locationParts.join(', ');
    final availabilityText = availabilityLabel?.trim().isNotEmpty == true
        ? availabilityLabel!.trim()
        : (nurse.shiftAvailability?.trim().isNotEmpty == true
            ? nurse.shiftAvailability!.trim()
            : 'Flexible hours');
    final fee = nurse.homeVisitFee;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: showBottomDivider
                ? AppColors.divider
                : const Color(0xFFE8E8EC),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _NurseProfileImage(
                              nurse: nurse,
                              showAvailable: isLiveNow,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 76),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nurse.displayName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A1D26),
                                        height: 1.2,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      designation,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: kNurseCardAccent,
                                        height: 1.2,
                                      ),
                                    ),
                                    if (qualification != null &&
                                        qualification.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        qualification,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: const Color(0xFF6B7280),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    if (experience != null) ...[
                                      const SizedBox(height: 8),
                                      _MetaRow(
                                        icon: Icons.work_outline_rounded,
                                        label: '$experience+ Years Experience',
                                      ),
                                    ],
                                    if (locationLine.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      _MetaRow(
                                        icon: Icons.location_on_outlined,
                                        label: locationLine,
                                        onTap: onOpenMapTap,
                                      ),
                                    ],
                                    if (distanceLabel != null &&
                                        distanceLabel!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        distanceLabel!.trim(),
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: kNurseCardAccent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                    if (skills.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      _NurseSkillChips(skills: skills),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isVerified) const _VerifiedBadge(),
                              if (isVerified) const SizedBox(height: 6),
                              _RatingBadge(rating: nurse.cardDisplayRating),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFECECF0),
                    ),
                    const SizedBox(height: 12),
                    _NurseServiceStatsBar(
                      serviceType: bookable ? 'Home Visit' : 'Unavailable',
                      availability: availabilityText,
                      fee: fee,
                      originalFee: originalFee,
                    ),
                  ],
                ),
              ),
              if (showActionButtons) ...[
                const SizedBox(height: 14),
                _NurseBookNowButton(
                  enabled: bookable,
                  onPressed: bookable ? (onBookHomeVisit ?? onTap) : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NurseProfileImage extends StatelessWidget {
  const _NurseProfileImage({
    required this.nurse,
    required this.showAvailable,
  });

  final NurseModel nurse;
  final bool showAvailable;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(nurse.profilePicture);
    final hasImage = imageUrl.isNotEmpty;

    return SizedBox(
      width: 118,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          if (showAvailable) ...[
            const SizedBox(height: 8),
            const Center(child: LiveAvailableBadge()),
          ],
        ],
      ),
    );
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kNurseCardAccentLight,
            kNurseCardAccent.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.health_and_safety_rounded,
          size: 34,
          color: kNurseCardAccent,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kNurseCardAccent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 13,
            color: AppColors.white,
          ),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 13,
            color: AppColors.tertiary,
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D26),
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(icon, size: 14, color: kNurseCardAccent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              height: 1.3,
            ),
          ),
        ),
      ],
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: row,
    );
  }
}

class _NurseSkillChips extends StatelessWidget {
  const _NurseSkillChips({required this.skills});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    const maxVisible = 3;
    final visible = skills.take(maxVisible).toList();
    final remaining = skills.length - visible.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final skill in visible) _NurseSkillChip(label: skill),
        if (remaining > 0) _NurseMoreSkillsChip(label: '+$remaining more'),
      ],
    );
  }
}

class _NurseSkillChip extends StatelessWidget {
  const _NurseSkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kNurseCardAccentChip,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _nurseSkillIcon(label),
            size: 13,
            color: kNurseCardAccentDark,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: kNurseCardAccentDark,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _NurseMoreSkillsChip extends StatelessWidget {
  const _NurseMoreSkillsChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: kNurseCardAccent,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

IconData _nurseSkillIcon(String skill) {
  final value = skill.toLowerCase();
  if (value.contains('elder')) return Icons.person_outline_rounded;
  if (value.contains('patient') || value.contains('care')) {
    return Icons.volunteer_activism_rounded;
  }
  if (value.contains('injection') || value.contains('iv')) {
    return Icons.vaccines_rounded;
  }
  if (value.contains('wound') || value.contains('dressing')) {
    return Icons.healing_rounded;
  }
  if (value.contains('vital') || value.contains('monitor')) {
    return Icons.monitor_heart_outlined;
  }
  if (value.contains('catheter')) return Icons.water_drop_outlined;
  return Icons.medical_services_outlined;
}

class _NurseServiceStatsBar extends StatelessWidget {
  const _NurseServiceStatsBar({
    required this.serviceType,
    required this.availability,
    required this.fee,
    this.originalFee,
  });

  final String serviceType;
  final String availability;
  final int? fee;
  final int? originalFee;

  @override
  Widget build(BuildContext context) {
    final chargeLabel = fee != null && fee! > 0 ? '₹$fee / Visit' : 'On request';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _NurseStatColumn(
                icon: Icons.home_rounded,
                label: 'Service Type',
                value: serviceType,
              ),
            ),
            const _NurseStatDivider(),
            Expanded(
              child: _NurseStatColumn(
                icon: Icons.schedule_rounded,
                label: 'Availability',
                value: availability,
              ),
            ),
            const _NurseStatDivider(),
            Expanded(
              child: _NurseStatColumn(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Charges',
                value: chargeLabel,
                strikeValue: originalFee != null &&
                        fee != null &&
                        originalFee! > fee!
                    ? '₹$originalFee'
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NurseStatDivider extends StatelessWidget {
  const _NurseStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: const Color(0xFFE5E7EB),
    );
  }
}

class _NurseStatColumn extends StatelessWidget {
  const _NurseStatColumn({
    required this.icon,
    required this.label,
    required this.value,
    this.strikeValue,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? strikeValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: kNurseCardAccent),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF9AA3AF),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        if (strikeValue != null) ...[
          Text(
            strikeValue!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFC8CDD4),
              decoration: TextDecoration.lineThrough,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF1A1D26),
            fontWeight: FontWeight.w800,
            fontSize: 12,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _NurseBookNowButton extends StatelessWidget {
  const _NurseBookNowButton({
    required this.enabled,
    this.onPressed,
  });

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: kNurseCardAccent,
          disabledBackgroundColor: AppColors.grey200,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Book Now',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class AmbulanceListingCard extends StatelessWidget {
  const AmbulanceListingCard({
    super.key,
    required this.ambulance,
    this.showBottomDivider = false,
    this.onTap,
  });

  final AmbulanceModel ambulance;
  final bool showBottomDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final vehicles = ambulance.vehicleTypes ?? [];
    final subtitleParts = <String>[
      if (ambulance.city != null && ambulance.city!.isNotEmpty) ambulance.city!,
      if (vehicles.isNotEmpty) vehicles.join(', '),
    ];

    return _ModernCareCard(
      accentGradient: const [Color(0xFF1565C0), Color(0xFF1976D2)],
      title: ambulance.serviceName ?? 'Ambulance service',
      subtitle: subtitleParts.join(' · '),
      footer: ambulance.available24x7 == true ? '24×7 emergency' : 'Limited hours',
      icon: Icons.local_shipping_rounded,
      iconColor: const Color(0xFF1565C0),
      imageUrl: MediaUrlUtils.resolve(ambulance.profilePicture),
      onTap: onTap,
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
      if (bloodBank.startingPrice != null) 'From ₹${bloodBank.startingPrice}',
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB71C1C).withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        const Color(0xFFB71C1C).withValues(alpha: 0.12),
                    backgroundImage: () {
                      final resolved = MediaUrlUtils.resolve(
                        bloodBank.logoUrl ?? bloodBank.profilePicture,
                      );
                      return resolved.isNotEmpty
                          ? CachedNetworkImageProvider(resolved)
                          : null;
                    }(),
                    child: () {
                      final resolved = MediaUrlUtils.resolve(
                        bloodBank.logoUrl ?? bloodBank.profilePicture,
                      );
                      return resolved.isEmpty
                          ? const Icon(Icons.bloodtype_rounded,
                              color: Color(0xFFB71C1C), size: 28)
                          : null;
                    }(),
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

class _ModernCareCard extends StatelessWidget {
  const _ModernCareCard({
    required this.accentGradient,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.footer,
    this.imageUrl,
    this.onTap,
  });

  final List<Color> accentGradient;
  final String title;
  final String subtitle;
  final String? footer;
  final String? imageUrl;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: accentGradient),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
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
                                ),
                              ),
                            ],
                            if (footer != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                footer!,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: iconColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
