import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:vantage/models/models.dart';

final Directory _rootDir = File(Platform.script.toFilePath()).parent.parent;

class _Node {
  final Position pos;
  final int rot; // normalized: 0, 90, 180, 270

  const _Node(this.pos, this.rot);

  @override
  bool operator ==(Object other) =>
      other is _Node && other.pos == pos && other.rot == rot;

  @override
  int get hashCode => Object.hash(pos, rot);
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
      throw FormatException('Unknown tile: $ch');
  }
}

Level _parseLevel(String path, Map<String, dynamic> json) {
  final rows = (json['rows'] as List).cast<String>();
  final gridRows = rows.length;
  final gridCols = rows.first.length;

  Position? start;
  Position? goal;

  final grid = List<List<Cell>>.generate(gridRows, (r) {
    return List<Cell>.generate(gridCols, (c) {
      final type = _charToCellType(rows[r][c]);
      final pos = Position(r, c);
      if (type == CellType.start) start = pos;
      if (type == CellType.goal) goal = pos;
      return Cell(row: r, col: c, type: type);
    });
  });

  if (start == null || goal == null) {
    throw FormatException('Level ${json['id']} missing S or G');
  }

  return Level(
    id: json['id'] as String,
    name: json['name'] as String,
    hint: json['hint'] as String?,
    gridRows: gridRows,
    gridCols: gridCols,
    grid: grid,
    startPos: start!,
    goalPos: goal!,
    parRotations: json['parRotations'] as int,
  );
}

int _normalizeRot(int rot) => ((rot % 360) + 360) % 360;

bool _isSolvable(Level level) {
  final start = _Node(level.startPos, 0);
  final queue = Queue<_Node>()..add(start);
  final seen = <_Node>{start};

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (current.pos == level.goalPos) return true;

    // Moves
    for (final dir in Direction.values) {
      final nextPos = current.pos + dir.delta;
      if (nextPos.row < 0 || nextPos.row >= level.gridRows) continue;
      if (nextPos.col < 0 || nextPos.col >= level.gridCols) continue;
      final cell = level.cellAt(nextPos);
      if (!cell.type.isWalkable(current.rot)) continue;
      final next = _Node(nextPos, current.rot);
      if (seen.add(next)) queue.add(next);
    }

    // Rotations
    final cw = _Node(current.pos, _normalizeRot(current.rot + 90));
    final ccw = _Node(current.pos, _normalizeRot(current.rot - 90));
    if (seen.add(cw)) queue.add(cw);
    if (seen.add(ccw)) queue.add(ccw);
  }

  return false;
}

int? _minRotations(Level level) {
  // 0-1 BFS: move cost=0, rotate cost=1.
  final start = _Node(level.startPos, 0);
  final dist = <_Node, int>{start: 0};
  final deque = Queue<_Node>()..add(start);

  while (deque.isNotEmpty) {
    final current = deque.removeFirst();
    final curCost = dist[current]!;

    if (current.pos == level.goalPos) {
      // Keep going; there might be same-pos/rot with equal cost but no smaller
      // cost can appear after 0-1 BFS pops in nondecreasing order.
    }

    // Moves (cost 0)
    for (final dir in Direction.values) {
      final nextPos = current.pos + dir.delta;
      if (nextPos.row < 0 || nextPos.row >= level.gridRows) continue;
      if (nextPos.col < 0 || nextPos.col >= level.gridCols) continue;
      final cell = level.cellAt(nextPos);
      if (!cell.type.isWalkable(current.rot)) continue;

      final next = _Node(nextPos, current.rot);
      if (!dist.containsKey(next) || curCost < dist[next]!) {
        dist[next] = curCost;
        deque.addFirst(next);
      }
    }

    // Rotations (cost 1)
    for (final delta in const [90, -90]) {
      final next = _Node(current.pos, _normalizeRot(current.rot + delta));
      final nextCost = curCost + 1;
      if (!dist.containsKey(next) || nextCost < dist[next]!) {
        dist[next] = nextCost;
        deque.addLast(next);
      }
    }
  }

  int? best;
  for (final entry in dist.entries) {
    if (entry.key.pos == level.goalPos) {
      best = best == null
          ? entry.value
          : (entry.value < best ? entry.value : best);
    }
  }
  return best;
}

void main() {
  final indexFile = File('${_rootDir.path}/assets/levels/index.json');
  final indexJson =
      jsonDecode(indexFile.readAsStringSync()) as Map<String, dynamic>;
  final assets = (indexJson['levels'] as List).cast<String>();

  var allSolvable = true;
  for (final asset in assets) {
    final file = File('${_rootDir.path}/$asset');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final level = _parseLevel(asset, json);

    final solvable = _isSolvable(level);
    final minRot = _minRotations(level);
    final par = level.parRotations;
    final parMark = minRot == null
        ? 'n/a'
        : (par == minRot ? 'OK' : (par > minRot ? 'high' : 'LOW'));

    if (!solvable) allSolvable = false;

    stdout.writeln(
      '${level.id.padRight(18)} solvable=${solvable.toString().padRight(5)} '
      'minRot=${(minRot?.toString() ?? '-').padRight(2)} par=$par ($parMark)',
    );
  }

  if (!allSolvable) {
    stderr.writeln('ERROR: one or more levels are unsolvable.');
    exitCode = 1;
  }
}
