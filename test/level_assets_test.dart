import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

typedef PassableRule = bool Function(int rotation);

const _passable = <String, PassableRule>{
  '.': _always,
  'S': _always,
  'G': _always,
  'N': _north,
  'E': _east,
  'T': _south,
  'W': _west,
};

bool _always(int _) => true;
bool _north(int r) => r == 0;
bool _east(int r) => r == 90;
bool _south(int r) => r == 180;
bool _west(int r) => r == 270;

({int minRotations, int minMoves})? _solve(List<String> rows) {
  final height = rows.length;
  final width = rows.first.length;

  int? startR, startC, goalR, goalC;
  for (var r = 0; r < height; r++) {
    for (var c = 0; c < width; c++) {
      final ch = rows[r][c];
      if (ch == 'S') {
        startR = r;
        startC = c;
      }
      if (ch == 'G') {
        goalR = r;
        goalC = c;
      }
    }
  }

  if (startR == null || startC == null || goalR == null || goalC == null) {
    return null;
  }

  final best = <String, ({int rotCost, int moveCost})>{};
  final queue = <({int rotCost, int moveCost, int r, int c, int rot})>[
    (rotCost: 0, moveCost: 0, r: startR, c: startC, rot: 0),
  ];
  best['$startR:$startC:0'] = (rotCost: 0, moveCost: 0);

  while (queue.isNotEmpty) {
    queue.sort((a, b) {
      final byRot = a.rotCost.compareTo(b.rotCost);
      if (byRot != 0) return byRot;
      return a.moveCost.compareTo(b.moveCost);
    });

    final current = queue.removeAt(0);
    if (current.r == goalR && current.c == goalC) {
      return (minRotations: current.rotCost, minMoves: current.moveCost);
    }

    final currentKey = '${current.r}:${current.c}:${current.rot}';
    final known = best[currentKey];
    if (known == null ||
        known.rotCost != current.rotCost ||
        known.moveCost != current.moveCost) {
      continue;
    }

    for (final nextRot in <int>[(current.rot + 90) % 360, (current.rot + 270) % 360]) {
      final key = '${current.r}:${current.c}:$nextRot';
      final candidate = (rotCost: current.rotCost + 1, moveCost: current.moveCost);
      final prev = best[key];
      if (prev == null ||
          candidate.rotCost < prev.rotCost ||
          (candidate.rotCost == prev.rotCost && candidate.moveCost < prev.moveCost)) {
        best[key] = candidate;
        queue.add((
          rotCost: candidate.rotCost,
          moveCost: candidate.moveCost,
          r: current.r,
          c: current.c,
          rot: nextRot,
        ));
      }
    }

    for (final (dr, dc) in const <(int, int)>[(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final nr = current.r + dr;
      final nc = current.c + dc;
      if (nr < 0 || nr >= height || nc < 0 || nc >= width) continue;

      final ch = rows[nr][nc];
      if (ch == '#' || ch == ' ') continue;
      final rule = _passable[ch];
      if (rule == null || !rule(current.rot)) continue;

      final key = '$nr:$nc:${current.rot}';
      final candidate = (rotCost: current.rotCost, moveCost: current.moveCost + 1);
      final prev = best[key];
      if (prev == null ||
          candidate.rotCost < prev.rotCost ||
          (candidate.rotCost == prev.rotCost && candidate.moveCost < prev.moveCost)) {
        best[key] = candidate;
        queue.add((
          rotCost: candidate.rotCost,
          moveCost: candidate.moveCost,
          r: nr,
          c: nc,
          rot: current.rot,
        ));
      }
    }
  }

  return null;
}

void main() {
  test('all level JSON assets are valid, solvable, and par-achievable', () async {
    final indexFile = File('assets/levels/index.json');
    expect(indexFile.existsSync(), isTrue, reason: 'Missing assets/levels/index.json');

    final index = jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
    final entries = (index['levels'] as List).cast<String>();

    expect(entries, isNotEmpty, reason: 'Level index must not be empty');
    expect(entries.toSet().length, entries.length,
        reason: 'Level index contains duplicate entries');

    for (final path in entries) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Missing level asset: $path');

      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final id = json['id'] as String;
      final par = json['parRotations'] as int;
      final rows = (json['rows'] as List).cast<String>();

      expect(rows, isNotEmpty, reason: '$id has empty rows');
      final width = rows.first.length;
      expect(rows.every((r) => r.length == width), isTrue,
          reason: '$id has inconsistent row widths');

      var startCount = 0;
      var goalCount = 0;
      for (final row in rows) {
        for (final rune in row.runes) {
          final ch = String.fromCharCode(rune);
          expect('.# SGETWN'.contains(ch), isTrue,
              reason: '$id contains unknown tile "$ch"');
          if (ch == 'S') startCount++;
          if (ch == 'G') goalCount++;
        }
      }

      expect(startCount, 1, reason: '$id must contain exactly one S');
      expect(goalCount, 1, reason: '$id must contain exactly one G');

      final solved = _solve(rows);
      expect(solved, isNotNull, reason: '$id is unsolvable');
      expect(solved!.minRotations <= par, isTrue,
          reason:
              '$id has impossible par: par=$par, minRotations=${solved.minRotations}');
    }
  });
}
