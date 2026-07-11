import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'doctor_listing_card.dart';
import 'marketplace_provider_card_ui.dart';

/// How many provider cards are visible before the user scrolls for more.
const int kHomeProviderPreviewCount = 3;

/// Estimated card height for viewport sizing (home cards).
const double kHomeProviderCardHeight = kDoctorListingCardHeight;

/// Extra space below the third card so the next card peeks through.
const double kHomeProviderPeekExtent = 36;

/// Vertical list of providers on home: shows ~3 cards, scrolls for the rest.
class HomeProviderScrollList extends StatelessWidget {
  const HomeProviderScrollList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.previewCount = kHomeProviderPreviewCount,
    this.cardHeight = kHomeProviderCardHeight,
    this.spacing = kDoctorCardSpacing,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int previewCount;
  final double cardHeight;
  final double spacing;

  bool get _hasMore => itemCount > previewCount;

  double _viewportHeight() {
    if (itemCount <= previewCount) {
      if (itemCount == 0) return 0;
      return itemCount * cardHeight + (itemCount - 1) * spacing;
    }
    return previewCount * cardHeight +
        (previewCount - 1) * spacing +
        kHomeProviderPeekExtent;
  }

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    // ≤3 items: plain Column (ListView needs bounded height inside home scroll).
    if (!_hasMore) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            itemBuilder(context, i),
          ],
        ],
      );
    }

    final list = SizedBox(
      height: _viewportHeight(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: ListView.separated(
          primary: false,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: itemCount,
          separatorBuilder: (_, _) => SizedBox(height: spacing),
          itemBuilder: itemBuilder,
        ),
      ),
    );

    return HomeProviderPreviewStack(
      totalCount: itemCount,
      previewCount: previewCount,
      child: list,
    );
  }
}

/// Fade + bouncing arrow when more providers exist below the fold.
class HomeProviderPreviewStack extends StatelessWidget {
  const HomeProviderPreviewStack({
    super.key,
    required this.totalCount,
    required this.child,
    this.previewCount = kHomeProviderPreviewCount,
  });

  final int totalCount;
  final int previewCount;
  final Widget child;

  bool get _hasMore => totalCount > previewCount;

  @override
  Widget build(BuildContext context) {
    if (!_hasMore) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 80,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0),
                    AppColors.background.withValues(alpha: 0.88),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: _ScrollMoreHint(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScrollMoreHint extends StatefulWidget {
  const _ScrollMoreHint();

  @override
  State<_ScrollMoreHint> createState() => _ScrollMoreHintState();
}

class _ScrollMoreHintState extends State<_ScrollMoreHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounce.value),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Scroll for more',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
