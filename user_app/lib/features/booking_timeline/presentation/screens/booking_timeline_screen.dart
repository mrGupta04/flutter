import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/patient_booking_model.dart';
import '../../../../data/repositories/booking_lifecycle_repository.dart';
import '../../../../shared/widgets/app_widgets.dart';

class BookingTimelineScreen extends StatefulWidget {
  const BookingTimelineScreen({
    super.key,
    required this.bookingId,
    this.initialSteps = const [],
  });

  final String bookingId;
  final List<BookingTimelineStep> initialSteps;

  @override
  State<BookingTimelineScreen> createState() => _BookingTimelineScreenState();
}

class _BookingTimelineScreenState extends State<BookingTimelineScreen> {
  final _repo = BookingLifecycleRepository();
  List<BookingTimelineStep> _steps = [];
  CancellationPolicy? _policy;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _steps = widget.initialSteps;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.fetchTimeline(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _steps = result.timeline;
        _policy = result.policy;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'requested':
        return Icons.pending_actions_outlined;
      case 'approved':
        return Icons.thumb_up_alt_outlined;
      case 'rejected':
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'paid':
        return Icons.payments_outlined;
      case 'en_route':
        return Icons.directions_walk;
      case 'arrived':
        return Icons.home_outlined;
      case 'verified':
        return Icons.verified_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM, hh:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Visit tracking')),
      body: _loading && _steps.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _steps.isEmpty
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_policy != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cancellation policy',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _policy!.message,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      VerificationTimeline(
                        items: _steps
                            .map(
                              (s) => TimelineItem(
                                title: s.label,
                                subtitle: s.done ? 'Done' : 'Pending',
                                date: s.at != null
                                    ? dateFmt.format(s.at!.toLocal())
                                    : null,
                                icon: _iconFor(s.key),
                                isCompleted: s.done,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
    );
  }
}
