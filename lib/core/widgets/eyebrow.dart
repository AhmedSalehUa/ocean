import 'package:flutter/material.dart';

import '../theme/typography.dart';

/// Mono-spaced overline used everywhere as section labels.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppType.eyebrow.copyWith(color: color),
    );
  }
}
