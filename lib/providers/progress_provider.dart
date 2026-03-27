import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/level_repository.dart';

// ---------------------------------------------------------------------------
// SharedPreferences provider (async, initialised once)
// ---------------------------------------------------------------------------

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) => SharedPreferences.getInstance());

// ---------------------------------------------------------------------------
// Progress provider
// ---------------------------------------------------------------------------

class ProgressNotifier extends AsyncNotifier<Map<String, LevelProgress>> {
  static const _prefKey = 'vantage_progress';

  Map<String, LevelProgress> _defaultProgress(List<Level> levels) {
    return {
      for (final level in levels)
        level.id: LevelProgress(
          levelId: level.id,
          isUnlocked: level.id == levels.first.id,
        ),
    };
  }

  @override
  Future<Map<String, LevelProgress>> build() async {
    final levels = await loadLevels();
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final raw = prefs.getString(_prefKey);

    final defaults = _defaultProgress(levels);

    if (raw == null) {
      return defaults;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final saved = decoded.map(
      (k, v) => MapEntry(k, LevelProgress.fromJson(v as Map<String, dynamic>)),
    );

    // Merge saved progress over defaults so newly added levels (like tutorial)
    // still exist in the map, and ensure the first level is always unlocked.
    final merged = Map<String, LevelProgress>.from(defaults)..addAll(saved);
    final firstId = levels.first.id;
    merged[firstId] = (merged[firstId] ?? LevelProgress(levelId: firstId))
        .copyWith(isUnlocked: true);

    return merged;
  }

  Future<void> recordCompletion(
      String levelId, int moves, int rotations) async {
    final levels = await loadLevels();
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final current = state.valueOrNull ?? {};
    final existing = current[levelId] ??
        LevelProgress(levelId: levelId, isUnlocked: true);

    final updated = existing.copyWith(
      isCompleted: true,
      isUnlocked: true,
      bestMoves:
          existing.bestMoves == null ? moves : existing.bestMoves! < moves ? existing.bestMoves : moves,
      bestRotations: existing.bestRotations == null
          ? rotations
          : existing.bestRotations! < rotations
              ? existing.bestRotations
              : rotations,
    );

    // Unlock the next level if it exists.
    final levelIds = levels.map((l) => l.id).toList();
    final idx = levelIds.indexOf(levelId);
    final next =
        idx >= 0 && idx + 1 < levelIds.length ? levelIds[idx + 1] : null;

    final newMap = Map<String, LevelProgress>.from(current)
      ..[levelId] = updated;
    if (next != null) {
      newMap[next] = (newMap[next] ?? LevelProgress(levelId: next))
          .copyWith(isUnlocked: true);
    }

    await prefs.setString(
      _prefKey,
      jsonEncode(newMap.map((k, v) => MapEntry(k, v.toJson()))),
    );
    state = AsyncData(newMap);
  }

  Future<void> resetProgress() async {
    final levels = await loadLevels();
    final defaults = _defaultProgress(levels);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.remove(_prefKey);
    state = AsyncData(defaults);
  }
}

final progressProvider =
    AsyncNotifierProvider<ProgressNotifier, Map<String, LevelProgress>>(
  ProgressNotifier.new,
);
