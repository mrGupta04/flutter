import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_shell.dart';

/// Animated step progress for multi-step registration.
class StepProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final List<String> stepLabels;

  const StepProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final step = index + 1;
              final isCompleted = step < currentStep;
              final isCurrent = step == currentStep;
              final isActive = isCompleted || isCurrent;

              return Expanded(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isActive
                            ? const LinearGradient(
                                colors: AppColors.gradientPrimary,
                              )
                            : null,
                        color: isActive ? null : AppColors.grey200,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check_rounded,
                                color: AppColors.white, size: 18)
                            : Text(
                                '$step',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: isCurrent
                                      ? AppColors.white
                                      : AppColors.grey600,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    if (index < totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isCompleted
                                ? AppColors.primary
                                : AppColors.grey200,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            stepLabels[currentStep - 1],
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
          ),
          Text(
            'Step $currentStep of $totalSteps',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class VerificationTimeline extends StatelessWidget {
  final List<TimelineItem> items;

  const VerificationTimeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final item = items[index];
          final isLast = index == items.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: item.isCompleted
                            ? const LinearGradient(
                                colors: AppColors.gradientSuccess,
                              )
                            : null,
                        color: item.isCompleted ? null : AppColors.grey100,
                        border: Border.all(
                          color: item.isCompleted
                              ? Colors.transparent
                              : AppColors.grey300,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.isCompleted
                            ? AppColors.white
                            : AppColors.grey500,
                        size: 22,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          color: item.isCompleted
                              ? AppColors.secondary
                              : AppColors.grey200,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: AppTextStyles.titleSmall),
                        if (item.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (item.date != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: AppDecorations.borderRadiusSm,
                            ),
                            child: Text(
                              item.date!,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TimelineItem {
  final String title;
  final String? subtitle;
  final String? date;
  final IconData icon;
  final bool isCompleted;

  TimelineItem({
    required this.title,
    this.subtitle,
    this.date,
    required this.icon,
    required this.isCompleted,
  });
}

class VerificationBadge extends StatelessWidget {
  final String status;
  final Color backgroundColor;
  final Color textColor;
  final bool solid;

  const VerificationBadge({
    super.key,
    required this.status,
    required this.backgroundColor,
    required this.textColor,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: solid ? backgroundColor : null,
        gradient: solid
            ? null
            : LinearGradient(
                colors: [
                  backgroundColor.withValues(alpha: 0.2),
                  backgroundColor.withValues(alpha: 0.08),
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: solid
              ? backgroundColor.withValues(alpha: 0.18)
              : backgroundColor.withValues(alpha: 0.5),
        ),
        boxShadow: solid
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            status,
            style: AppTextStyles.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final String name;
  final String specialization;
  final String imageUrl;
  final String? verificationStatus;
  final VoidCallback? onTap;

  const ProfileCard({
    super.key,
    required this.name,
    required this.specialization,
    required this.imageUrl,
    this.verificationStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: AppColors.gradientPrimary),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(imageUrl),
            ),
          ),
          const SizedBox(height: 14),
          Text(name, style: AppTextStyles.titleLarge),
          const SizedBox(height: 4),
          Text(
            specialization,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (verificationStatus != null) ...[
            const SizedBox(height: 12),
            VerificationBadge(
              status: verificationStatus!,
              backgroundColor: verificationStatus == 'Verified'
                  ? AppColors.success
                  : verificationStatus == 'Rejected'
                      ? AppColors.error
                      : AppColors.warning,
              textColor: verificationStatus == 'Verified'
                  ? AppColors.success
                  : verificationStatus == 'Rejected'
                      ? AppColors.error
                      : AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class DocumentUploadCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isUploading;

  const DocumentUploadCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: isUploading ? null : onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecorations.iconTile(AppColors.primary),
            child: Icon(icon, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTextStyles.titleSmall, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (isUploading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(minHeight: 4),
          ],
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.backgroundColor = AppColors.primaryLight,
    this.iconColor = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: AppDecorations.iconTile(iconColor),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: iconColor.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}
