import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/patient_user_model.dart';
import '../../../../data/repositories/notifications_repository.dart';
import '../../../../data/repositories/patient_auth_repository.dart';
import '../notification_routes.dart';

final notificationsProvider =
    FutureProvider<({List<AppNotification> notifications, int unreadCount})>(
  (ref) => NotificationsRepository().list(),
);

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key, this.iconColor});

  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider).maybeWhen(
          data: (data) => data.unreadCount,
          orElse: () => 0,
        );
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => context.push(AppConstants.routeNotifications),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(Icons.notifications_outlined, color: iconColor),
      ),
    );
  }
}

const _categories = [
  ('all', 'All'),
  ('booking', 'Booking'),
  ('payment', 'Payment'),
  ('provider', 'Provider'),
  ('emergency', 'Emergency'),
  ('system', 'System'),
];

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _category = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Notification settings',
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.tune_rounded),
          ),
          TextButton(
            onPressed: () async {
              try {
                await NotificationsRepository().markAllRead();
                ref.invalidate(notificationsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not update notifications.')),
                  );
                }
              }
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final item in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(item.$2),
                      selected: _category == item.$1,
                      onSelected: (_) => setState(() => _category = item.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Something went wrong.',
                        style: AppTextStyles.titleSmall
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(notificationsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (data) {
                final list = _category == 'all'
                    ? data.notifications
                    : data.notifications
                        .where((n) => n.category == _category)
                        .toList();
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No notifications yet',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                final stamp = DateFormat('d MMM, h:mm a');
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final n = list[index];
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
                          _iconFor(n.category, n.type),
                          color: n.category == 'emergency'
                              ? AppColors.error
                              : AppColors.primary,
                        ),
                        title: Text(
                          n.title,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight:
                                n.isUnread ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          [
                            n.body,
                            if (n.createdAt != null) stamp.format(n.createdAt!.toLocal()),
                          ].join('\n'),
                        ),
                        isThreeLine: n.createdAt != null,
                        onTap: () async {
                          if (n.isUnread) {
                            try {
                              await NotificationsRepository().markRead(n.id);
                              ref.invalidate(notificationsProvider);
                            } catch (_) {}
                          }
                          if (context.mounted) {
                            openPatientNotificationModel(GoRouter.of(context), n);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    try {
      final repo = PatientAuthRepository();
      final settings = await repo.fetchNotificationSettings();
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => _NotificationSettingsSheet(
          initial: settings,
          repository: repo,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load notification settings.')),
        );
      }
    }
  }

  IconData _iconFor(String category, String type) {
    switch (category) {
      case 'emergency':
        return Icons.emergency_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'provider':
        return Icons.chat_bubble_outline;
      case 'booking':
        return Icons.event_available_outlined;
      default:
        switch (type) {
          case 'prescription_ready':
          case 'nursing_report_ready':
            return Icons.description_outlined;
          default:
            return Icons.notifications_outlined;
        }
    }
  }
}

class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet({
    required this.initial,
    required this.repository,
  });

  final NotificationSettingsModel initial;
  final PatientAuthRepository repository;

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<_NotificationSettingsSheet> {
  late NotificationSettingsModel _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Notification settings')),
          SwitchListTile(
            title: const Text('Bookings'),
            value: _settings.booking,
            onChanged: (v) =>
                setState(() => _settings = _settings.copyWith(booking: v)),
          ),
          SwitchListTile(
            title: const Text('Payments'),
            value: _settings.payment,
            onChanged: (v) =>
                setState(() => _settings = _settings.copyWith(payment: v)),
          ),
          SwitchListTile(
            title: const Text('Provider messages'),
            value: _settings.provider,
            onChanged: (v) =>
                setState(() => _settings = _settings.copyWith(provider: v)),
          ),
          const SwitchListTile(
            title: Text('Emergency'),
            subtitle: Text('Always on for ambulance and emergency blood'),
            value: true,
            onChanged: null,
          ),
          SwitchListTile(
            title: const Text('System'),
            value: _settings.system,
            onChanged: (v) =>
                setState(() => _settings = _settings.copyWith(system: v)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () async {
                await widget.repository.updateNotificationSettings(_settings);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
