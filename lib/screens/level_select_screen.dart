import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/vantage_theme.dart';
import 'game_screen.dart';

/// Level-selection hub screen.
class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(levelsProvider);
    final progressAsync = ref.watch(progressProvider);
    final _ = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: VantageTheme.background,
      appBar: AppBar(
        backgroundColor: VantageTheme.surface,
        title: Text(
          'VANTAGE',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 22,
                letterSpacing: 8,
              ),
        ),
        centerTitle: true,
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Reset Progress (Debug)',
              icon: const Icon(Icons.restart_alt),
              onPressed: () async {
                await ref.read(progressProvider.notifier).resetProgress();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progress reset.')),
                );
              },
            ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune),
            onPressed: () => _openSettingsSheet(context),
          ),
        ],
      ),
      body: levelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (levels) => progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (progress) => GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 160,
            ),
            itemCount: levels.length,
            itemBuilder: (context, i) {
              final level = levels[i];
              final p = progress[level.id] ?? LevelProgress(levelId: level.id);
              return _LevelCard(
                level: level,
                progress: p,
                index: i,
              )
                  .animate(delay: (80 * i).ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.2, end: 0);
            },
          ),
        ),
      ),
    );
  }

  void _openSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VantageTheme.surface,
      builder: (_) => const _SettingsSheet(),
    );
  }
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
                            ? (v) => ref
                                .read(settingsProvider.notifier)
                                .setSoundVolume(v)
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

class _LevelCard extends StatelessWidget {
  final Level level;
  final LevelProgress progress;
  final int index;

  const _LevelCard({
    required this.level,
    required this.progress,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !progress.isUnlocked;

    return GestureDetector(
      onTap: locked
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => GameScreen(level: level),
                ),
              ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: locked ? VantageTheme.surface.withAlpha(120) : VantageTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: progress.isCompleted
                ? VantageTheme.goalColor
                : locked
                    ? Colors.white12
                    : VantageTheme.accentDim,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                locked
                    ? Icons.lock
                    : progress.isCompleted
                        ? Icons.star
                        : Icons.grid_view,
                color: locked
                    ? Colors.white24
                    : progress.isCompleted
                        ? VantageTheme.goalColor
                        : VantageTheme.accent,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                '${index + 1}',
                style: TextStyle(
                  color: locked ? Colors.white24 : VantageTheme.accent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                level.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: locked ? Colors.white24 : Colors.white60,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (progress.isCompleted && progress.bestRotations != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Best: ${progress.bestRotations} rot.',
                    style: const TextStyle(
                        color: VantageTheme.goalColor, fontSize: 9),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
