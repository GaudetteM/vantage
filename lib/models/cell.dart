/// The type of a single cell in the maze grid.
enum CellType {
  empty,  // impassable void
  floor,  // passable in any rotation
  wall,   // always impassable
  start,  // player spawn
  goal,   // level exit
  // Perspective-shifted cells: passable only from specific rotation angles
  perspectiveNorth, // passable when board rotation == 0°
  perspectiveEast,  // passable when board rotation == 90°
  perspectiveSouth, // passable when board rotation == 180°
  perspectiveWest,  // passable when board rotation == 270°
}

extension CellTypeX on CellType {
  /// Returns true if this cell type is walkable at the given [rotationDeg]
  /// when normalized to one of 0, 90, 180, or 270.
  bool isWalkable(int rotationDeg) {
    final normalized = ((rotationDeg % 360) + 360) % 360;

    switch (this) {
      case CellType.floor:
      case CellType.start:
      case CellType.goal:
        return true;
      case CellType.perspectiveNorth:
        return normalized == 0;
      case CellType.perspectiveEast:
        return normalized == 90;
      case CellType.perspectiveSouth:
        return normalized == 180;
      case CellType.perspectiveWest:
        return normalized == 270;
      case CellType.empty:
      case CellType.wall:
        return false;
    }
  }
}

/// A single tile in the puzzle grid.
class Cell {
  final int row;
  final int col;
  final CellType type;

  const Cell({required this.row, required this.col, required this.type});

  Cell copyWith({CellType? type}) =>
      Cell(row: row, col: col, type: type ?? this.type);

  @override
  String toString() => 'Cell($row,$col,$type)';
}
