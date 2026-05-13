import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';

enum ChipTone { neutral, green, warn, danger, ghost, dark, soft }

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.tone = ChipTone.neutral,
    this.leading,
  });

  final String label;
  final ChipTone tone;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(999),
        border: s.border == null ? null : Border.all(color: s.border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[IconTheme(data: IconThemeData(color: s.fg, size: 11), child: leading!), const SizedBox(width: 6)],
          Text(
            label.toUpperCase(),
            style: AppType.mono11.copyWith(
              color: s.fg,
              letterSpacing: 0.44,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  _ChipColors _styleFor(ChipTone t) {
    switch (t) {
      case ChipTone.neutral:
        return _ChipColors(bg: AppColors.bgDeep, fg: AppColors.ink2);
      case ChipTone.green:
        return _ChipColors(bg: AppColors.accentSoft, fg: AppColors.accentInk);
      case ChipTone.warn:
        return _ChipColors(bg: AppColors.warnSoft, fg: AppColors.warnInk);
      case ChipTone.danger:
        return _ChipColors(bg: AppColors.dangerSoft, fg: AppColors.danger);
      case ChipTone.ghost:
        return _ChipColors(bg: Colors.transparent, fg: AppColors.muted, border: AppColors.line);
      case ChipTone.dark:
        return _ChipColors(bg: AppColors.ink, fg: Colors.white);
      case ChipTone.soft:
        return _ChipColors(bg: AppColors.surface, fg: AppColors.ink2, border: AppColors.line);
    }
  }
}

class _ChipColors {
  final Color bg;
  final Color fg;
  final Color? border;
  const _ChipColors({required this.bg, required this.fg, this.border});
}
