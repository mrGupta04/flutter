import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/media_url_utils.dart';
import '../../data/models/ambulance_model.dart';
import '../../data/models/blood_bank_model.dart';
import '../../data/models/doctor_model.dart';
import '../../data/models/nurse_model.dart';

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
  });

  final NurseModel nurse;
  final bool showBottomDivider;
  final bool showActionButtons;
  final VoidCallback? onTap;
  final VoidCallback? onBookHomeVisit;
  final VoidCallback? onOpenMapTap;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    final qualification = nurse.qualification?.trim();
    final specialization = nurse.specialization?.trim() ?? 'General Nursing';
    final experience = nurse.yearsOfExperience;
    final city = nurse.city?.trim();
    final isVerified =
        nurse.verificationStatus == VerificationStatus.verified;
    final available = nurse.availableForHomeVisit != false;
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
                  : AppColors.secondary.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.08),
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
                          AppColors.secondary.withValues(alpha: 0.14),
                          AppColors.secondary.withValues(alpha: 0),
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
                        gradient: LinearGradient(colors: kNurseGradient),
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
                              _NurseAvatar(nurse: nurse),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nurse.displayName,
                                      style: AppTextStyles.titleSmall.copyWith(
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        if (isVerified) const _NurseVerifiedBadge(),
                                        _NurseSpecialtyChip(label: specialization),
                                        if (nurse.gender != null &&
                                            nurse.gender!.trim().isNotEmpty)
                                          _NurseTagChip(label: nurse.gender!.trim()),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (qualification != null && qualification.isNotEmpty)
                            _NurseMetaRow(
                              icon: Icons.school_outlined,
                              text: experience != null
                                  ? '$experience+ yrs · $qualification'
                                  : qualification,
                            ),
                          if (city != null && city.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _NurseMetaRow(
                              icon: Icons.location_on_outlined,
                              text: distanceLabel != null
                                  ? '$city · $distanceLabel'
                                  : city,
                            ),
                          ] else if (distanceLabel != null) ...[
                            const SizedBox(height: 6),
                            _NurseMetaRow(
                              icon: Icons.near_me_outlined,
                              text: distanceLabel!,
                            ),
                          ],
                          if (nurse.shiftAvailability != null &&
                              nurse.shiftAvailability!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _NurseMetaRow(
                              icon: Icons.schedule_rounded,
                              text: nurse.shiftAvailability!.trim(),
                            ),
                          ],
                          if (nurse.homeVisitFee != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.home_rounded,
                                    size: 14,
                                    color: AppColors.secondaryDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Home visit from ₹${nurse.homeVisitFee}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.secondaryDark,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (!showActionButtons) ...[
                            const SizedBox(height: 10),
                            _NurseAvailabilityPill(available: available),
                          ],
                          if (showActionButtons) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _NurseActionButton(
                                    icon: Icons.home_rounded,
                                    label: 'Book visit',
                                    subtitle: nurse.homeVisitFee != null
                                        ? '₹${nurse.homeVisitFee}'
                                        : null,
                                    filled: available,
                                    onPressed: available
                                        ? (onBookHomeVisit ?? onTap)
                                        : null,
                                  ),
                                ),
                                if (onOpenMapTap != null) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _NurseActionButton(
                                      icon: Icons.map_rounded,
                                      label: 'Map',
                                      filled: false,
                                      onPressed: onOpenMapTap,
                                    ),
                                  ),
                                ],
                              ],
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

class _NurseAvatar extends StatelessWidget {
  const _NurseAvatar({required this.nurse});

  final NurseModel nurse;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(nurse.profilePicture);
    final hasImage = imageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: kNurseGradient),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: SizedBox(
            width: 60,
            height: 60,
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
      ),
    );
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryLight,
            AppColors.secondary.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: const Icon(
        Icons.health_and_safety_rounded,
        size: 30,
        color: AppColors.secondary,
      ),
    );
  }
}

class _NurseVerifiedBadge extends StatelessWidget {
  const _NurseVerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: kNurseGradient),
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

class _NurseSpecialtyChip extends StatelessWidget {
  const _NurseSpecialtyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.secondaryDark,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _NurseTagChip extends StatelessWidget {
  const _NurseTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _NurseMetaRow extends StatelessWidget {
  const _NurseMetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
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

class _NurseAvailabilityPill extends StatelessWidget {
  const _NurseAvailabilityPill({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: available
            ? AppColors.secondaryLight
            : AppColors.grey50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: available
              ? AppColors.secondary.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Icons.check_circle_rounded : Icons.cancel_outlined,
            size: 14,
            color: available ? AppColors.secondary : AppColors.grey500,
          ),
          const SizedBox(width: 6),
          Text(
            available ? 'Available for home visit' : 'Not available',
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: available ? AppColors.secondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NurseActionButton extends StatelessWidget {
  const _NurseActionButton({
    required this.icon,
    required this.label,
    this.subtitle,
    this.filled = true,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            gradient: filled
                ? const LinearGradient(colors: kNurseGradient)
                : null,
            color: filled ? null : AppColors.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: filled
                  ? Colors.transparent
                  : AppColors.secondary.withValues(alpha: 0.35),
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
                    size: 16,
                    color: filled ? AppColors.white : AppColors.secondaryDark,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: filled ? AppColors.white : AppColors.secondaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: filled
                        ? AppColors.white.withValues(alpha: 0.9)
                        : AppColors.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
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
