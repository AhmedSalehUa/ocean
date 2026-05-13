import 'package:flutter/material.dart';

import '../theme/colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
    this.glow = false,
    this.muted = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final bool glow;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(22);
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? AppColors.lineSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withAlpha(8),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          if (glow)
            BoxShadow(
              color: AppColors.accentSoft,
              spreadRadius: 3,
              blurRadius: 0,
            ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    final wrapped = Opacity(opacity: muted ? 0.7 : 1, child: card);

    if (onTap == null) return wrapped;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        splashColor: AppColors.accentSoft.withAlpha(120),
        highlightColor: AppColors.accentSoft.withAlpha(40),
        child: wrapped,
      ),
    );
  }
}
