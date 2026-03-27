import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart' hide Direction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/vantage_theme.dart';
import '../widgets/board_widget.dart';
import '../widgets/hud_bar.dart';
import '../widgets/settings_sheet.dart';

/// The main puzzle-play screen.
class GameScreen extends ConsumerStatefulWidget {
  final Level level;

  const GameScreen({super.key, required this.level});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
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
    final progressAsync = ref.watch(progressProvider);
    if (gameState == null || gameState.level.id != widget.level.id) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tutorialCompleted = progressAsync.maybeWhen(
      data: (progress) =>
          progress['level_00_tutorial']?.isCompleted ?? false,
      orElse: () => false,
    );

    if (!gameState.isSolved &&
        _victoryShownForLevelId == gameState.level.id) {
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

    Widget board = BoardWidget(gameState: gameState);
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
              onRotateCW: () => ref.read(gameProvider.notifier).rotateCW(),
              onRotateCCW: () => ref.read(gameProvider.notifier).rotateCCW(),
              onReset: () => ref.read(gameProvider.notifier).reset(),
            ),
            if (widget.level.id == 'level_00_tutorial' && !tutorialCompleted)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: VantageTheme.surface.withAlpha(180),
                child: const Text(
                  'Tutorial: the purple gate opens only at one rotation. Rotate once, then move to the star.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: GestureDetector(
                onPanEnd: (details) => _handleSwipe(details.velocity),
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: board,
                    ),
                  ),
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
    var hasNextLevel = false;
    if (levelsNow != null) {
      final currentIdx = levelsNow.indexWhere((l) => l.id == gameState.level.id);
      hasNextLevel = currentIdx >= 0 && currentIdx + 1 < levelsNow.length;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _VictoryDialog(
        moveCount: gameState.moveCount,
        rotationCount: gameState.rotationCount,
        parRotations: widget.level.parRotations,
        hasNextLevel: hasNextLevel,
        onNext: () async {
          Navigator.of(dialogContext).pop(); // close dialog
          final resolvedLevels =
              (levelsNow ?? await ref.read(levelsProvider.future)) ?? <Level>[];
          if (!mounted) return;

          final idx = resolvedLevels.indexWhere((l) => l.id == gameState.level.id);
          final nextLevel =
              idx >= 0 && idx + 1 < resolvedLevels.length ? resolvedLevels[idx + 1] : null;

          if (nextLevel != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => GameScreen(level: nextLevel),
              ),
            );
          } else {
            Navigator.of(context).pop(); // back to level select
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

// ---------------------------------------------------------------------------
// On-screen d-pad for mobile
// ---------------------------------------------------------------------------

class _DirectionPad extends StatelessWidget {
  final int rotationDeg;
  final void Function(Direction) onMove;

  const _DirectionPad({
    required this.rotationDeg,
    required this.onMove,
  });

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
  final VoidCallback onNext;
  final VoidCallback onReplay;

  const _VictoryDialog({
    required this.moveCount,
    required this.rotationCount,
    required this.parRotations,
    required this.hasNextLevel,
    required this.onNext,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final underPar = rotationCount <= parRotations;
    return Dialog(
      backgroundColor: VantageTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: VantageTheme.goalColor, size: 48)
                .animate()
                .scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 12),
            Text(
              underPar ? 'PERFECT SHIFT!' : 'SOLVED!',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text('Moves: $moveCount',
                style: Theme.of(context).textTheme.bodyMedium),
            Text('Rotations: $rotationCount (par $parRotations)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: underPar
                        ? VantageTheme.accent
                        : Colors.white54)),
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
                  label: Text(hasNextLevel ? 'NEXT' : 'LEVELS'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
