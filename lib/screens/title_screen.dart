import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/routes.dart';
import '../utils/vantage_theme.dart';
import 'level_select_screen.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _go() {
    Navigator.of(
      context,
    ).pushReplacement(fadeRoute<void>(const LevelSelectScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VantageTheme.background,
      body: GestureDetector(
        onTap: _go,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Background diamond grid decoration
            const Positioned.fill(child: _DiamondGrid()),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo diamond
                  _LogoDiamond()
                      .animate()
                      .scale(
                        begin: const Offset(0.4, 0.4),
                        end: const Offset(1, 1),
                        duration: 700.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 28),

                  // Title
                  const Text(
                        'VANTAGE',
                        style: TextStyle(
                          color: VantageTheme.accent,
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 12,
                        ),
                      )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 8),

                  const Text(
                    'PERSPECTIVE · SHIFT · PUZZLE',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate(delay: 450.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 72),

                  // Tap prompt
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final opacity =
                          0.35 +
                          0.65 *
                              Curves.easeInOut.transform(
                                _pulseController.value,
                              );
                      return Opacity(
                        opacity: opacity,
                        child: const Text(
                          'TAP TO PLAY',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            letterSpacing: 5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ).animate(delay: 800.ms).fadeIn(duration: 600.ms),
                ],
              ),
            ),

            // Version / studio tag at bottom
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: const Text(
                'NITROTURTLE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  letterSpacing: 4,
                ),
              ).animate(delay: 1000.ms).fadeIn(duration: 600.ms),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo — a rotating diamond built from the 4 gate colours
// ---------------------------------------------------------------------------

class _LogoDiamond extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    const dotSize = 18.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring dots (direction colours)
          _dot(
            Alignment.topCenter,
            VantageTheme.perspectiveNorthColor,
            dotSize,
          ),
          _dot(
            Alignment.centerRight,
            VantageTheme.perspectiveEastColor,
            dotSize,
          ),
          _dot(
            Alignment.bottomCenter,
            VantageTheme.perspectiveSouthColor,
            dotSize,
          ),
          _dot(
            Alignment.centerLeft,
            VantageTheme.perspectiveWestColor,
            dotSize,
          ),

          // Centre accent dot
          Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: VantageTheme.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: VantageTheme.accent.withAlpha(160),
                      blurRadius: 14,
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.85, end: 1.15, duration: 1200.ms),
        ],
      ),
    );
  }

  Widget _dot(Alignment alignment, Color color, double size) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 8)],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subtle background grid of faint diamonds
// ---------------------------------------------------------------------------

class _DiamondGrid extends StatelessWidget {
  const _DiamondGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DiamondGridPainter());
  }
}

class _DiamondGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VantageTheme.accentDim.withAlpha(28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    const spacing = 52.0;
    const half = spacing / 2;

    for (var col = -1.0; col < (size.width / spacing) + 1; col++) {
      for (var row = -1.0; row < (size.height / spacing) + 1; row++) {
        final cx = col * spacing + (row.toInt().isOdd ? half : 0);
        final cy = row * spacing;
        final path = Path()
          ..moveTo(cx, cy - half)
          ..lineTo(cx + half, cy)
          ..lineTo(cx, cy + half)
          ..lineTo(cx - half, cy)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DiamondGridPainter old) => false;
}
