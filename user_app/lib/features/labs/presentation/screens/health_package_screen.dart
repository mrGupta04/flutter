import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/health_package.dart';
import '../widgets/health_package_card.dart';

/// Reusable horizontal or vertical list of health package cards.
class HealthPackageList extends StatelessWidget {
  const HealthPackageList({
    super.key,
    required this.packages,
    required this.onPackageTap,
    this.scrollDirection = Axis.horizontal,
    this.isLoading = false,
    this.height = 230,
    this.padding = EdgeInsets.zero,
    this.itemSpacing = 12,
  });

  final List<HealthPackage> packages;
  final ValueChanged<HealthPackage> onPackageTap;
  final Axis scrollDirection;
  final bool isLoading;
  final double height;
  final EdgeInsets padding;
  final double itemSpacing;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildSkeletonList();
    }

    if (packages.isEmpty) {
      return const SizedBox.shrink();
    }

    if (scrollDirection == Axis.horizontal) {
      return SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: padding,
          itemCount: packages.length,
          separatorBuilder: (context, index) => SizedBox(width: itemSpacing),
          itemBuilder: (context, index) {
            final package = packages[index];
            return HealthPackageCard(
              package: package,
              heroTag: 'health_package_${package.id}',
              onTap: () => onPackageTap(package),
            );
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 420 ? 2 : 1;
        if (crossAxisCount == 1) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: padding,
            itemCount: packages.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: itemSpacing),
            itemBuilder: (context, index) {
              final package = packages[index];
              return Center(
                child: HealthPackageCard(
                  package: package,
                  heroTag: 'health_package_${package.id}',
                  onTap: () => onPackageTap(package),
                ),
              );
            },
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: itemSpacing,
            crossAxisSpacing: itemSpacing,
            childAspectRatio: HealthTestCardTheme.cardWidth /
                HealthTestCardTheme.cardHeight,
          ),
          itemCount: packages.length,
          itemBuilder: (context, index) {
            final package = packages[index];
            return HealthPackageCard(
              package: package,
              heroTag: 'health_package_${package.id}',
              onTap: () => onPackageTap(package),
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonList() {
    if (scrollDirection == Axis.horizontal) {
      return SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: padding,
          itemCount: 4,
          separatorBuilder: (context, index) => SizedBox(width: itemSpacing),
          itemBuilder: (context, index) => const HealthPackageCardSkeleton(),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: 4,
      separatorBuilder: (context, index) => SizedBox(height: itemSpacing),
      itemBuilder: (context, index) => const Center(
        child: HealthPackageCardSkeleton(),
      ),
    );
  }
}

/// Full-screen browse view for health risk / package cards.
class HealthPackageScreen extends StatelessWidget {
  const HealthPackageScreen({
    super.key,
    required this.title,
    required this.packages,
    required this.onPackageTap,
    this.isLoading = false,
  });

  final String title;
  final List<HealthPackage> packages;
  final ValueChanged<HealthPackage> onPackageTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: List.generate(
                4,
                (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Center(child: HealthPackageCardSkeleton()),
                ),
              ),
            )
          : packages.isEmpty
              ? Center(
                  child: Text(
                    'No packages found',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    HealthPackageList(
                      packages: packages,
                      onPackageTap: onPackageTap,
                      scrollDirection: Axis.vertical,
                      padding: EdgeInsets.zero,
                      itemSpacing: 16,
                    ),
                  ],
                ),
    );
  }
}
