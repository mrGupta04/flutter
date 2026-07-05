import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class HeroWallpaperCarousel extends StatefulWidget {
  const HeroWallpaperCarousel({super.key});

  @override
  State<HeroWallpaperCarousel> createState() => _HeroWallpaperCarouselState();
}

class _HeroWallpaperCarouselState extends State<HeroWallpaperCarousel> {
  static const _slides = [
    _HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1666214280391-8ff5bd3c0bf0?w=1400&h=700&fit=crop',
      title: 'Book trusted doctors instantly',
      subtitle: 'Online, home visit, or clinic consultations',
    ),
    _HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1584432810601-6c7f27d2362b?w=1400&h=700&fit=crop',
      title: 'Care at your convenience',
      subtitle: 'Choose your slot and get care on your schedule',
    ),
    _HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=1400&h=700&fit=crop',
      title: 'Verified providers, better outcomes',
      subtitle: 'Explore specialists by role, city, and service type',
    ),
    _HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1579154204601-01588f351e67?w=1400&h=700&fit=crop',
      title: 'Multi-specialty healthcare network',
      subtitle: 'Discover providers across top departments',
    ),
    _HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=1400&h=700&fit=crop',
      title: 'Quick response and easy booking',
      subtitle: 'Get faster confirmations for your care needs',
    ),
  ];

  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final currentPage = _controller.page?.round() ?? _index;
      final next = currentPage >= _slides.length - 1 ? 0 : currentPage + 1;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 8.6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (_, i) {
                final slide = _slides[i];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: slide.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.primaryLight,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.primary,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.68),
                            Colors.black.withValues(alpha: 0.20),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          Text(
                            slide.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            slide.subtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _index == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _index == i
                          ? AppColors.white
                          : AppColors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSlide {
  const _HeroSlide({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });

  final String imageUrl;
  final String title;
  final String subtitle;
}
