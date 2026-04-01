import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/monetization_provider.dart';
import '../utils/monetization_config.dart';
import '../utils/routes.dart';
import '../utils/vantage_theme.dart';
import 'game_screen.dart';

class UpgradeScreen extends ConsumerWidget {
  final Level? targetLevel;

  const UpgradeScreen({super.key, this.targetLevel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monetizationAsync = ref.watch(monetizationProvider);

    return Scaffold(
      backgroundColor: VantageTheme.background,
      appBar: AppBar(
        backgroundColor: VantageTheme.surface,
        title: const Text('FULL GAME'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: monetizationAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _UpgradeCard(
                  child: Text(
                    'Failed to load upgrade options: $error',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
                data: (state) {
                  final isUnlocked = state.hasFullGame;
                  final ctaLabel = isUnlocked
                      ? targetLevel == null
                            ? 'BACK TO LEVELS'
                            : 'PLAY ${targetLevel!.name.toUpperCase()}'
                      : state.purchasePending
                      ? 'PROCESSING...'
                      : state.priceLabel.toUpperCase();

                  return _UpgradeCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KEEP THE PERSPECTIVE SHIFT GOING',
                          style: TextStyle(
                            color: VantageTheme.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isUnlocked
                              ? 'Full game unlocked.'
                              : 'The first ${MonetizationConfig.freeLevelCount} levels are free. Unlock the rest of the campaign with one purchase.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          targetLevel == null
                              ? 'You have reached the end of the free chapter.'
                              : 'Level ${targetLevel!.name} is part of the paid chapter.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _FeatureList(),
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 18),
                          Text(
                            state.errorMessage!,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: state.purchasePending
                                ? null
                                : isUnlocked
                                ? () {
                                    if (targetLevel != null) {
                                      Navigator.of(context).pushReplacement(
                                        fadeSlideRoute<void>(
                                          GameScreen(level: targetLevel!),
                                        ),
                                      );
                                    } else {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                : state.productDetails == null
                                ? null
                                : () => ref
                                      .read(monetizationProvider.notifier)
                                      .buyFullGame(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(ctaLabel),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: state.purchasePending
                                ? null
                                : () => ref
                                      .read(monetizationProvider.notifier)
                                      .restorePurchases(),
                            child: const Text('RESTORE PURCHASES'),
                          ),
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => ref
                                  .read(monetizationProvider.notifier)
                                  .grantDebugUnlock(),
                              child: const Text('DEBUG: GRANT FULL GAME'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  final Widget child;

  const _UpgradeCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: VantageTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    const items = [
      'One-time unlock. No forced ads.',
      'All remaining campaign levels.',
      'Future level packs can build on the same upgrade path.',
    ];

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.diamond_outlined,
                    size: 16,
                    color: VantageTheme.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
