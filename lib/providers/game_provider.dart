import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../utils/game_engine.dart';
import '../utils/level_repository.dart';
import 'progress_provider.dart';

// ---------------------------------------------------------------------------
// Active game notifier
// ---------------------------------------------------------------------------

class GameNotifier extends Notifier<GameState?> {
  @override
  GameState? build() => null;

  void loadLevel(Level level) {
    state = GameState.initial(level);
  }

  bool tryMove(Direction direction) {
    final current = state;
    if (current == null) return false;
    final next = GameEngine.move(current, direction);
    if (next == current) return false; // blocked move
    state = next;
    if (next.isSolved) {
      ref.read(progressProvider.notifier).recordCompletion(
            next.level.id,
            next.moveCount,
            next.rotationCount,
          );
    }
    return true;
  }

  void move(Direction direction) {
    tryMove(direction);
  }

  void rotateCW() {
    final current = state;
    if (current == null) return;
    state = GameEngine.rotateCW(current);
  }

  void rotateCCW() {
    final current = state;
    if (current == null) return;
    state = GameEngine.rotateCCW(current);
  }

  void reset() {
    final current = state;
    if (current == null) return;
    state = GameEngine.reset(current);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState?>(
  GameNotifier.new,
);

// ---------------------------------------------------------------------------
// Convenience: ordered list of all levels (no async needed)
// ---------------------------------------------------------------------------

final levelsProvider = Provider<List<Level>>((ref) => allLevels);
