import '../models/models.dart';

// Shorthand constructors for compact level definitions.
Cell _c(int r, int c, CellType t) => Cell(row: r, col: c, type: t);
const e = CellType.empty;
const f = CellType.floor;
const w = CellType.wall;
const s = CellType.start;
const g = CellType.goal;
const pN = CellType.perspectiveNorth;
const pE = CellType.perspectiveEast;
const pS = CellType.perspectiveSouth;
const pW = CellType.perspectiveWest;

List<List<Cell>> _buildGrid(List<List<CellType>> types) {
  return List.generate(
    types.length,
    (r) => List.generate(
      types[r].length,
      (c) => _c(r, c, types[r][c]),
    ),
  );
}

// ---------------------------------------------------------------------------
// Level catalogue
// ---------------------------------------------------------------------------

final Level level1 = Level(
  id: 'level_01',
  name: 'First Glance',
  gridRows: 5,
  gridCols: 5,
  startPos: const Position(4, 0),
  goalPos: const Position(0, 4),
  parRotations: 1,
  grid: _buildGrid([
    [f, f, f, f, g],
    [w, w, f, w, w],
    [f, pN, f, pN, f],
    [f, w, w, w, f],
    [s, f, f, f, f],
  ]),
);

final Level level2 = Level(
  id: 'level_02',
  name: 'Shift & Step',
  gridRows: 6,
  gridCols: 6,
  startPos: const Position(5, 0),
  goalPos: const Position(0, 5),
  parRotations: 2,
  grid: _buildGrid([
    [f, pE, f, f, f, g],
    [f, w, w, w, f, w],
    [f, f, f, w, f, f],
    [w, w, pS, w, w, f],
    [f, f, f, f, pW, f],
    [s, f, w, w, f, f],
  ]),
);

final Level level3 = Level(
  id: 'level_03',
  name: 'Through the Looking Glass',
  gridRows: 7,
  gridCols: 7,
  startPos: const Position(6, 0),
  goalPos: const Position(0, 6),
  parRotations: 3,
  grid: _buildGrid([
    [f, f, f, f, f, f, g],
    [w, pN, w, pE, w, pS, w],
    [f, f, f, f, f, f, f],
    [w, pW, w, f, w, pN, w],
    [f, f, f, pE, f, f, f],
    [w, pS, w, w, w, pW, w],
    [s, f, f, f, f, f, f],
  ]),
);

/// All levels in order.
final List<Level> allLevels = [level1, level2, level3];
