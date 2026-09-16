import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/service_faqs.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/app_bar_title.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/consultation_type.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/blinking_online_badge.dart';
import '../../../../shared/widgets/doctor_consultation_booking_section.dart';
import '../../../../shared/widgets/doctor_feedback_carousel.dart';
import '../../../../shared/widgets/favorite_toggle_button.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/provider_profile_widgets.dart';
import '../../../../shared/widgets/service_faq_section.dart';
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
        appBar: _doctorProfileAppBar(context: context),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: _doctorProfileAppBar(context: context),
        body: AppErrorWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(doctorForBookingProvider(doctorId)),
        ),
      ),
      data: (doctor) {
        final canBook = doctor.availableConsultationTypes.isNotEmpty;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _doctorProfileAppBar(
            context: context,
            actions: [
              FavoriteToggleButton(
                providerType: 'doctor',
                providerId: doctor.id ?? doctorId,
              ),
              IconButton(
                tooltip: 'Share profile',
                icon: const Icon(Icons.share_outlined, size: 20),
                onPressed: () => _shareDoctorProfile(context, doctor),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: _DoctorProfileBody(doctor: doctor),
          bottomNavigationBar: canBook
              ? BottomCtaBar(
                  child: FilledButton(
                    onPressed: () => _onBookAppointment(context, doctor),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Book Appointment'),
                  ),
                )
              : null,
        );
      },
    );
  }
}

PreferredSizeWidget _doctorProfileAppBar({
  required BuildContext context,
  List<Widget>? actions,
}) {
  return AppBar(
    toolbarHeight: 52,
    centerTitle: false,
    titleSpacing: 4,
    leadingWidth: 48,
    leading: IconButton(
      tooltip: 'Back',
      onPressed: () {
        if (context.canPop()) context.pop();
      },
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
    ),
    title: const AppBarTitle('Doctor profile'),
    actions: actions,
  );
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
    if (doctor.state != null && doctor.state!.trim().isNotEmpty)
      doctor.state!.trim(),
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
  final name = doctor.fullName.trim();
  if (name.isEmpty) return 'Doctor';
  return name;
}

String _specialtyLine(DoctorModel doctor) {
  final specs = (doctor.specializations ?? [])
      .map((spec) => spec.trim())
      .where((spec) => spec.isNotEmpty)
      .toList(growable: false);
  if (specs.isEmpty) return '';
  return specs.join(' • ');
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

  bool get _hasClinicDetails =>
      _locationLine.isNotEmpty ||
      (doctor.clinicName != null && doctor.clinicName!.trim().isNotEmpty);

  String get _aboutText {
    final bio = doctor.bio?.trim() ?? '';
    return bio;
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
    final canBook = doctor.availableConsultationTypes.isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, canBook ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DoctorHeaderCard(
            name: _displayName,
            specialtyLine: _specialtyLine(doctor),
            imageUrl: hasImage ? imageUrl : null,
            isVerified: isVerified,
            isLiveNow: doctor.isLiveNow,
            rating: doctor.hasRating ? doctor.averageRating : null,
            ratingCount: doctor.ratingCount,
          ),
          if (feedbackAsync != null) ...[
            const SizedBox(height: 16),
            feedbackAsync.when(
              loading: () => const SizedBox(
                height: 148,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const SizedBox.shrink(),
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
          const MarketplaceSectionTitle(
            title: 'Professional details',
            padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
          ),
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
              if (_aboutText.isNotEmpty)
                ProviderInfoRow(
                  icon: Icons.info_outline_rounded,
                  label: 'About',
                  value: _aboutText,
                )
              else
                const _AboutPlaceholderRow(),
            ],
          ),
          if (_hasClinicDetails) ...[
            const SizedBox(height: 20),
            const MarketplaceSectionTitle(
              title: 'Clinic location',
              padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
            ),
            _ClinicLocationCard(
              clinicName: doctor.clinicName?.trim() ?? '',
              address: _locationLine,
            ),
          ],
          if (hospitalPhotos.isNotEmpty) ...[
            const SizedBox(height: 20),
            const MarketplaceSectionTitle(
              title: 'Hospital photos',
              padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
            ),
            _HospitalPhotoGallery(photoUrls: hospitalPhotos),
          ],
          if (canBook)
            DoctorConsultationBookingSection(
              doctor: doctor,
              titlePadding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
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
          const ServiceFaqSection(
            title: "General FAQs for Doctor Consultations",
            items: ServiceFaqs.doctor,
            padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
          ),
        ],
      ),
    );
  }
}

class _DoctorHeaderCard extends StatelessWidget {
  const _DoctorHeaderCard({
    required this.name,
    required this.specialtyLine,
    required this.imageUrl,
    required this.isVerified,
    required this.isLiveNow,
    this.rating,
    this.ratingCount,
  });

  final String name;
  final String specialtyLine;
  final String? imageUrl;
  final bool isVerified;
  final bool isLiveNow;
  final double? rating;
  final int? ratingCount;

  @override
  Widget build(BuildContext context) {
    final photo = _DoctorAvatar(
      name: name,
      imageUrl: imageUrl,
      isLiveNow: isLiveNow,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F8EF), AppColors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppDecorations.softShadow(opacity: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              photo,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.25,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (specialtyLine.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        specialtyLine,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _VerifiedDoctorChip(isVerified: isVerified),
                        if (rating != null)
                          DoctorOverallRatingChip(
                            rating: rating!,
                            count: ratingCount,
                            compact: true,
                          ),
                        if (isLiveNow) const BlinkingOnlineBadge(compact: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({
    required this.name,
    required this.imageUrl,
    required this.isLiveNow,
  });

  final String name;
  final String? imageUrl;
  final bool isLiveNow;

  static const double _size = 88;

  void _openPhoto(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) return;
    showFullScreenNetworkImage(context, imageUrl: url, title: name);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final photo = Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasImage ? () => _openPhoto(context) : null,
        child: SizedBox(
          width: _size,
          height: _size,
          child: hasImage
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  placeholder: (_, _) => const ColoredBox(
                    color: AppColors.primaryLight,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, _, _) => const ColoredBox(
                    color: AppColors.primaryLight,
                    child: Icon(
                      Icons.medical_services_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                )
              : const ColoredBox(
                  color: AppColors.primaryLight,
                  child: Icon(
                    Icons.medical_services_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
        ),
      ),
    );

    final framed = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: photo,
    );

    if (!isLiveNow) return framed;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        BlinkingLiveAvatarBorder(
          padding: 3,
          borderWidth: 2,
          borderRadius: 20,
          child: framed,
        ),
        const Positioned(
          right: 0,
          bottom: 0,
          child: BlinkingOnlineAvatarBadge(),
        ),
      ],
    );
  }
}

class _VerifiedDoctorChip extends StatelessWidget {
  const _VerifiedDoctorChip({required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? AppColors.primaryDark : AppColors.warning;
    final label = isVerified ? 'Verified doctor' : 'Admin verified listing';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified ? AppColors.primaryLight : AppColors.offerLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutPlaceholderRow extends StatelessWidget {
  const _AboutPlaceholderRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'No bio added yet.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClinicLocationCard extends StatelessWidget {
  const _ClinicLocationCard({
    required this.clinicName,
    required this.address,
  });

  final String clinicName;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppDecorations.softShadow(opacity: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (clinicName.isNotEmpty)
            ProviderInfoRow(
              icon: Icons.local_hospital_outlined,
              label: 'Clinic',
              value: clinicName,
            ),
          if (clinicName.isNotEmpty && address.isNotEmpty)
            Divider(
              height: 24,
              thickness: 1,
              color: AppColors.divider.withValues(alpha: 0.7),
            ),
          if (address.isNotEmpty)
            ProviderInfoRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: address,
            ),
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

Future<void> _onBookAppointment(
  BuildContext context,
  DoctorModel doctor,
) async {
  final types = doctor.availableConsultationTypes;
  if (types.isEmpty) return;
  if (types.length == 1) {
    _openConsultationBooking(context, doctor, types.first);
    return;
  }

  final selected = await showModalBottomSheet<ConsultationType>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Book Appointment',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a consultation type',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (final type in types) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconForConsultationType(type),
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    type.label,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: Text(
                    _feeLabelFor(doctor, type),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => Navigator.pop(sheetContext, type),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  if (selected != null && context.mounted) {
    _openConsultationBooking(context, doctor, selected);
  }
}

IconData _iconForConsultationType(ConsultationType type) {
  switch (type) {
    case ConsultationType.onlineConsult:
      return Icons.videocam_rounded;
    case ConsultationType.visitSite:
      return Icons.local_hospital_rounded;
    case ConsultationType.bookHome:
      return Icons.home_rounded;
  }
}

String _feeLabelFor(DoctorModel doctor, ConsultationType type) {
  final fee = doctor.effectiveFeeForConsultationType(type);
  if (fee == null || fee <= 0) return 'On request';
  return FormattingUtils.formatConsultationFee(fee);
}

class _HospitalPhotoViewerPage extends StatelessWidget {
  const _HospitalPhotoViewerPage({
    required this.imageUrl,
    required this.title,
  });

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        title: Text(title),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return InteractiveViewer(
            constrained: false,
            minScale: 1,
            maxScale: 5,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: constraints.maxWidth,
                fit: BoxFit.fitWidth,
                placeholder: (_, _) => SizedBox(
                  height: constraints.maxHeight,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.white),
                  ),
                ),
                errorWidget: (_, _, _) => SizedBox(
                  height: constraints.maxHeight,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HospitalPhotoGallery extends StatefulWidget {
  const _HospitalPhotoGallery({required this.photoUrls});

  final List<String> photoUrls;

  @override
  State<_HospitalPhotoGallery> createState() => _HospitalPhotoGalleryState();
}

class _HospitalPhotoGalleryState extends State<_HospitalPhotoGallery> {
  int _page = 0;

  void _openPhoto(BuildContext context, String url, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _HospitalPhotoViewerPage(
          imageUrl: url,
          title: 'Hospital photo ${index + 1}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photoUrls;
    if (photos.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 196,
          child: PageView.builder(
            itemCount: photos.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final url = photos[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
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
                          placeholder: (_, _) => Container(
                            color: AppColors.grey100,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: AppColors.grey100,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Photo ${index + 1} of ${photos.length}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < photos.length; i++)
                Container(
                  width: i == _page ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.primary : AppColors.grey300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ],
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
