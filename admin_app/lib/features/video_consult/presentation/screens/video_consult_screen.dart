import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/video_session_model.dart';
import '../../../../data/repositories/video_consult_repository.dart';
import '../../../../data/repositories/prescription_repository.dart';
import '../widgets/agora_video_call_view.dart';
import '../widgets/prescription_sheet.dart';

class VideoConsultScreen extends StatefulWidget {
  const VideoConsultScreen({
    super.key,
    required this.bookingId,
    this.peerName,
  });

  final String bookingId;
  final String? peerName;

  @override
  State<VideoConsultScreen> createState() => _VideoConsultScreenState();
}

class _VideoConsultScreenState extends State<VideoConsultScreen> {
  final _repository = VideoConsultRepository();
  final _prescriptionRepository = PrescriptionRepository();
  VideoSessionModel? _session;
  String? _error;
  bool _loading = true;
  bool _ending = false;
  bool _prescriptionSent = false;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;
  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSession() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await _repository.fetchSession(widget.bookingId);
      if (!mounted) return;

      if (!session.canJoin) {
        setState(() {
          _session = session;
          _loading = false;
          _error = session.message ?? 'Video call is not available right now';
        });
        return;
      }

      await _repository.markJoined(widget.bookingId);
      if (!mounted) return;

      if (session.isJitsi && session.joinUrl != null) {
        _webController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(session.joinUrl!));
      }

      _startElapsedTimer();
      await _loadPrescriptionStatus();
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _loadPrescriptionStatus() async {
    try {
      final contextData =
          await _prescriptionRepository.fetchContext(widget.bookingId);
      if (contextData.prescription?.isFinalized == true) {
        _prescriptionSent = true;
      }
    } catch (_) {
      // Ignore — prescription prompt still available manually.
    }
  }

  Future<void> _openPrescription() async {
    final saved = await PrescriptionSheet.show(
      context,
      bookingId: widget.bookingId,
      onSaved: () => _prescriptionSent = true,
    );
    if (saved == true && mounted) {
      setState(() => _prescriptionSent = true);
    }
  }

  Future<void> _endCall() async {
    if (_ending) return;

    if (!_prescriptionSent) {
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('End consultation?'),
          content: const Text(
            'You can write a prescription before ending the call. The patient will receive a PDF in their profile and by email.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'prescription'),
              child: const Text('Write prescription'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'end'),
              child: const Text('End without prescription'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (action == 'prescription') {
        await _openPrescription();
        return;
      }
      if (action != 'end') return;
    }

    setState(() => _ending = true);
    try {
      await _repository.markEnded(widget.bookingId);
    } catch (_) {
      // Still leave the screen if end tracking fails.
    }
    if (mounted) context.pop(true);
  }

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final peer = widget.peerName ?? _session?.peerName ?? 'Consultation';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: AppColors.white,
        title: Text(
          peer,
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.white),
        ),
        actions: [
          if (_session != null && _session!.canJoin)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  _formatElapsed(_elapsed),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.white,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(peer),
      floatingActionButton: _session != null && _session!.canJoin
          ? FloatingActionButton.extended(
              onPressed: _openPrescription,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.medication_rounded),
              label: const Text('Prescription'),
            )
          : null,
      bottomNavigationBar: _session != null && _session!.canJoin
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _ending ? null : _endCall,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: _ending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.call_end_rounded),
                  label: const Text('End call'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(String peer) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded,
                  size: 48, color: AppColors.white),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => context.pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: BorderSide(color: AppColors.white.withValues(alpha: 0.54)),
                ),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    final session = _session!;
    if (session.isAgora) {
      return AgoraVideoCallView(
        appId: session.agoraAppId!,
        token: session.agoraToken ?? '',
        channelName: session.agoraChannel!,
        uid: session.agoraUid!,
        peerName: peer,
        label: session.label,
      );
    }

    if (session.isJitsi && _webController != null) {
      return WebViewWidget(controller: _webController!);
    }

    return _MockVideoCallView(
      peerName: peer,
      role: session.role,
      label: session.label,
    );
  }
}

class _MockVideoCallView extends StatelessWidget {
  const _MockVideoCallView({
    required this.peerName,
    required this.role,
    this.label,
  });

  final String peerName;
  final String role;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final selfLabel = role == 'doctor' ? 'You (Doctor)' : 'You (Patient)';

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.25),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      peerName,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (label != null && label!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        label!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Connected (demo mode)',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.videocam_rounded,
                        color: AppColors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selfLabel,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Demo video consult — set VIDEO_PROVIDER=agora on the API for live video.',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}
