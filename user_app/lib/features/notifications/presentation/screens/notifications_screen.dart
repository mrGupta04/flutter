import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/repositories/notifications_repository.dart';

final notificationsProvider =
    FutureProvider.autoDispose<({List<AppNotification> notifications, int unreadCount})>(
  (ref) => NotificationsRepository().list(),
);

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _openNotification(BuildContext context, AppNotification n) {
    final bookingId = n.data['bookingId']?.toString() ?? '';
    switch (n.type) {
      case 'chat_message':
        if (bookingId.isEmpty) return;
        context.push(
          '${AppConstants.routeBookingChat}?bookingId=$bookingId&title=${Uri.encodeComponent('Chat')}',
        );
        return;
      case 'payment_due':
      case 'booking_approved':
      case 'home_visit_request':
      case 'en_route':
      case 'visit_reminder':
        context.push(AppConstants.routeUserDashboard);
        return;
      case 'prescription_ready':
      case 'visit_note_ready':
        if (bookingId.isNotEmpty) {
          context.push(
            '${AppConstants.routeBookingTimeline}?bookingId=$bookingId',
          );
        } else {
          context.push(AppConstants.routeUserDashboard);
        }
        return;
      default:
        if (bookingId.isNotEmpty) {
          context.push(AppConstants.routeUserDashboard);
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await NotificationsRepository().markAllRead();
                ref.invalidate(notificationsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              }
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          if (data.notifications.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final n = data.notifications[index];
              return Material(
                color: n.isUnread
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.divider),
                  ),
                  leading: Icon(
                    _iconFor(n.type),
                    color: AppColors.primary,
                  ),
                  title: Text(
                    n.title,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight:
                          n.isUnread ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(n.body),
                  onTap: () async {
                    if (n.isUnread) {
                      try {
                        await NotificationsRepository().markRead(n.id);
                        ref.invalidate(notificationsProvider);
                      } catch (_) {}
                    }
                    if (context.mounted) _openNotification(context, n);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'home_visit_request':
        return Icons.home_outlined;
      case 'booking_approved':
        return Icons.check_circle_outline;
      case 'booking_rejected':
      case 'booking_cancelled':
        return Icons.cancel_outlined;
      case 'payment_due':
        return Icons.payment_outlined;
      case 'visit_reminder':
        return Icons.alarm;
      case 'en_route':
        return Icons.directions_walk;
      case 'prescription_ready':
      case 'visit_note_ready':
        return Icons.description_outlined;
      case 'chat_message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_outlined;
    }
  }
}
