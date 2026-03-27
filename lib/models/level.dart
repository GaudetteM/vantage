import 'cell.dart';

/// A 2-D position on the grid.
class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  Position operator +(Position other) =>
      Position(row + other.row, col + other.col);

  @override
  bool operator ==(Object other) =>
      other is Position && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row, $col)';
}

/// Cardinal movement deltas. The logical direction is board-relative
/// (not screen-relative) and does not change as the board rotates — the
/// board rotation affects which cells are *walkable*, not the movement input.
const _deltas = {
  Direction.up: Position(-1, 0),
  Direction.down: Position(1, 0),
  Direction.left: Position(0, -1),
  Direction.right: Position(0, 1),
};

enum Direction { up, down, left, right }

extension DirectionX on Direction {
  Position get delta => _deltas[this]!;
}

/// Immutable description of one puzzle level.
class Level {
  final String id;
  final String name;
  final String? hint;
  final int gridRows;
  final int gridCols;
  final List<List<Cell>> grid; // [row][col]
  final Position startPos;
  final Position goalPos;
  final int parRotations; // minimum rotations to solve

  const Level({
    required this.id,
    required this.name,
    this.hint,
    required this.gridRows,
    required this.gridCols,
    required this.grid,
    required this.startPos,
    required this.goalPos,
    required this.parRotations,
  });

  Cell cellAt(Position pos) => grid[pos.row][pos.col];

  bool isInBounds(Position pos) =>
      pos.row >= 0 &&
      pos.row < gridRows &&
      pos.col >= 0 &&
      pos.col < gridCols;
}
