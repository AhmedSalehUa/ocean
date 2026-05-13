import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';

/// Striped/painted placeholder used wherever a real photo isn't available yet.
/// Matches the CapturedPhoto component from the design prototype.
class CapturedPhoto extends StatelessWidget {
  const CapturedPhoto({
    super.key,
    this.tone = 0,
    this.label,
    this.gps,
    this.time,
    this.height,
    this.radius = 14,
    this.dim = false,
  });

  final int tone;
  final String? label;
  final String? gps;
  final String? time;
  final double? height;
  final double radius;
  final bool dim;

  static const _palette = [
    [Color(0xFFB4A98E), Color(0xFF5E5440)],
    [Color(0xFF9CB0A6), Color(0xFF3F5249)],
    [Color(0xFFA8A39B), Color(0xFF4A463F)],
    [Color(0xFF8E9CB0), Color(0xFF3D4757)],
    [Color(0xFFC2B098), Color(0xFF6B5A44)],
  ];

  @override
  Widget build(BuildContext context) {
    final pair = _palette[tone.abs() % _palette.length];

    final stack = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: pair,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.7),
                  radius: 0.6,
                  colors: [Colors.white.withAlpha(38), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _HorizonPainter()),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(64)],
                  stops: const [0.62, 1.0],
                ),
              ),
            ),
          ),
          if (dim) Container(color: Colors.black.withAlpha(89)),
          // labels
          if (label != null || time != null)
            Positioned(
              left: 10, right: 10, top: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (label != null) _tag(label!),
                  if (time != null) _tag(time!),
                ],
              ),
            ),
          if (gps != null)
            Positioned(
              left: 10, bottom: 10,
              child: _tag('GPS  $gps'),
            ),
        ],
      ),
    );

    return height == null ? stack : SizedBox(height: height, child: stack);
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(102),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(text, style: AppType.mono10.copyWith(color: Colors.white, fontSize: 10)),
      );
}

class _HorizonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = const Color(0xFF14160F).withAlpha(102);
    final path = Path()
      ..moveTo(w * 0.12, h * 0.78)
      ..lineTo(w * 0.32, h * 0.62)
      ..lineTo(w * 0.5, h * 0.7)
      ..lineTo(w * 0.7, h * 0.55)
      ..lineTo(w * 0.88, h * 0.65)
      ..lineTo(w, h * 0.7)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..lineTo(0, h * 0.82)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
