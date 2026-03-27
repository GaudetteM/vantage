import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart' hide Direction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/vantage_theme.dart';
import '../widgets/board_widget.dart';
import '../widgets/hud_bar.dart';

/// The main puzzle-play screen.
class GameScreen extends ConsumerStatefulWidget {
  final Level level;

  const GameScreen({super.key, required this.level});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final FocusNode _focusNode = FocusNode();

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
        notifier.move(Direction.up);
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        notifier.move(Direction.down);
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        notifier.move(Direction.left);
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        notifier.move(Direction.right);
      case LogicalKeyboardKey.keyQ:
        notifier.rotateCCW();
      case LogicalKeyboardKey.keyE:
        notifier.rotateCW();
      case LogicalKeyboardKey.keyR:
        notifier.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show victory overlay when solved.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (gameState.isSolved && mounted) _showVictoryDialog(gameState);
    });

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
            Expanded(
              child: GestureDetector(
                onPanEnd: (details) => _handleSwipe(details.velocity),
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: BoardWidget(gameState: gameState),
                    ),
                  ),
                ),
              ),
            ),
            _DirectionPad(
              rotationDeg: gameState.rotationDeg,
              onMove: (d) => ref.read(gameProvider.notifier).move(d),
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
      if (dx > threshold) ref.read(gameProvider.notifier).move(Direction.right);
      if (dx < -threshold) ref.read(gameProvider.notifier).move(Direction.left);
    } else {
      if (dy > threshold) ref.read(gameProvider.notifier).move(Direction.down);
      if (dy < -threshold) ref.read(gameProvider.notifier).move(Direction.up);
    }
  }

  void _showVictoryDialog(GameState gameState) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VictoryDialog(
        moveCount: gameState.moveCount,
        rotationCount: gameState.rotationCount,
        parRotations: widget.level.parRotations,
        onNext: () {
          Navigator.of(context).pop(); // close dialog
          Navigator.of(context).pop(); // back to level select
        },
        onReplay: () {
          Navigator.of(context).pop();
          ref.read(gameProvider.notifier).reset();
        },
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
  final VoidCallback onNext;
  final VoidCallback onReplay;

  const _VictoryDialog({
    required this.moveCount,
    required this.rotationCount,
    required this.parRotations,
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
                  label: const Text('LEVELS'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
