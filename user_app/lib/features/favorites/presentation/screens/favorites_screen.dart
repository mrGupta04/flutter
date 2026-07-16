import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../data/repositories/favorites_repository.dart';

final favoritesProvider =
    FutureProvider.autoDispose<List<FavoriteItem>>((ref) {
  return FavoritesRepository().list();
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No favorites yet.\nTap the heart on a doctor or nurse profile.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final photo = MediaUrlUtils.resolve(item.profilePicture);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isEmpty
                        ? Text(item.displayName.isNotEmpty
                            ? item.displayName[0]
                            : '?')
                        : null,
                  ),
                  title: Text(
                    item.displayName,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    [
                      item.providerType == 'nurse' ? 'Nurse' : 'Doctor',
                      if (item.specialization != null) item.specialization!,
                    ].join(' · '),
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      if (item.providerType == 'nurse') {
                        context.push(
                          '${AppConstants.routeNurseProfile}?id=${item.providerId}',
                        );
                      } else {
                        context.push(
                          '${AppConstants.routeDoctorProfile}?id=${item.providerId}',
                        );
                      }
                    },
                    child: const Text('Book again'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
