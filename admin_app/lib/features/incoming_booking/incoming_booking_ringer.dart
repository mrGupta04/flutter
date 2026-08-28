import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

/// Loops the system ringtone and haptic pulse until [stop] is called.
class IncomingBookingRinger {
  IncomingBookingRinger._();
  static final IncomingBookingRinger instance = IncomingBookingRinger._();

  final _player = FlutterRingtonePlayer();
  Timer? _haptic;
  Timer? _iosRepeat;
  bool _playing = false;

  bool get isPlaying => _playing;

  Future<void> start() async {
    await stop();
    _playing = true;
    await _playTone();
    if (!kIsWeb && Platform.isIOS) {
      _iosRepeat = Timer.periodic(const Duration(seconds: 2), (_) {
        if (_playing) {
          _playTone();
        }
      });
    }
    _haptic = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (_playing) {
        HapticFeedback.heavyImpact();
      }
    });
    unawaited(HapticFeedback.heavyImpact());
  }

  Future<void> _playTone() async {
    try {
      await _player.playRingtone(
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
    } catch (_) {
      try {
        await _player.play(
          android: AndroidSounds.ringtone,
          ios: IosSounds.electronic,
          looping: true,
          volume: 1.0,
          asAlarm: true,
        );
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    _playing = false;
    _haptic?.cancel();
    _haptic = null;
    _iosRepeat?.cancel();
    _iosRepeat = null;
    try {
      await _player.stop();
    } catch (_) {}
  }
}
