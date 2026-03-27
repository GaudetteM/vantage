import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/models.dart';

// Shorthand constructors for compact level definitions.
Cell _c(int r, int c, CellType t) => Cell(row: r, col: c, type: t);
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

CellType _charToCellType(String ch) {
  switch (ch) {
    case '#':
      return CellType.wall;
    case '.':
      return CellType.floor;
    case ' ':
      return CellType.empty;
    case 'S':
      return CellType.start;
    case 'G':
      return CellType.goal;
    case 'N':
      return CellType.perspectiveNorth;
    case 'E':
      return CellType.perspectiveEast;
    case 'T':
      return CellType.perspectiveSouth;
    case 'W':
      return CellType.perspectiveWest;
    default:
      throw FormatException('Unknown level tile "$ch"');
  }
}

Level _parseLevelFromJson(Map<String, dynamic> json) {
  final id = json['id'] as String;
  final name = json['name'] as String;
  final parRotations = json['parRotations'] as int;
  final rows = (json['rows'] as List).cast<String>();

  if (rows.isEmpty) {
    throw FormatException('Level "$id" has no rows');
  }

  final width = rows.first.length;
  if (rows.any((r) => r.length != width)) {
    throw FormatException('Level "$id" has inconsistent row widths');
  }

  Position? startPos;
  Position? goalPos;
  final gridTypes = List.generate(rows.length, (r) {
    return List.generate(width, (c) {
      final type = _charToCellType(rows[r][c]);
      if (type == CellType.start) startPos = Position(r, c);
      if (type == CellType.goal) goalPos = Position(r, c);
      return type;
    });
  });

  if (startPos == null || goalPos == null) {
    throw FormatException('Level "$id" must include exactly one S and one G');
  }

  return Level(
    id: id,
    name: name,
    gridRows: rows.length,
    gridCols: width,
    grid: _buildGrid(gridTypes),
    startPos: startPos!,
    goalPos: goalPos!,
    parRotations: parRotations,
  );
}

Future<Level> loadLevelFromAsset(String assetPath) async {
  final raw = await rootBundle.loadString(assetPath);
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return _parseLevelFromJson(decoded);
}

List<Level>? _levelsCache;

Future<List<Level>> loadLevels() async {
  if (_levelsCache != null) return _levelsCache!;

  final tutorialLevel = await loadLevelFromAsset(
    'assets/levels/level_00_tutorial.json',
  );

  final level1 = Level(
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

  final level2 = Level(
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

  final level3 = Level(
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

  _levelsCache = [tutorialLevel, level1, level2, level3];
  return _levelsCache!;
}
