import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/vantage_theme.dart';

/// Renders a single grid cell.
class CellWidget extends StatelessWidget {
  final Cell cell;
  final bool isPlayer;
  final int rotationDeg;

  const CellWidget({
    super.key,
    required this.cell,
    required this.rotationDeg,
    this.isPlayer = false,
  });

  @override
  Widget build(BuildContext context) {
    final isWall = cell.type == CellType.wall;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: _cellColor(),
        // Walls have sharp corners to feel solid/blocked.
        // Everything else is slightly rounded.
        borderRadius: isWall ? BorderRadius.zero : BorderRadius.circular(4),
        border: _border(),
      ),
      child: _icon(),
    );
  }

  Color _cellColor() {
    if (isPlayer) return VantageTheme.playerColor.withAlpha(60);
    return switch (cell.type) {
      CellType.wall => VantageTheme.wallColor,
      CellType.empty => VantageTheme.emptyColor,
      CellType.floor || CellType.start => VantageTheme.floorColor,
      CellType.goal => VantageTheme.goalColor.withAlpha(40),
      CellType.perspectiveNorth ||
      CellType.perspectiveEast ||
      CellType.perspectiveSouth ||
      CellType.perspectiveWest =>
        cell.type.isWalkable(rotationDeg)
            ? _perspectiveDirectionColor.withAlpha(70)
            : VantageTheme.perspectiveHiddenColor,
    };
  }

  Border? _border() {
    if (cell.type == CellType.wall) {
      // Subtle top/left highlight makes wall look raised/solid.
      return Border(
        top: BorderSide(color: VantageTheme.wallBorderColor, width: 1.5),
        left: BorderSide(color: VantageTheme.wallBorderColor, width: 1.5),
        bottom: const BorderSide(color: Colors.black26, width: 1),
        right: const BorderSide(color: Colors.black26, width: 1),
      );
    }
    if (cell.type == CellType.goal) {
      return Border.all(color: VantageTheme.goalColor, width: 1.5);
    }
    if (_isPerspective) {
      final active = cell.type.isWalkable(rotationDeg);
      return Border.all(
        color: active
            ? _perspectiveDirectionColor
            : _perspectiveDirectionColor.withAlpha(140),
        width: active ? 2 : 1.5,
      );
    }
    return null;
  }

  Color get _perspectiveDirectionColor => switch (cell.type) {
        CellType.perspectiveNorth => VantageTheme.perspectiveNorthColor,
        CellType.perspectiveEast => VantageTheme.perspectiveEastColor,
        CellType.perspectiveSouth => VantageTheme.perspectiveSouthColor,
        CellType.perspectiveWest => VantageTheme.perspectiveWestColor,
        _ => VantageTheme.perspectiveActiveColor,
      };

  bool get _isPerspective => switch (cell.type) {
        CellType.perspectiveNorth ||
        CellType.perspectiveEast ||
        CellType.perspectiveSouth ||
        CellType.perspectiveWest =>
          true,
        _ => false,
      };

  Widget? _icon() {
    if (isPlayer) {
      return const Center(
        child: Icon(Icons.circle, color: VantageTheme.playerColor, size: 14),
      );
    }
    if (cell.type == CellType.goal) {
      return const Center(
        child: Icon(Icons.star, color: VantageTheme.goalColor, size: 14),
      );
    }
    return null;
  }
}
