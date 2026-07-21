import 'package:flutter/material.dart';

enum HealthServiceCardType { asset, compact }

class HealthServiceItem {
  const HealthServiceItem({
    required this.title,
    required this.image,
    required this.icon,
    required this.color,
    required this.onTap,
    this.type = HealthServiceCardType.compact,
    this.assetAspectRatio,
  });

  final String title;
  final String image;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final HealthServiceCardType type;
  final double? assetAspectRatio;
}

/// Two-column service grid for the home dashboard.
class HealthServiceGrid extends StatelessWidget {
  const HealthServiceGrid({
    super.key,
    required this.items,
    this.title = 'What are you looking for?',
    this.cardsPerRow = 2,
  });

  final List<HealthServiceItem> items;
  final String title;
  final int cardsPerRow;

  @override
  Widget build(BuildContext context) {
    final perRow = cardsPerRow < 1 ? 1 : cardsPerRow;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          for (var row = 0; row < items.length; row += perRow) ...[
            if (row > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var col = 0; col < perRow; col++) ...[
                  if (col > 0) const SizedBox(width: 12),
                  Expanded(
                    child: row + col < items.length
                        ? _buildCard(items[row + col])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(HealthServiceItem item) {
    if (item.type == HealthServiceCardType.asset) {
      return HealthServiceAssetCard(
        image: item.image,
        aspectRatio: item.assetAspectRatio ?? 1,
        semanticLabel: item.title.replaceAll('\n', ' '),
        onTap: item.onTap,
      );
    }

    return HealthServiceCard(
      title: item.title,
      image: item.image,
      icon: item.icon,
      color: item.color,
      onTap: item.onTap,
    );
  }
}

/// Pre-designed inner card image (doctor, lab, nurse, scans).
class HealthServiceAssetCard extends StatelessWidget {
  const HealthServiceAssetCard({
    super.key,
    required this.image,
    required this.onTap,
    this.aspectRatio = 1,
    this.semanticLabel,
  });

  final String image;
  final VoidCallback onTap;
  final double aspectRatio;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Image.asset(
              image,
              fit: BoxFit.cover,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact service card for ambulance, blood bank, etc.
class HealthServiceCard extends StatelessWidget {
  const HealthServiceCard({
    super.key,
    required this.title,
    required this.image,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String image;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 168,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 8,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Image.asset(
                  image,
                  width: 88,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: onTap,
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
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
