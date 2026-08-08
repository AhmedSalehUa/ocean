import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import '../../l10n/app_l10n.dart';
import 'app_button.dart';

/// Where a proof file should come from.
enum CaptureSource { camera, document }

/// Bottom sheet letting the user capture a photo or pick a document.
/// Returns null if dismissed. Set [allowDocument] false to offer camera only.
Future<CaptureSource?> showCaptureSourceSheet(
  BuildContext context, {
  bool allowDocument = true,
}) {
  final t = AppL10n.of(context);
  return showModalBottomSheet<CaptureSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(t.addFileTitle, style: AppType.h3),
            const SizedBox(height: 16),
            AppButton(
              label: t.takePhoto,
              leading: const Icon(Icons.photo_camera_outlined, size: 18),
              onPressed: () => Navigator.pop(sheetContext, CaptureSource.camera),
            ),
            if (allowDocument) ...[
              const SizedBox(height: 10),
              AppButton(
                label: t.chooseDocument,
                variant: AppBtnVariant.ghost,
                leading: const Icon(Icons.folder_open_outlined, size: 18),
                onPressed: () => Navigator.pop(sheetContext, CaptureSource.document),
              ),
            ],
          ],
        ),
      );
    },
  );
}
