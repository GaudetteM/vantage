import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/audio_service.dart';
import 'progress_provider.dart';

class AppSettings {
  final bool soundEnabled;
  final double soundVolume;
  final bool hapticsEnabled;

  const AppSettings({
    required this.soundEnabled,
    required this.soundVolume,
    required this.hapticsEnabled,
  });

  static const defaults = AppSettings(
    soundEnabled: true,
    soundVolume: 0.8,
    hapticsEnabled: true,
  );

  AppSettings copyWith({
    bool? soundEnabled,
    double? soundVolume,
    bool? hapticsEnabled,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'soundVolume': soundVolume,
        'hapticsEnabled': hapticsEnabled,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      soundVolume: (json['soundVolume'] as num?)?.toDouble() ?? 0.8,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _prefKey = 'vantage_settings';

  @override
  Future<AppSettings> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final raw = prefs.getString(_prefKey);

    final settings =
        raw == null ? AppSettings.defaults : AppSettings.fromJson(jsonDecode(raw));

    AudioService.configure(
      enabled: settings.soundEnabled,
      masterVolume: settings.soundVolume,
    );

    return settings;
  }

  Future<void> _persist(AppSettings settings) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_prefKey, jsonEncode(settings.toJson()));
    AudioService.configure(
      enabled: settings.soundEnabled,
      masterVolume: settings.soundVolume,
    );
    state = AsyncData(settings);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await _persist(current.copyWith(soundEnabled: enabled));
  }

  Future<void> setSoundVolume(double volume) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    final clamped = volume.clamp(0.0, 1.0);
    await _persist(current.copyWith(soundVolume: clamped));
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await _persist(current.copyWith(hapticsEnabled: enabled));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
