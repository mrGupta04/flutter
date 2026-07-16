import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/consultation_type.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/blinking_online_badge.dart';
import '../../../../shared/widgets/doctor_consultation_booking_section.dart';
import '../../../../shared/widgets/doctor_feedback_carousel.dart';
import '../../../../shared/widgets/doctor_hospital_map_card.dart';
import '../../../../shared/widgets/favorite_toggle_button.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/provider_profile_widgets.dart';
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
            FavoriteToggleButton(
              providerType: 'doctor',
              providerId: doctor.id ?? doctorId,
            ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProviderProfileHero(
            name: _displayName,
            subtitle: doctor.specializations?.isNotEmpty == true
                ? doctor.specializations!.join(', ')
                : null,
            imageUrl: hasImage ? imageUrl : null,
            avatarBorder: doctor.isLiveNow
                ? BlinkingLiveAvatarBorder(
                    padding: 4,
                    borderWidth: 3,
                    borderRadius: ProviderProfileHero.avatarCornerRadius + 4,
                    child: ProviderProfilePhoto(
                      imageUrl: hasImage ? imageUrl : null,
                      placeholderIcon: Icons.medical_services_rounded,
                      accentColor: AppColors.primary,
                      size: 96,
                      borderWidth: 0,
                    ),
                  )
                : null,
            avatarOverlay: doctor.isLiveNow
                ? const Positioned(
                    right: 4,
                    bottom: 4,
                    child: BlinkingOnlineAvatarBadge(),
                  )
                : null,
            badges: [
              if (doctor.isLiveNow) const BlinkingOnlineBadge(),
              if (doctor.hasRating)
                DoctorOverallRatingChip(
                  rating: doctor.averageRating!,
                  count: doctor.ratingCount,
                ),
              VerificationBadge(
                status: isVerified ? 'Verified doctor' : 'Admin verified listing',
                backgroundColor: AppColors.white,
                textColor: isVerified ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          if (doctor.clinicName != null &&
              doctor.clinicName!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                doctor.clinicName!.trim(),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
          ProviderInfoCard(
                  children: [
                    if (doctor.qualification != null &&
                        doctor.qualification!.trim().isNotEmpty)
                      ProviderInfoRow(
                        icon: Icons.school_outlined,
                        label: 'Qualification',
                        value: doctor.qualification!.trim(),
                      ),
                    if (doctor.yearsOfExperience != null)
                      ProviderInfoRow(
                        icon: Icons.work_history_outlined,
                        label: 'Experience',
                        value: '${doctor.yearsOfExperience} years',
                      ),
                    if (doctor.languagesSpoken?.isNotEmpty == true)
                      ProviderInfoRow(
                        icon: Icons.translate_rounded,
                        label: 'Languages',
                        value: doctor.languagesSpoken!.join(', '),
                      ),
                    if (doctor.bio != null && doctor.bio!.trim().isNotEmpty)
                      ProviderInfoRow(
                        icon: Icons.info_outline_rounded,
                        label: 'About',
                        value: doctor.bio!.trim(),
                      ),
                  ],
          ),
          if (_locationLine.isNotEmpty) ...[
            const SizedBox(height: 16),
            const MarketplaceSectionTitle(title: 'Clinic location'),
            ProviderInfoCard(
              children: [
                ProviderInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: _locationLine,
                ),
              ],
            ),
            const SizedBox(height: 12),
            DoctorHospitalMapCard(doctor: doctor),
          ],
          if (hospitalPhotos.isNotEmpty) ...[
            const SizedBox(height: 16),
            const MarketplaceSectionTitle(title: 'Hospital photos'),
            _HospitalPhotoGallery(photoUrls: hospitalPhotos),
          ],
          if (doctor.availableConsultationTypes.isNotEmpty)
            DoctorConsultationBookingSection(
              doctor: doctor,
              onBook: (type) => _openConsultationBooking(context, doctor, type),
            )
          else ...[
            const SizedBox(height: 20),
            Text(
              'No bookable consultation options for this doctor.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

void _openConsultationBooking(
  BuildContext context,
  DoctorModel doctor,
  ConsultationType type,
) {
  switch (type) {
    case ConsultationType.onlineConsult:
      openOnlineConsultBooking(context, doctor);
    case ConsultationType.visitSite:
      openHospitalVisitBooking(context, doctor);
    case ConsultationType.bookHome:
      openHomeVisitBooking(context, doctor);
  }
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
