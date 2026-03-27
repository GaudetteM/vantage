/// Returns stars earned (1–3) based on rotations vs par.
/// 3 = at or under par, 2 = one over par, 1 = completed.
int starsEarned(int bestRotations, int parRotations) {
  if (bestRotations <= parRotations) return 3;
  if (bestRotations <= parRotations + 1) return 2;
  return 1;
}

/// Tracks per-level player progress persisted to SharedPreferences.
class LevelProgress {
  final String levelId;
  final bool isUnlocked;
  final bool isCompleted;
  final int? bestMoves;
  final int? bestRotations;

  const LevelProgress({
    required this.levelId,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.bestMoves,
    this.bestRotations,
  });

  LevelProgress copyWith({
    bool? isUnlocked,
    bool? isCompleted,
    int? bestMoves,
    int? bestRotations,
  }) =>
      LevelProgress(
        levelId: levelId,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        isCompleted: isCompleted ?? this.isCompleted,
        bestMoves: bestMoves ?? this.bestMoves,
        bestRotations: bestRotations ?? this.bestRotations,
      );

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'isUnlocked': isUnlocked,
        'isCompleted': isCompleted,
        'bestMoves': bestMoves,
        'bestRotations': bestRotations,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
        levelId: json['levelId'] as String,
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        isCompleted: json['isCompleted'] as bool? ?? false,
        bestMoves: json['bestMoves'] as int?,
        bestRotations: json['bestRotations'] as int?,
      );
}
