import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';

class TrailTopBar extends StatelessWidget implements PreferredSizeWidget {
  const TrailTopBar({
    super.key,
    this.title,
    this.leading,
    this.trailing,
    this.subtitle,
  });

  final String? title;
  final Widget? leading;
  final Widget? trailing;
  final Widget? subtitle;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 96 : 124);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg.withAlpha(217),
            border: const Border(bottom: BorderSide(color: AppColors.lineSoft)),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 4,
            left: 16,
            right: 16,
            bottom: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(width: 40, child: leading ?? const SizedBox.shrink()),
                  Expanded(
                    child: Center(
                      child: title != null
                          ? Text(
                              title!,
                              style: AppType.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  SizedBox(width: 40, child: Align(alignment: Alignment.centerRight, child: trailing)),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                subtitle!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
