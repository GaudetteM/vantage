import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart' hide Direction;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/monetization_config.dart';
import '../utils/routes.dart';
import '../utils/vantage_theme.dart';
import '../widgets/board_widget.dart';
import '../widgets/hud_bar.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/star_rating.dart';
import 'completion_screen.dart';
import 'upgrade_screen.dart';

/// The main puzzle-play screen.
class GameScreen extends ConsumerStatefulWidget {
  final Level level;

  const GameScreen({super.key, required this.level});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  static const double _boardCellSize = 48;

  final FocusNode _focusNode = FocusNode();
  int _blockedMoveTick = 0;
  bool _isVictoryDialogOpen = false;
  String? _victoryShownForLevelId;

  @override
  void initState() {
    super.initState();
    // Load the level on the first frame after the widget tree settles.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).loadLevel(widget.level);
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final notifier = ref.read(gameProvider.notifier);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        _attemptMove(Direction.up);
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        _attemptMove(Direction.down);
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        _attemptMove(Direction.left);
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        _attemptMove(Direction.right);
      case LogicalKeyboardKey.keyQ:
        notifier.rotateCCW();
      case LogicalKeyboardKey.keyE:
        notifier.rotateCW();
      case LogicalKeyboardKey.keyR:
        notifier.reset();
    }
  }

  bool _attemptMove(Direction direction) {
    final moved = ref.read(gameProvider.notifier).tryMove(direction);
    if (!moved && mounted) {
      setState(() => _blockedMoveTick++);
    }
    return moved;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    if (gameState == null || gameState.level.id != widget.level.id) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!gameState.isSolved && _victoryShownForLevelId == gameState.level.id) {
      _victoryShownForLevelId = null;
    }

    // Show victory overlay when solved.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (gameState.isSolved &&
          !_isVictoryDialogOpen &&
          _victoryShownForLevelId != gameState.level.id) {
        _showVictoryDialog(gameState);
      }
    });

    Widget board = BoardWidget(gameState: gameState, cellSize: _boardCellSize);
    if (_blockedMoveTick > 0) {
      board = board
          .animate(key: ValueKey(_blockedMoveTick))
          .shake(duration: 220.ms, hz: 6, offset: const Offset(8, 0));
    }

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: VantageTheme.background,
        appBar: AppBar(
          backgroundColor: VantageTheme.surface,
          title: Text(
            widget.level.name.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          centerTitle: true,
          actions: [
            if (widget.level.hint != null)
              IconButton(
                tooltip: 'Hint',
                icon: const Icon(Icons.lightbulb_outline),
                onPressed: _showHintSheet,
              ),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.tune),
              onPressed: () => showSettingsSheet(context),
            ),
          ],
        ),
        body: Column(
          children: [
            HudBar(
              moveCount: gameState.moveCount,
              rotationCount: gameState.rotationCount,
              parRotations: widget.level.parRotations,
              currentRotationDeg: gameState.rotationDeg,
              onRotateCW: () => ref.read(gameProvider.notifier).rotateCW(),
              onRotateCCW: () => ref.read(gameProvider.notifier).rotateCCW(),
              onReset: () => ref.read(gameProvider.notifier).reset(),
            ),
            Expanded(
              child: GestureDetector(
                onPanEnd: (details) => _handleSwipe(details.velocity),
                child: LayoutBuilder(
                  builder: (context, _) {
                    final boardWidth =
                        gameState.level.gridCols * _boardCellSize;
                    final boardHeight =
                        gameState.level.gridRows * _boardCellSize;

                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: boardWidth,
                            height: boardHeight,
                            child: board,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            _DirectionPad(
              rotationDeg: gameState.rotationDeg,
              onMove: _attemptMove,
            ),
          ],
        ),
      ),
    );
  }

  void _showHintSheet() {
    final hint = widget.level.hint;
    if (hint == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _LevelHintSheet(
          name: widget.level.name,
          hint: hint,
          parRotations: widget.level.parRotations,
        );
      },
    );
  }

  void _handleSwipe(Velocity velocity) {
    const threshold = 300.0;
    final dx = velocity.pixelsPerSecond.dx;
    final dy = velocity.pixelsPerSecond.dy;
    if (dx.abs() > dy.abs()) {
      if (dx > threshold) _attemptMove(Direction.right);
      if (dx < -threshold) _attemptMove(Direction.left);
    } else {
      if (dy > threshold) _attemptMove(Direction.down);
      if (dy < -threshold) _attemptMove(Direction.up);
    }
  }

  void _showVictoryDialog(GameState gameState) {
    if (!mounted) return;
    _isVictoryDialogOpen = true;
    _victoryShownForLevelId = gameState.level.id;

    final levelsNow = ref.read(levelsProvider).valueOrNull;
    final hasFullGame =
        ref.read(monetizationProvider).valueOrNull?.hasFullGame ?? false;
    var hasNextLevel = false;
    var nextRequiresUnlock = false;
    if (levelsNow != null) {
      final currentIdx = levelsNow.indexWhere(
        (l) => l.id == gameState.level.id,
      );
      hasNextLevel = currentIdx >= 0 && currentIdx + 1 < levelsNow.length;
      nextRequiresUnlock =
          hasNextLevel &&
          !hasFullGame &&
          !MonetizationConfig.isInFreeChapter(currentIdx + 1);
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _VictoryDialog(
        moveCount: gameState.moveCount,
        rotationCount: gameState.rotationCount,
        parRotations: widget.level.parRotations,
        hasNextLevel: hasNextLevel,
        nextRequiresUnlock: nextRequiresUnlock,
        onNext: () async {
          Navigator.of(dialogContext).pop(); // close dialog
          final resolvedLevels =
              (levelsNow ?? await ref.read(levelsProvider.future)) ?? <Level>[];
          if (!mounted) return;

          final idx = resolvedLevels.indexWhere(
            (l) => l.id == gameState.level.id,
          );
          final nextLevel = idx >= 0 && idx + 1 < resolvedLevels.length
              ? resolvedLevels[idx + 1]
              : null;

          if (nextLevel != null &&
              !hasFullGame &&
              !MonetizationConfig.isInFreeChapter(idx + 1)) {
            Navigator.of(context).pushReplacement(
              fadeSlideRoute<void>(UpgradeScreen(targetLevel: nextLevel)),
            );
          } else if (nextLevel != null) {
            Navigator.of(context).pushReplacement(
              fadeSlideRoute<void>(GameScreen(level: nextLevel)),
            );
          } else {
            await ref
                .read(progressProvider.notifier)
                .recordCompletion(
                  gameState.level.id,
                  gameState.moveCount,
                  gameState.rotationCount,
                );
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              fadeSlideRoute<void>(
                CompletionScreen(
                  finalLevel: widget.level,
                  finalMoveCount: gameState.moveCount,
                  finalRotationCount: gameState.rotationCount,
                ),
              ),
            );
          }
        },
        onReplay: () {
          Navigator.of(dialogContext).pop();
          ref.read(gameProvider.notifier).reset();
        },
      ),
    ).whenComplete(() {
      _isVictoryDialogOpen = false;
    });
  }
}

class _LevelHintSheet extends StatelessWidget {
  final String name;
  final String hint;
  final int parRotations;

  const _LevelHintSheet({
    required this.name,
    required this.hint,
    required this.parRotations,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: VantageTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: VantageTheme.accentDim, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: VantageTheme.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        color: VantageTheme.accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Text(
                    'PAR $parRotations',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                hint,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CLOSE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// On-screen d-pad for mobile
// ---------------------------------------------------------------------------

class _DirectionPad extends StatelessWidget {
  final int rotationDeg;
  final void Function(Direction) onMove;

  const _DirectionPad({required this.rotationDeg, required this.onMove});

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: rotationDeg / 360.0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _padButton(Icons.arrow_upward, Direction.up),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _padButton(Icons.arrow_back, Direction.left),
                const SizedBox(width: 48),
                _padButton(Icons.arrow_forward, Direction.right),
              ],
            ),
            _padButton(Icons.arrow_downward, Direction.down),
          ],
        ),
      ),
    );
  }

  Widget _padButton(IconData icon, Direction direction) {
    return IconButton(
      icon: Icon(icon),
      color: VantageTheme.accent,
      iconSize: 32,
      onPressed: () => onMove(direction),
    );
  }
}

// ---------------------------------------------------------------------------
// Victory dialog
// ---------------------------------------------------------------------------

class _VictoryDialog extends StatelessWidget {
  final int moveCount;
  final int rotationCount;
  final int parRotations;
  final bool hasNextLevel;
  final bool nextRequiresUnlock;
  final VoidCallback onNext;
  final VoidCallback onReplay;

  const _VictoryDialog({
    required this.moveCount,
    required this.rotationCount,
    required this.parRotations,
    required this.hasNextLevel,
    required this.nextRequiresUnlock,
    required this.onNext,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final stars = starsEarned(rotationCount, parRotations);
    final headline = switch (stars) {
      3 => 'PERFECT SHIFT!',
      2 => 'GREAT RUN!',
      _ => 'SOLVED!',
    };
    return Dialog(
      backgroundColor: VantageTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StarRating(stars: stars, size: 40, animate: true),
            const SizedBox(height: 14),
            Text(headline, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Moves: $moveCount',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Rotations: $rotationCount (par $parRotations)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: stars == 3 ? VantageTheme.accent : Colors.white54,
              ),
            ),
            if (nextRequiresUnlock)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'You cleared the free chapter. The next level is part of the full game.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: onReplay,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('REPLAY'),
                ),
                ElevatedButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(
                    nextRequiresUnlock
                        ? 'UNLOCK'
                        : hasNextLevel
                        ? 'NEXT'
                        : 'FINISH',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
