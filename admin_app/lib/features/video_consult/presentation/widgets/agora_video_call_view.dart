import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AgoraVideoCallView extends StatefulWidget {
  const AgoraVideoCallView({
    super.key,
    required this.appId,
    required this.token,
    required this.channelName,
    required this.uid,
    required this.peerName,
    this.label,
  });

  final String appId;
  final String token;
  final String channelName;
  final int uid;
  final String peerName;
  final String? label;

  @override
  State<AgoraVideoCallView> createState() => _AgoraVideoCallViewState();
}

class _AgoraVideoCallViewState extends State<AgoraVideoCallView> {
  RtcEngine? _engine;
  bool _joined = false;
  bool _muted = false;
  bool _videoEnabled = true;
  int? _remoteUid;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  @override
  void dispose() {
    _disposeEngine();
    super.dispose();
  }

  Future<void> _disposeEngine() async {
    final engine = _engine;
    if (engine == null) return;
    await engine.leaveChannel();
    await engine.release();
    _engine = null;
  }

  Future<void> _initAgora() async {
    try {
      await [Permission.microphone, Permission.camera].request();

      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: widget.appId));
      await engine.enableVideo();
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine.startPreview();

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            if (!mounted) return;
            setState(() => _joined = true);
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (!mounted) return;
            setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (!mounted) return;
            setState(() {
              if (_remoteUid == remoteUid) _remoteUid = null;
            });
          },
          onError: (err, msg) {
            if (!mounted) return;
            setState(() => _error = msg);
          },
        ),
      );

      await engine.joinChannel(
        token: widget.token,
        channelId: widget.channelName,
        uid: widget.uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      if (!mounted) return;
      setState(() => _engine = engine);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _toggleMute() async {
    final engine = _engine;
    if (engine == null) return;
    final next = !_muted;
    await engine.muteLocalAudioStream(next);
    setState(() => _muted = next);
  }

  Future<void> _toggleVideo() async {
    final engine = _engine;
    if (engine == null) return;
    final next = !_videoEnabled;
    await engine.muteLocalVideoStream(next);
    setState(() => _videoEnabled = next);
  }

  Future<void> _switchCamera() async {
    await _engine?.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      );
    }

    if (_engine == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildRemoteView(),
              Positioned(
                right: 16,
                bottom: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 120,
                    height: 160,
                    child: _videoEnabled
                        ? AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: _engine!,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          )
                        : ColoredBox(
                            color: const Color(0xFF334155),
                            child: Icon(
                              Icons.videocam_off_rounded,
                              color: AppColors.white.withValues(alpha: 0.7),
                            ),
                          ),
                  ),
                ),
              ),
              if (!_joined)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.white),
                ),
            ],
          ),
        ),
        Container(
          color: const Color(0xFF1E293B),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: _muted ? 'Unmute' : 'Mute',
                onPressed: _toggleMute,
              ),
              _ControlButton(
                icon: _videoEnabled
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
                label: _videoEnabled ? 'Video off' : 'Video on',
                onPressed: _toggleVideo,
              ),
              _ControlButton(
                icon: Icons.cameraswitch_rounded,
                label: 'Flip',
                onPressed: _switchCamera,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRemoteView() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    }

    return Container(
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
            widget.peerName,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (widget.label != null && widget.label!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.label!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _joined ? 'Waiting for ${widget.peerName} to join…' : 'Connecting…',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF334155),
            foregroundColor: AppColors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
