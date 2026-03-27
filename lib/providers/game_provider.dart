import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../utils/audio_service.dart';
import '../utils/game_engine.dart';
import '../utils/level_repository.dart';
import 'progress_provider.dart';
import 'settings_provider.dart';

// ---------------------------------------------------------------------------
// Active game notifier
// ---------------------------------------------------------------------------

class GameNotifier extends Notifier<GameState?> {
  bool get _hapticsEnabled =>
      ref.read(settingsProvider).valueOrNull?.hapticsEnabled ?? true;

  @override
  GameState? build() => null;

  void loadLevel(Level level) {
    state = GameState.initial(level);
  }

  bool tryMove(Direction direction) {
    final current = state;
    if (current == null) return false;
    final next = GameEngine.move(current, direction);
    if (next == current) {
      unawaited(AudioService.playBlocked());
      if (_hapticsEnabled) {
        unawaited(HapticFeedback.mediumImpact());
      }
      return false; // blocked move
    }

    state = next;
    unawaited(AudioService.playMove());
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }

    if (next.isSolved) {
      unawaited(AudioService.playSolved());
      if (_hapticsEnabled) {
        unawaited(HapticFeedback.heavyImpact());
      }
      ref.read(progressProvider.notifier).recordCompletion(
            next.level.id,
            next.moveCount,
            next.rotationCount,
          );
    }
    return true;
  }

  void move(Direction direction) {
    tryMove(direction);
  }

  void rotateCW() {
    final current = state;
    if (current == null) return;
    state = GameEngine.rotateCW(current);
    unawaited(AudioService.playRotate());
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void rotateCCW() {
    final current = state;
    if (current == null) return;
    state = GameEngine.rotateCCW(current);
    unawaited(AudioService.playRotate());
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void reset() {
    final current = state;
    if (current == null) return;
    state = GameEngine.reset(current);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState?>(
  GameNotifier.new,
);

// ---------------------------------------------------------------------------
// Convenience: ordered list of all levels
// ---------------------------------------------------------------------------

final levelsProvider = FutureProvider<List<Level>>((ref) => loadLevels());
