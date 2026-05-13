import 'package:flutter/material.dart';

import '../theme/colors.dart';

class TrailLogo extends StatelessWidget {
  const TrailLogo({super.key, this.size = 18, this.color = AppColors.ink});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size * 1.5, size * 0.78),
          painter: _TrailMark(color),
        ),
        const SizedBox(width: 8),
        Text(
          'Trail',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: size,
            letterSpacing: -0.36,
          ),
        ),
      ],
    );
  }
}

class _TrailMark extends CustomPainter {
  _TrailMark(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 27;
    final scaleY = size.height / 14;
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(3 * scaleX, 11 * scaleY), 2.2 * scaleX, paint);
    canvas.drawCircle(Offset(11 * scaleX, 7 * scaleY), 2.2 * scaleX, paint..color = color.withAlpha(179));
    canvas.drawCircle(Offset(19 * scaleX, 4 * scaleY), 2.2 * scaleX, paint..color = color.withAlpha(115));

    final stroke = Paint()
      ..color = color.withAlpha(102)
      ..strokeWidth = 0.8 * scaleX
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(3 * scaleX, 11 * scaleY)
      ..lineTo(11 * scaleX, 7 * scaleY)
      ..lineTo(19 * scaleX, 4 * scaleY);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _TrailMark old) => old.color != color;
}
