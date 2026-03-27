import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../utils/vantage_theme.dart';

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: VantageTheme.surface,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: settingsAsync.when(
          loading: () => const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 140,
            child: Center(
              child: Text(
                'Settings failed to load: $e',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
          data: (settings) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sound', style: TextStyle(color: Colors.white)),
                  value: settings.soundEnabled,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setSoundEnabled(v),
                ),
                Opacity(
                  opacity: settings.soundEnabled ? 1.0 : 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SFX Volume ${(settings.soundVolume * 100).round()}%',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Slider(
                        value: settings.soundVolume,
                        min: 0,
                        max: 1,
                        onChanged: settings.soundEnabled
                            ? (v) =>
                                ref.read(settingsProvider.notifier).setSoundVolume(v)
                            : null,
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Haptics', style: TextStyle(color: Colors.white)),
                  value: settings.hapticsEnabled,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setHapticsEnabled(v),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
