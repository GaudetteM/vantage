import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/vantage_theme.dart';

/// Renders 1–3 filled stars for [stars] out of 3.
/// When [animate] is true, each star pops in with a staggered scale effect.
class StarRating extends StatelessWidget {
  final int stars; // 0–3
  final double size;
  final bool animate;

  const StarRating({
    super.key,
    required this.stars,
    this.size = 28,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < stars;
        final icon = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: filled ? VantageTheme.goalColor : Colors.white24,
          size: size,
        );

        if (!animate || !filled) return icon;

        return icon
            .animate(delay: (150 * i).ms)
            .scale(
              begin: const Offset(0.3, 0.3),
              end: const Offset(1, 1),
              duration: 380.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 120.ms);
      }),
    );
  }
}
