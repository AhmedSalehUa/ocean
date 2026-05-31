import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Ocean Ship wordmark + circular ship-and-waves mark.
///
/// Kept the historical class name so existing imports/call sites keep working.
class TrailLogo extends StatelessWidget {
  const TrailLogo({
    super.key,
    this.size = 18,
    this.color = AppColors.navy,
    this.accentColor = AppColors.gold,
    this.showText = true,
  });

  final double size;
  final Color color;
  final Color accentColor;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: size * 1.6,
      height: size * 1.6,
      child: CustomPaint(painter: _OceanShipMark(color, accentColor)),
    );
    if (!showText) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.5),
        Text(
          'Ocean Ship',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: size,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

/// Large branded lockup for the login / splash screen.
///
/// Tries to render `assets/images/ocean_ship_logo.png` first; if the asset
/// isn't bundled yet, falls back to the painted mark + typeset wordmark so
/// the screen stays useful before the PNG is added.
class OceanShipLockup extends StatelessWidget {
  const OceanShipLockup({
    super.key,
    this.markSize = 120,
    this.color = AppColors.navy,
    this.accentColor = AppColors.gold,
    this.subtitle = 'supply & services',
    this.tagline = 'Egyptian ports and Suez Canal',
    this.assetPath = 'assets/images/ocean_ship_logo.png',
  });

  final double markSize;
  final Color color;
  final Color accentColor;
  final String subtitle;
  final String tagline;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: markSize * 2.4,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _PaintedLockup(
          markSize: markSize,
          color: color,
          accentColor: accentColor,
          subtitle: subtitle,
          tagline: tagline),
    );
  }
}

class _PaintedLockup extends StatelessWidget {
  const _PaintedLockup({
    required this.markSize,
    required this.color,
    required this.accentColor,
    required this.subtitle,
    required this.tagline,
  });
  final double markSize;
  final Color color;
  final Color accentColor;
  final String subtitle;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: markSize,
          height: markSize,
          child: CustomPaint(painter: _OceanShipMark(color, accentColor)),
        ),
        const SizedBox(height: 16),
        Text(
          'Ocean Ship',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: markSize * 0.34,
            letterSpacing: -0.8,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w400,
            fontSize: markSize * 0.16,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          tagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w400,
            fontSize: markSize * 0.18,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _OceanShipMark extends CustomPainter {
  _OceanShipMark(this.color, this.accent);
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = s * 0.48;

    final stroke = Paint()
      ..color = color
      ..strokeWidth = s * 0.04
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final goldStroke = Paint()
      ..color = accent
      ..strokeWidth = s * 0.022
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Circle outline.
    canvas.drawCircle(Offset(cx, cy), r, stroke);

    // Ship hull: rounded trapezoid sitting above the waves.
    final hullTopY = cy - s * 0.04;
    final hullBottomY = cy + s * 0.06;
    final hull = Path()
      ..moveTo(cx - s * 0.22, hullTopY)
      ..lineTo(cx + s * 0.22, hullTopY)
      ..lineTo(cx + s * 0.17, hullBottomY)
      ..lineTo(cx - s * 0.17, hullBottomY)
      ..close();
    canvas.drawPath(hull, stroke);

    // Cabin on top of hull.
    final cabinH = s * 0.09;
    final cabin = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - s * 0.10, hullTopY - cabinH, s * 0.20, cabinH),
        Radius.circular(s * 0.02),
      ));
    canvas.drawPath(cabin, stroke);

    // Funnel/stack.
    final stackRect = Rect.fromLTWH(
      cx - s * 0.025,
      hullTopY - cabinH - s * 0.08,
      s * 0.05,
      s * 0.08,
    );
    canvas.drawRect(stackRect, stroke);

    // Two waves under the ship.
    final waveTop = cy + s * 0.14;
    for (var i = 0; i < 2; i++) {
      final y = waveTop + i * s * 0.075;
      final wave = Path()..moveTo(cx - r * 0.95, y);
      final segs = 4;
      for (var k = 0; k < segs; k++) {
        final x1 = cx - r * 0.95 + (2 * k + 1) * (r * 1.9 / (segs * 2));
        final x2 = cx - r * 0.95 + (2 * k + 2) * (r * 1.9 / (segs * 2));
        final dy = (k.isEven ? -1 : 1) * s * 0.035;
        wave.quadraticBezierTo(x1, y + dy, x2, y);
      }
      canvas.drawPath(wave, stroke);
    }

    // Subtle gold echo behind the bottom wave for warmth (matches brand).
    final accentWave = Path()..moveTo(cx - r * 0.6, waveTop + s * 0.075 + s * 0.015);
    accentWave.quadraticBezierTo(
        cx, waveTop + s * 0.075 + s * 0.045, cx + r * 0.6, waveTop + s * 0.075 + s * 0.015);
    canvas.drawPath(accentWave, goldStroke);
  }

  @override
  bool shouldRepaint(covariant _OceanShipMark old) => old.color != color || old.accent != accent;
}
