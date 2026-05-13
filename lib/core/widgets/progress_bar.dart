import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Two-segment progress bar (delivered green + missing red) used by the
/// item loop and dashboard.
class SplitProgressBar extends StatelessWidget {
  const SplitProgressBar({
    super.key,
    required this.deliveredPct,
    required this.missingPct,
    this.height = 6,
    this.background = AppColors.bgDeep,
  });

  final double deliveredPct;
  final double missingPct;
  final double height;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: background,
        child: Row(
          children: [
            if (deliveredPct > 0)
              Flexible(
                flex: (deliveredPct * 1000).round(),
                child: Container(color: AppColors.accent),
              ),
            if (missingPct > 0)
              Flexible(
                flex: (missingPct * 1000).round(),
                child: Container(color: AppColors.danger),
              ),
            Flexible(
              flex: ((1 - deliveredPct - missingPct).clamp(0, 1) * 1000).round(),
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleProgressBar extends StatelessWidget {
  const SimpleProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.accentInk,
    this.height = 5,
  });
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: AppColors.bgDeep,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(color: color),
          ),
        ),
      ),
    );
  }
}
