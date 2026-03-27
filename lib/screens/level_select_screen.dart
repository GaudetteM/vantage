import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/routes.dart';
import '../models/level_progress.dart' show starsEarned;
import '../utils/vantage_theme.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/star_rating.dart';
import 'game_screen.dart';

/// Level-selection hub screen.
class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(levelsProvider);
    final progressAsync = ref.watch(progressProvider);

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
            onPressed: () => showSettingsSheet(context),
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

  Color _borderColor(LevelProgress p, int par) {
    if (!p.isCompleted) return p.isUnlocked ? VantageTheme.accentDim : Colors.white12;
    final stars = starsEarned(p.bestRotations!, par);
    if (stars == 3) return VantageTheme.goalColor;
    if (stars == 2) return VantageTheme.goalColor.withAlpha(160);
    return VantageTheme.goalColor.withAlpha(80);
  }

  @override
  Widget build(BuildContext context) {
    final locked = !progress.isUnlocked;

    return GestureDetector(
      onTap: locked
          ? null
          : () => Navigator.of(context)
                .push(fadeSlideRoute<void>(GameScreen(level: level))),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: locked ? VantageTheme.surface.withAlpha(120) : VantageTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _borderColor(progress, level.parRotations),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (locked)
                const Icon(Icons.lock, color: Colors.white24, size: 28)
              else if (progress.isCompleted && progress.bestRotations != null)
                StarRating(
                  stars: starsEarned(
                      progress.bestRotations!, level.parRotations),
                  size: 20,
                )
              else
                const Icon(Icons.grid_view,
                    color: VantageTheme.accent, size: 28),
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
                    '${progress.bestRotations} / par ${level.parRotations}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 9),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
