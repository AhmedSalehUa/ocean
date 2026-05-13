import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';

enum AppBtnVariant { primary, ghost, soft, danger, dark }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppBtnVariant.primary,
    this.full = true,
    this.leading,
    this.trailing,
    this.height = 56,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppBtnVariant variant;
  final bool full;
  final Widget? leading;
  final Widget? trailing;
  final double height;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final colors = _styleFor(variant, disabled);

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: loading
          ? SizedBox(
              key: const ValueKey('loader'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.fg,
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[IconTheme(data: IconThemeData(color: colors.fg, size: 18), child: leading!), const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    label,
                    style: AppType.button.copyWith(color: colors.fg),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), IconTheme(data: IconThemeData(color: colors.fg, size: 18), child: trailing!)],
              ],
            ),
    );

    final btn = Material(
      color: colors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: colors.border == null
            ? BorderSide.none
            : BorderSide(color: colors.border!, width: 1),
      ),
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: child),
          ),
        ),
      ),
    );

    if (full) return SizedBox(width: double.infinity, child: btn);
    return btn;
  }

  _BtnColors _styleFor(AppBtnVariant v, bool disabled) {
    switch (v) {
      case AppBtnVariant.primary:
        return _BtnColors(
          bg: disabled ? AppColors.accentInk.withAlpha(102) : AppColors.accentInk,
          fg: Colors.white,
        );
      case AppBtnVariant.dark:
        return _BtnColors(
          bg: disabled ? AppColors.ink.withAlpha(102) : AppColors.ink,
          fg: Colors.white,
        );
      case AppBtnVariant.soft:
        return _BtnColors(
          bg: AppColors.accentSoft,
          fg: AppColors.accentInk,
        );
      case AppBtnVariant.ghost:
        return _BtnColors(
          bg: Colors.transparent,
          fg: AppColors.ink2,
          border: AppColors.line,
        );
      case AppBtnVariant.danger:
        return _BtnColors(
          bg: AppColors.surface,
          fg: AppColors.danger,
          border: AppColors.line,
        );
    }
  }
}

class _BtnColors {
  final Color bg;
  final Color fg;
  final Color? border;
  const _BtnColors({required this.bg, required this.fg, this.border});
}

class RoundIconBtn extends StatelessWidget {
  const RoundIconBtn({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 36,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: AppColors.surface.withAlpha(180),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: AppColors.line),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: 16, color: AppColors.ink2),
          ),
        ),
      ),
    );
  }
}
