import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/services/dio_service.dart';

class _ProviderNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime? createdAt;
  final DateTime? readAt;
  final Map<String, dynamic> data;

  const _ProviderNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.createdAt,
    this.readAt,
    this.data = const {},
  });

  bool get isUnread => readAt == null;

  factory _ProviderNotification.fromJson(Map<String, dynamic> json) {
    return _ProviderNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
    );
  }
}

class ProviderNotificationsScreen extends ConsumerStatefulWidget {
  const ProviderNotificationsScreen({super.key, required this.role});

  final String role; // doctor | nurse

  @override
  ConsumerState<ProviderNotificationsScreen> createState() =>
      _ProviderNotificationsScreenState();
}

class _ProviderNotificationsScreenState
    extends ConsumerState<ProviderNotificationsScreen> {
  final _dio = DioService();
  List<_ProviderNotification> _items = [];
  int _unread = 0;
  bool _loading = true;
  String? _error;

  String get _listEndpoint => widget.role == 'nurse'
      ? AppConstants.endpointNurseNotifications
      : AppConstants.endpointDoctorNotifications;

  String get _readAllEndpoint => widget.role == 'nurse'
      ? AppConstants.endpointNurseNotificationsReadAll
      : AppConstants.endpointDoctorNotificationsReadAll;

  String _readEndpoint(String id) => widget.role == 'nurse'
      ? AppConstants.endpointNurseNotificationRead(id)
      : AppConstants.endpointDoctorNotificationRead(id);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dio.get(_listEndpoint);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final list = (data['notifications'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => _ProviderNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      setState(() {
        _items = list;
        _unread = (data['unreadCount'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data is Map
            ? ((e.response!.data as Map)['error'] ?? e.message).toString()
            : e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _dio.post(_readAllEndpoint, data: <String, dynamic>{});
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _markRead(_ProviderNotification n) async {
    if (!n.isUnread) return;
    try {
      await _dio.post(_readEndpoint(n.id), data: <String, dynamic>{});
      await _load();
    } catch (_) {}
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'home_visit_request':
        return Icons.home_outlined;
      case 'booking_cancelled':
        return Icons.cancel_outlined;
      case 'chat_message':
        return Icons.chat_bubble_outline;
      case 'visit_reminder':
        return Icons.alarm;
      case 'booking_rescheduled':
        return Icons.event_repeat;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_unread > 0 ? 'Notifications ($_unread)' : 'Notifications'),
        actions: [
          TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Text(
                                'No notifications yet',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final n = _items[index];
                            return Material(
                              color: n.isUnread
                                  ? AppColors.primary.withValues(alpha: 0.06)
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppColors.divider),
                                ),
                                leading: Icon(_iconFor(n.type), color: AppColors.primary),
                                title: Text(
                                  n.title,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: n.isUnread
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(n.body),
                                onTap: () => _markRead(n),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
