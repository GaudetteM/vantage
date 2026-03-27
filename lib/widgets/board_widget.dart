import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import 'cell_widget.dart';

/// The animated grid board. Rotates visually when [rotationDeg] changes.
class BoardWidget extends StatelessWidget {
  final GameState gameState;
  /// Pixel size for each cell.
  final double cellSize;

  const BoardWidget({
    super.key,
    required this.gameState,
    this.cellSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final level = gameState.level;
    return AnimatedRotation(
      turns: gameState.rotationDeg / 360.0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      child: _buildGrid(level),
    );
  }

  Widget _buildGrid(Level level) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(level.gridRows, (r) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(level.gridCols, (c) {
            final pos = Position(r, c);
            final cell = level.cellAt(pos);
            final isPlayer = pos == gameState.playerPos;
            return SizedBox(
              width: cellSize,
              height: cellSize,
              child: CellWidget(
                cell: cell,
                rotationDeg: gameState.rotationDeg,
                isPlayer: isPlayer,
              ),
            );
          }),
        );
      }),
    )
        .animate(key: ValueKey(gameState.rotationDeg))
        .fadeIn(duration: 150.ms);
  }
}
