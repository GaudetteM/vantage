import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();

  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  static bool _enabled = true;
  static double _masterVolume = 1.0;

  // Relative SFX mix (0.0 - 1.0).
  static const double _moveVolume = 0.35;
  static const double _blockedVolume = 0.50;
  static const double _rotateVolume = 0.45;
  static const double _solvedVolume = 0.80;

  static void configure({required bool enabled, required double masterVolume}) {
    _enabled = enabled;
    _masterVolume = masterVolume.clamp(0.0, 1.0);
  }

  static Future<void> _play(String fileName, double volume) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.setVolume((volume * _masterVolume).clamp(0.0, 1.0));
      await _player.play(AssetSource('audio/$fileName'));
    } catch (_) {
      // Ignore missing/unconfigured audio files in early development.
    }
  }

  static Future<void> playMove() => _play('move.wav', _moveVolume);

  static Future<void> playBlocked() => _play('blocked.wav', _blockedVolume);

  static Future<void> playRotate() => _play('rotate.wav', _rotateVolume);

  static Future<void> playSolved() => _play('solved.wav', _solvedVolume);
}