class MonetizationConfig {
  static const int freeLevelCount = 8;
  static const String fullGameProductId = 'vantage_full_game';

  static bool isInFreeChapter(int levelIndex) => levelIndex < freeLevelCount;
}
