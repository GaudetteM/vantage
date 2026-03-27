import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/routes.dart';
import '../utils/vantage_theme.dart';
import '../widgets/star_rating.dart';
import 'game_screen.dart';

class CompletionScreen extends ConsumerWidget {
  final Level finalLevel;
  final int finalMoveCount;
  final int finalRotationCount;

  const CompletionScreen({
    super.key,
    required this.finalLevel,
    required this.finalMoveCount,
    required this.finalRotationCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(levelsProvider);
    final progressAsync = ref.watch(progressProvider);

    return Scaffold(
      backgroundColor: VantageTheme.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _CompletionBackdrop()),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: levelsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _CompletionShell(
                      child: Text(
                        'Failed to load completion stats: $error',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    data: (levels) => progressAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => _CompletionShell(
                        child: Text(
                          'Failed to load completion stats: $error',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      data: (progress) {
                        final mergedProgress = _withFinalRun(progress);
                        final solvedLevels = levels
                            .where(
                              (level) =>
                                  mergedProgress[level.id]?.isCompleted ??
                                  false,
                            )
                            .length;
                        final totalStars = levels.fold<int>(0, (sum, level) {
                          final levelProgress = mergedProgress[level.id];
                          if (levelProgress == null ||
                              !levelProgress.isCompleted ||
                              levelProgress.bestRotations == null) {
                            return sum;
                          }
                          return sum +
                              starsEarned(
                                levelProgress.bestRotations!,
                                level.parRotations,
                              );
                        });
                        final maxStars = levels.length * 3;
                        final perfectLevels = levels.where((level) {
                          final levelProgress = mergedProgress[level.id];
                          return levelProgress != null &&
                              levelProgress.isCompleted &&
                              levelProgress.bestRotations != null &&
                              starsEarned(
                                    levelProgress.bestRotations!,
                                    level.parRotations,
                                  ) ==
                                  3;
                        }).length;
                        final finalStars = starsEarned(
                          finalRotationCount,
                          finalLevel.parRotations,
                        );
                        final perfectRun = totalStars == maxStars;

                        return _CompletionShell(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _CompletionDiamond()
                                  .animate()
                                  .scale(
                                    begin: const Offset(0.75, 0.75),
                                    end: const Offset(1, 1),
                                    duration: 520.ms,
                                    curve: Curves.easeOutBack,
                                  )
                                  .fadeIn(duration: 320.ms),
                              const SizedBox(height: 24),
                              Text(
                                perfectRun
                                    ? 'TOTAL ALIGNMENT'
                                    : 'VANTAGE CLEARED',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(fontSize: 28, letterSpacing: 5),
                              ).animate(delay: 120.ms).fadeIn(duration: 260.ms),
                              const SizedBox(height: 12),
                              Text(
                                perfectRun
                                    ? 'Every route solved at par or better.'
                                    : 'You solved every level. Perfect the set for $maxStars/$maxStars stars.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                              ).animate(delay: 180.ms).fadeIn(duration: 260.ms),
                              const SizedBox(height: 28),
                              Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(10),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: VantageTheme.accentDim,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          finalLevel.name.toUpperCase(),
                                          style: const TextStyle(
                                            color: VantageTheme.accent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 2.4,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        StarRating(
                                          stars: finalStars,
                                          size: 34,
                                          animate: true,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Final run: $finalMoveCount moves · $finalRotationCount rotations',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate(delay: 240.ms)
                                  .fadeIn(duration: 260.ms)
                                  .slideY(begin: 0.08, end: 0),
                              const SizedBox(height: 20),
                              Row(
                                    children: [
                                      Expanded(
                                        child: _StatTile(
                                          label: 'STARS',
                                          value: '$totalStars/$maxStars',
                                          accentColor: VantageTheme.goalColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _StatTile(
                                          label: 'SOLVED',
                                          value:
                                              '$solvedLevels/${levels.length}',
                                          accentColor: VantageTheme.accent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _StatTile(
                                          label: 'PERFECT',
                                          value: '$perfectLevels',
                                          accentColor: VantageTheme
                                              .perspectiveNorthColor,
                                        ),
                                      ),
                                    ],
                                  )
                                  .animate(delay: 320.ms)
                                  .fadeIn(duration: 260.ms)
                                  .slideY(begin: 0.08, end: 0),
                              const SizedBox(height: 24),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        Navigator.of(context).pushReplacement(
                                          fadeSlideRoute<void>(
                                            GameScreen(level: finalLevel),
                                          ),
                                        ),
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('REPLAY FINAL'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(
                                      Icons.grid_view_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('LEVEL SELECT'),
                                  ),
                                ],
                              ).animate(delay: 400.ms).fadeIn(duration: 260.ms),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, LevelProgress> _withFinalRun(
    Map<String, LevelProgress> progress,
  ) {
    final existing =
        progress[finalLevel.id] ??
        LevelProgress(levelId: finalLevel.id, isUnlocked: true);

    final bestMoves =
        existing.bestMoves == null || finalMoveCount < existing.bestMoves!
        ? finalMoveCount
        : existing.bestMoves;
    final bestRotations =
        existing.bestRotations == null ||
            finalRotationCount < existing.bestRotations!
        ? finalRotationCount
        : existing.bestRotations;

    return {
      ...progress,
      finalLevel.id: existing.copyWith(
        isUnlocked: true,
        isCompleted: true,
        bestMoves: bestMoves,
        bestRotations: bestRotations,
      ),
    };
  }
}

class _CompletionShell extends StatelessWidget {
  final Widget child;

  const _CompletionShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: VantageTheme.surface.withAlpha(232),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 36,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withAlpha(110), width: 1.1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionDiamond extends StatelessWidget {
  const _CompletionDiamond();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            transform: Matrix4.rotationZ(0.78539816339),
          ),
          _diamondDot(Alignment.topCenter, VantageTheme.perspectiveNorthColor),
          _diamondDot(Alignment.centerRight, VantageTheme.perspectiveEastColor),
          _diamondDot(
            Alignment.bottomCenter,
            VantageTheme.perspectiveSouthColor,
          ),
          _diamondDot(Alignment.centerLeft, VantageTheme.perspectiveWestColor),
          Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: VantageTheme.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: VantageTheme.accent.withAlpha(120),
                      blurRadius: 18,
                    ),
                  ],
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 0.92, end: 1.08, duration: 1400.ms),
        ],
      ),
    );
  }

  Widget _diamondDot(Alignment alignment, Color color) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withAlpha(90), blurRadius: 12)],
        ),
      ),
    );
  }
}

class _CompletionBackdrop extends StatelessWidget {
  const _CompletionBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.25),
          radius: 1.05,
          colors: [Color(0xFF1A1A2E), VantageTheme.background],
        ),
      ),
      child: CustomPaint(painter: _CompletionBackdropPainter()),
    );
  }
}

class _CompletionBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = VantageTheme.accentDim.withAlpha(18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const spacing = 56.0;
    const half = spacing / 2;

    for (var row = -1.0; row < size.height / spacing + 2; row++) {
      for (var col = -1.0; col < size.width / spacing + 2; col++) {
        final cx = col * spacing + (row.toInt().isOdd ? half : 0);
        final cy = row * spacing;
        final path = Path()
          ..moveTo(cx, cy - half)
          ..lineTo(cx + half, cy)
          ..lineTo(cx, cy + half)
          ..lineTo(cx - half, cy)
          ..close();
        canvas.drawPath(path, gridPaint);
      }
    }

    final glowPaint = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0x2600E5FF), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height * 0.3),
              radius: size.width * 0.38,
            ),
          );
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.3),
      size.width * 0.38,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
