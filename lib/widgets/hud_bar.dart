import 'package:flutter/material.dart';
import '../utils/vantage_theme.dart';

/// HUD bar showing move count, rotation count, and controls.
class HudBar extends StatelessWidget {
  final int moveCount;
  final int rotationCount;
  final int parRotations;
  final VoidCallback onRotateCW;
  final VoidCallback onRotateCCW;
  final VoidCallback onReset;

  const HudBar({
    super.key,
    required this.moveCount,
    required this.rotationCount,
    required this.parRotations,
    required this.onRotateCW,
    required this.onRotateCCW,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: VantageTheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat('MOVES', moveCount.toString()),
          _stat('ROTATIONS', '$rotationCount / $parRotations'),
          Row(
            children: [
              IconButton(
                onPressed: onRotateCCW,
                icon: const Icon(Icons.rotate_left),
                color: VantageTheme.accent,
                tooltip: 'Rotate counter-clockwise',
              ),
              IconButton(
                onPressed: onRotateCW,
                icon: const Icon(Icons.rotate_right),
                color: VantageTheme.accent,
                tooltip: 'Rotate clockwise',
              ),
              IconButton(
                onPressed: onReset,
                icon: const Icon(Icons.refresh),
                color: Colors.white54,
                tooltip: 'Reset level',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 1.5)),
        Text(value,
            style: const TextStyle(
                color: VantageTheme.accent,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
