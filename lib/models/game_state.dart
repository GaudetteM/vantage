import 'level.dart';

/// Runtime mutable state of an active puzzle.
class GameState {
  final Level level;
  final Position playerPos;
  final int rotationDeg; // can grow unbounded for smooth animation
  final int moveCount;
  final int rotationCount;
  final bool isSolved;

  const GameState({
    required this.level,
    required this.playerPos,
    this.rotationDeg = 0,
    this.moveCount = 0,
    this.rotationCount = 0,
    this.isSolved = false,
  });

  factory GameState.initial(Level level) => GameState(
        level: level,
        playerPos: level.startPos,
      );

  GameState copyWith({
    Position? playerPos,
    int? rotationDeg,
    int? moveCount,
    int? rotationCount,
    bool? isSolved,
  }) =>
      GameState(
        level: level,
        playerPos: playerPos ?? this.playerPos,
        rotationDeg: rotationDeg ?? this.rotationDeg,
        moveCount: moveCount ?? this.moveCount,
        rotationCount: rotationCount ?? this.rotationCount,
        isSolved: isSolved ?? this.isSolved,
      );

  /// Clockwise rotation: keeps accumulating to avoid wrap-around animation jumps.
  int get nextClockwiseRotation => rotationDeg + 90;

  /// Counter-clockwise rotation: keeps accumulating negative values as needed.
  int get nextCounterClockwiseRotation => rotationDeg - 90;

  @override
  String toString() =>
      'GameState(pos=$playerPos, rot=$rotationDeg°, moves=$moveCount, rotations=$rotationCount, solved=$isSolved)';
}
