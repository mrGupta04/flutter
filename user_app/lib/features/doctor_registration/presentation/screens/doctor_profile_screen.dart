import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/consultation_type.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/blinking_online_badge.dart';
import '../../../../shared/widgets/doctor_consultation_fees_banner.dart';
import '../../../../shared/widgets/doctor_feedback_carousel.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../provider/doctor_feedback_provider.dart';
import '../../../online_consult/online_consult_navigation.dart';
import '../../../online_consult/provider/online_consult_provider.dart';

class DoctorProfileScreen extends ConsumerWidget {
  const DoctorProfileScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDoctor = ref.watch(doctorForBookingProvider(doctorId));

    return asyncDoctor.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Doctor profile')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Doctor profile')),
        body: AppErrorWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(doctorForBookingProvider(doctorId)),
        ),
      ),
      data: (doctor) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Doctor profile'),
          actions: [
            IconButton(
              tooltip: 'Share profile',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareDoctorProfile(context, doctor),
            ),
          ],
        ),
        body: _DoctorProfileBody(doctor: doctor),
      ),
    );
  }
}

Future<void> _shareDoctorProfile(BuildContext context, DoctorModel doctor) async {
  final name = _doctorDisplayName(doctor);
  final lines = <String>[
    'Check out $name on 1mg Care',
    if (doctor.specializations?.isNotEmpty == true)
      'Specialization: ${doctor.specializations!.join(', ')}',
    if (doctor.clinicName != null && doctor.clinicName!.trim().isNotEmpty)
      'Clinic: ${doctor.clinicName!.trim()}',
  ];

  final locationParts = [
    if (doctor.address != null && doctor.address!.trim().isNotEmpty)
      doctor.address!.trim(),
    if (doctor.city != null && doctor.city!.trim().isNotEmpty) doctor.city!.trim(),
    if (doctor.state != null && doctor.state!.trim().isNotEmpty) doctor.state!.trim(),
    if (doctor.pincode != null && doctor.pincode!.trim().isNotEmpty)
      doctor.pincode!.trim(),
  ];
  if (locationParts.isNotEmpty) {
    lines.add('Location: ${locationParts.join(', ')}');
  }

  final feeLines = <String>[
    if (doctor.offersOnlineConsult &&
        doctor.feeForConsultationType(ConsultationType.onlineConsult) != null)
      'Online consult: ₹${doctor.feeForConsultationType(ConsultationType.onlineConsult)}',
    if (doctor.offersVisitSite &&
        doctor.feeForConsultationType(ConsultationType.visitSite) != null)
      'Hospital visit: ₹${doctor.feeForConsultationType(ConsultationType.visitSite)}',
    if (doctor.offersBookHome &&
        doctor.feeForConsultationType(ConsultationType.bookHome) != null)
      'Home visit: ₹${doctor.feeForConsultationType(ConsultationType.bookHome)}',
  ];
  if (feeLines.isNotEmpty) {
    lines.add('Consultation fees: ${feeLines.join(', ')}');
  }

  final services = <String>[
    if (doctor.offersOnlineConsult) 'Online consult',
    if (doctor.offersVisitSite) 'Hospital visit',
    if (doctor.offersBookHome) 'Home visit',
  ];
  if (services.isNotEmpty) {
    lines.add('Available: ${services.join(', ')}');
  }

  if (doctor.id != null && doctor.id!.isNotEmpty) {
    lines.add('');
    lines.add(
      'View profile in app: ${AppConstants.routeDoctorProfile}?id=${Uri.encodeComponent(doctor.id!)}',
    );
  }

  final box = context.findRenderObject() as RenderBox?;
  final origin = box != null
      ? box.localToGlobal(Offset.zero) & box.size
      : null;

  await Share.share(
    lines.join('\n'),
    subject: '$name — 1mg Care',
    sharePositionOrigin: origin,
  );
}

String _doctorDisplayName(DoctorModel doctor) {
  final name = doctor.fullName;
  if (name.isEmpty) return 'Doctor';
  return name.startsWith('Dr.') ? name : 'Dr. $name';
}

class _DoctorProfileBody extends ConsumerWidget {
  const _DoctorProfileBody({required this.doctor});

  final DoctorModel doctor;

  String get _displayName => _doctorDisplayName(doctor);

  String get _locationLine {
    final parts = [
      if (doctor.address != null && doctor.address!.trim().isNotEmpty)
        doctor.address!.trim(),
      if (doctor.city != null && doctor.city!.trim().isNotEmpty)
        doctor.city!.trim(),
      if (doctor.state != null && doctor.state!.trim().isNotEmpty)
        doctor.state!.trim(),
      if (doctor.pincode != null && doctor.pincode!.trim().isNotEmpty)
        doctor.pincode!.trim(),
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = MediaUrlUtils.resolve(doctor.primaryPortraitUrl);
    final hasImage = imageUrl.isNotEmpty;
    final isVerified =
        doctor.verificationStatus == VerificationStatus.verified;
    final hospitalPhotos = doctor.hospitalPhotoUrls
        .map(MediaUrlUtils.resolve)
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    final feedbackAsync = doctor.id != null && doctor.id!.isNotEmpty
        ? ref.watch(doctorFeedbackProvider(doctor.id!))
        : null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.gradientHero),
                    borderRadius: AppDecorations.borderRadiusXl,
                  ),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (doctor.isLiveNow)
                            BlinkingLiveAvatarBorder(
                              padding: 4,
                              borderWidth: 3,
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: AppColors.white,
                                backgroundImage: hasImage
                                    ? CachedNetworkImageProvider(imageUrl)
                                    : null,
                                child: !hasImage
                                    ? const Icon(
                                        Icons.medical_services_rounded,
                                        size: 48,
                                        color: AppColors.primary,
                                      )
                                    : null,
                              ),
                            )
                          else
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: AppColors.white,
                              backgroundImage: hasImage
                                  ? CachedNetworkImageProvider(imageUrl)
                                  : null,
                              child: !hasImage
                                  ? const Icon(
                                      Icons.medical_services_rounded,
                                      size: 48,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                          if (doctor.isLiveNow)
                            const Positioned(
                              right: 4,
                              bottom: 4,
                              child: BlinkingOnlineAvatarBadge(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _displayName,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (doctor.isLiveNow) ...[
                        const SizedBox(height: 10),
                        const BlinkingOnlineBadge(),
                      ],
                      if (doctor.hasRating) ...[
                        const SizedBox(height: 10),
                        DoctorOverallRatingChip(
                          rating: doctor.averageRating!,
                          count: doctor.ratingCount,
                        ),
                      ],
                      if (doctor.specializations?.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(
                          doctor.specializations!.join(', '),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                      if (doctor.clinicName != null &&
                          doctor.clinicName!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          doctor.clinicName!.trim(),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      VerificationBadge(
                        status: isVerified ? 'Verified doctor' : 'Admin verified listing',
                        backgroundColor: AppColors.white,
                        textColor: isVerified ? AppColors.success : AppColors.warning,
                      ),
                    ],
                  ),
                ),
                if (feedbackAsync != null) ...[
                  const SizedBox(height: 20),
                  feedbackAsync.when(
                    loading: () => const SizedBox(
                      height: 148,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (feedback) {
                      if (!feedback.hasReviews) return const SizedBox.shrink();
                      return DoctorFeedbackCarousel(
                        reviews: feedback.reviews,
                        averageRating:
                            feedback.averageRating ?? doctor.averageRating,
                        ratingCount: feedback.ratingCount > 0
                            ? feedback.ratingCount
                            : (doctor.ratingCount ?? 0),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 20),
                const MarketplaceSectionTitle(title: 'Professional details'),
                _InfoCard(
                  children: [
                    if (doctor.qualification != null &&
                        doctor.qualification!.trim().isNotEmpty)
                      _InfoRow(
                        icon: Icons.school_outlined,
                        label: 'Qualification',
                        value: doctor.qualification!.trim(),
                      ),
                    if (doctor.yearsOfExperience != null)
                      _InfoRow(
                        icon: Icons.work_history_outlined,
                        label: 'Experience',
                        value: '${doctor.yearsOfExperience} years',
                      ),
                    if (doctor.languagesSpoken?.isNotEmpty == true)
                      _InfoRow(
                        label: 'Languages',
                        value: doctor.languagesSpoken!.join(', '),
                      ),
                    if (doctor.bio != null && doctor.bio!.trim().isNotEmpty)
                      _InfoRow(
                        icon: Icons.info_outline_rounded,
                        label: 'About',
                        value: doctor.bio!.trim(),
                      ),
                  ],
                ),
                if (doctor.availableConsultationTypes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const MarketplaceSectionTitle(title: 'Consultation charges'),
                  _InfoCard(
                    children: [
                      for (final type in doctor.availableConsultationTypes)
                        _InfoRow(
                          icon: _consultationTypeIcon(type),
                          label: _consultationTypeLabel(type),
                          value: _consultationFeeLabel(doctor, type),
                        ),
                    ],
                  ),
                ],
                if (_locationLine.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const MarketplaceSectionTitle(title: 'Clinic location'),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value: _locationLine,
                      ),
                    ],
                  ),
                ],
                if (hospitalPhotos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const MarketplaceSectionTitle(title: 'Hospital photos'),
                  _HospitalPhotoGallery(photoUrls: hospitalPhotos),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (doctor.availableConsultationTypes.isEmpty)
                  Text(
                    'No bookable consultation options for this doctor.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else ...[
                  DoctorConsultationFeesBanner(doctor: doctor),
                  const SizedBox(height: 12),
                  ..._bookingActions(context, doctor),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _bookingButtonLabel(String action, int? fee) {
  if (fee == null || fee <= 0) return action;
  return '$action · ₹$fee';
}

String _consultationTypeLabel(ConsultationType type) {
  switch (type) {
    case ConsultationType.onlineConsult:
      return 'Online consult';
    case ConsultationType.visitSite:
      return 'Hospital visit';
    case ConsultationType.bookHome:
      return 'Home visit';
  }
}

IconData _consultationTypeIcon(ConsultationType type) {
  switch (type) {
    case ConsultationType.onlineConsult:
      return Icons.videocam_outlined;
    case ConsultationType.visitSite:
      return Icons.local_hospital_outlined;
    case ConsultationType.bookHome:
      return Icons.home_outlined;
  }
}

String _consultationFeeLabel(DoctorModel doctor, ConsultationType type) {
  final fee = doctor.feeForConsultationType(type);
  if (fee == null || fee <= 0) return 'Fee on request';
  return FormattingUtils.formatConsultationFee(fee);
}

List<Widget> _bookingActions(BuildContext context, DoctorModel doctor) {
  final actions = <Widget>[];
  for (final type in doctor.availableConsultationTypes) {
    if (actions.isNotEmpty) {
      actions.add(const SizedBox(height: 10));
    }

    final label = _bookingButtonLabel(
      'Book ${_consultationTypeLabel(type).toLowerCase()}',
      doctor.feeForConsultationType(type),
    );
    final icon = switch (type) {
      ConsultationType.onlineConsult => Icons.videocam_rounded,
      ConsultationType.visitSite => Icons.local_hospital_rounded,
      ConsultationType.bookHome => Icons.home_rounded,
    };
    final onPressed = switch (type) {
      ConsultationType.onlineConsult =>
        () => openOnlineConsultBooking(context, doctor),
      ConsultationType.visitSite =>
        () => openHospitalVisitBooking(context, doctor),
      ConsultationType.bookHome => () => openHomeVisitBooking(context, doctor),
    };

    if (type == ConsultationType.visitSite) {
      actions.add(
        CustomOutlineButton(label: label, icon: icon, onPressed: onPressed),
      );
    } else {
      actions.add(
        CustomButton(label: label, icon: icon, onPressed: onPressed),
      );
    }
  }
  return actions;
}

class _HospitalPhotoGallery extends StatelessWidget {
  const _HospitalPhotoGallery({required this.photoUrls});

  final List<String> photoUrls;

  void _openPhoto(BuildContext context, String url, int index) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hospital photo ${index + 1}',
                      style: AppTextStyles.titleSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  placeholder: (_, __) => const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox(
                    height: 240,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: photoUrls.length,
      itemBuilder: (context, index) {
        final url = photoUrls[index];
        return Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openPhoto(context, url, index),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.grey100,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.grey100,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Photo ${index + 1}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          'No additional details provided.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 20),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    this.icon,
    required this.label,
    required this.value,
  });

  final IconData? icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// Navigate to doctor profile from listings.
void openDoctorProfile(BuildContext context, DoctorModel doctor) {
  final id = doctor.id;
  if (id == null || id.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This doctor profile is not available yet.')),
    );
    return;
  }
  context.push(
    '${AppConstants.routeDoctorProfile}?id=${Uri.encodeComponent(id)}',
  );
}
