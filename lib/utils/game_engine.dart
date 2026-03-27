import '../models/models.dart';

/// Pure logic for advancing game state. No Flutter dependencies.
class GameEngine {
  /// Attempt to move the player one step in [direction].
  /// Returns the updated [GameState] (unchanged if move is blocked).
  static GameState move(GameState state, Direction direction) {
    if (state.isSolved) return state;

    final newPos = state.playerPos + direction.delta;
    final level = state.level;

    if (!level.isInBounds(newPos)) return state;

    final cell = level.cellAt(newPos);
    if (!cell.type.isWalkable(state.rotationDeg)) return state;

    final arrived = newPos == level.goalPos;

    return state.copyWith(
      playerPos: newPos,
      moveCount: state.moveCount + 1,
      isSolved: arrived,
    );
  }

  /// Rotate the board clockwise by 90°.
  static GameState rotateCW(GameState state) {
    if (state.isSolved) return state;
    return state.copyWith(
      rotationDeg: state.nextClockwiseRotation,
      rotationCount: state.rotationCount + 1,
    );
  }

  /// Rotate the board counter-clockwise by 90°.
  static GameState rotateCCW(GameState state) {
    if (state.isSolved) return state;
    return state.copyWith(
      rotationDeg: state.nextCounterClockwiseRotation,
      rotationCount: state.rotationCount + 1,
    );
  }

  /// Reset to initial state for the same level.
  static GameState reset(GameState state) => GameState.initial(state.level);
}
