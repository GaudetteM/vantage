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

  @override
  Future<Map<String, LevelProgress>> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final raw = prefs.getString(_prefKey);
    if (raw == null) {
      // First run: unlock level 1 only.
      return {
        for (final level in allLevels)
          level.id: LevelProgress(
            levelId: level.id,
            isUnlocked: level.id == allLevels.first.id,
          ),
      };
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (k, v) => MapEntry(k, LevelProgress.fromJson(v as Map<String, dynamic>)),
    );
  }

  Future<void> recordCompletion(
      String levelId, int moves, int rotations) async {
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
    final levelIds = allLevels.map((l) => l.id).toList();
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
}

final progressProvider =
    AsyncNotifierProvider<ProgressNotifier, Map<String, LevelProgress>>(
  ProgressNotifier.new,
);
