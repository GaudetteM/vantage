import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/models.dart';

// Shorthand constructor for compact grid building.
Cell _c(int r, int c, CellType t) => Cell(row: r, col: c, type: t);

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
  final id = json['id'] as String?;
  final name = json['name'] as String?;
  final parRotations = json['parRotations'] as int?;
  final rowsDynamic = json['rows'];

  if (id == null || id.isEmpty) {
    throw const FormatException('Level json is missing non-empty "id"');
  }
  if (name == null || name.isEmpty) {
    throw FormatException('Level "$id" is missing non-empty "name"');
  }
  if (parRotations == null) {
    throw FormatException('Level "$id" is missing integer "parRotations"');
  }
  if (rowsDynamic is! List) {
    throw FormatException('Level "$id" is missing list "rows"');
  }

  final rows = rowsDynamic.cast<String>();

  if (rows.isEmpty) {
    throw FormatException('Level "$id" has no rows');
  }

  final width = rows.first.length;
  if (rows.any((r) => r.length != width)) {
    throw FormatException('Level "$id" has inconsistent row widths');
  }

  Position? startPos;
  Position? goalPos;
  var startCount = 0;
  var goalCount = 0;

  final gridTypes = List.generate(rows.length, (r) {
    return List.generate(width, (c) {
      final type = _charToCellType(rows[r][c]);
      if (type == CellType.start) {
        startCount++;
        startPos = Position(r, c);
      }
      if (type == CellType.goal) {
        goalCount++;
        goalPos = Position(r, c);
      }
      return type;
    });
  });

  if (startCount != 1 || goalCount != 1 || startPos == null || goalPos == null) {
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

  final indexRaw = await rootBundle.loadString('assets/levels/index.json');
  final indexJson = jsonDecode(indexRaw) as Map<String, dynamic>;
  final levelsDynamic = indexJson['levels'];
  if (levelsDynamic is! List) {
    throw const FormatException('levels/index.json must contain a list "levels"');
  }

  final orderedAssets = levelsDynamic.cast<String>();
  if (orderedAssets.isEmpty) {
    throw const FormatException('levels/index.json must list at least one level asset');
  }

  final duplicates = <String>{};
  final seen = <String>{};
  for (final asset in orderedAssets) {
    if (!seen.add(asset)) duplicates.add(asset);
  }
  if (duplicates.isNotEmpty) {
    throw FormatException(
      'levels/index.json contains duplicate entries: ${duplicates.join(', ')}',
    );
  }

  _levelsCache = [
    for (final asset in orderedAssets) await loadLevelFromAsset(asset),
  ];
  return _levelsCache!;
}
