import 'package:flutter/material.dart';
import '../utils/vantage_theme.dart';

/// HUD bar showing move count, rotation count, and controls.
class HudBar extends StatelessWidget {
  final int moveCount;
  final int rotationCount;
  final int parRotations;
  final int currentRotationDeg;
  final VoidCallback onRotateCW;
  final VoidCallback onRotateCCW;
  final VoidCallback onReset;

  const HudBar({
    super.key,
    required this.moveCount,
    required this.rotationCount,
    required this.parRotations,
    required this.currentRotationDeg,
    required this.onRotateCW,
    required this.onRotateCCW,
    required this.onReset,
  });

  int get _normalizedRotation {
    final normalized = ((currentRotationDeg % 360) + 360) % 360;
    return (normalized ~/ 90) % 4;
  }

  Color _directionColor(int directionIndex) {
    return switch (directionIndex) {
      0 => VantageTheme.perspectiveNorthColor,
      1 => VantageTheme.perspectiveEastColor,
      2 => VantageTheme.perspectiveSouthColor,
      _ => VantageTheme.perspectiveWestColor,
    };
  }

  Color get _activeGateColor {
    // Keep this in sync with CellTypeX.isWalkable rotation mapping:
    // 0->North, 90->East, 180->South, 270->West.
    return _directionColor(_normalizedRotation);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: VantageTheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat('MOVES', moveCount.toString()),
          _rotationStat(),
          Row(
            children: [
              IconButton(
                onPressed: onRotateCCW,
                icon: const Icon(Icons.rotate_left),
                color: VantageTheme.accent,
                tooltip: 'Rotate counter-clockwise',
              ),
              _RotationDiamondIndicator(
                // Rotate the color ring opposite board rotation so the color
                // arriving at visual top matches the active gate direction.
                turns: -currentRotationDeg / 360,
                activeColor: _activeGateColor,
                directionColor: _directionColor,
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

  Widget _rotationStat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'ROTATIONS',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$rotationCount / $parRotations',
              style: const TextStyle(
                color: VantageTheme.accent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
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

class _RotationDiamondIndicator extends StatelessWidget {
  final double turns;
  final Color activeColor;
  final Color Function(int directionIndex) directionColor;

  const _RotationDiamondIndicator({
    required this.turns,
    required this.activeColor,
    required this.directionColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedRotation(
            turns: turns,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _dot(alignment: Alignment.topCenter, color: directionColor(0), size: 7),
                  _dot(alignment: Alignment.centerRight, color: directionColor(1), size: 7),
                  _dot(alignment: Alignment.bottomCenter, color: directionColor(2), size: 7),
                  _dot(alignment: Alignment.centerLeft, color: directionColor(3), size: 7),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: activeColor.withAlpha(120), blurRadius: 6),
                ],
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot({
    required Alignment alignment,
    required Color color,
    required double size,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12, width: 0.6),
        ),
      ),
    );
  }
}
