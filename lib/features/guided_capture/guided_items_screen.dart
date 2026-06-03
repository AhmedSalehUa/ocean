import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/enums.dart';
import '../../data/models/vendor_po_item.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../../services/camera_service.dart';
import '../../services/location_service.dart';
import '../vendor_detail/vendor_detail_provider.dart';

/// Guided per-item capture: live camera + banner with the next pending item.
/// Confirming a photo enqueues the upload and immediately advances to the
/// next item so the user can keep snapping without waiting.
class GuidedItemsScreen extends StatefulWidget {
  const GuidedItemsScreen({super.key, required this.vendorId});
  final String vendorId;
  @override
  State<GuidedItemsScreen> createState() => _GuidedItemsScreenState();
}

class _GuidedItemsScreenState extends State<GuidedItemsScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _initializing = true;
  String? _cameraError;

  GpsFix? _fix;
  bool _gpsBusy = true;
  String? _gpsError;

  File? _pendingPhoto;
  String? _pendingForItemId;

  // When the user manually picks an item from the picker, it overrides the
  // auto-loop target until that item is captured/resolved. Cleared afterward
  // so the loop resumes from the next pending item.
  String? _manualItemId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<VendorDetailProvider>();
      if (p.vendor?.id != widget.vendorId) {
        await p.load(widget.vendorId);
      }
      _bootstrapCamera();
      _acquireGps();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _camera;
    if (state == AppLifecycleState.inactive) {
      c?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _bootstrapCamera();
    }
  }

  Future<void> _bootstrapCamera() async {
    setState(() {
      _initializing = true;
      _cameraError = null;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _cameraError = 'No camera available';
        });
        return;
      }
      final rearIndex = _cameras
          .indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      _cameraIndex = rearIndex >= 0 ? rearIndex : 0;
      await _initController(_cameras[_cameraIndex]);
    } catch (e, st) {
      AppLog.error('GuidedItemsScreen._bootstrapCamera', e, st);
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraError = e.toString();
      });
    }
  }

  Future<void> _initController(CameraDescription desc) async {
    final controller = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      final old = _camera;
      setState(() {
        _camera = controller;
        _initializing = false;
      });
      await old?.dispose();
    } catch (e, st) {
      AppLog.error('GuidedItemsScreen._initController', e, st);
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraError = e.toString();
      });
    }
  }

  Future<void> _flip() async {
    if (_cameras.length < 2) return;
    setState(() => _initializing = true);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _initController(_cameras[_cameraIndex]);
  }

  Future<void> _acquireGps() async {
    setState(() {
      _gpsBusy = true;
      _gpsError = null;
    });
    try {
      final fix = await context.read<LocationService>().currentFix();
      if (!mounted) return;
      setState(() {
        _fix = fix;
        _gpsBusy = false;
        if (fix == null) _gpsError = AppL10n.of(context).gpsBlocked;
      });
    } catch (e, st) {
      AppLog.error('GuidedItemsScreen._acquireGps', e, st);
      if (!mounted) return;
      setState(() {
        _gpsBusy = false;
        _gpsError = e.toString();
      });
    }
  }

  /// Returns the next item that still needs a photo for the *current* step.
  /// Each item-photo step re-asks for every item independently of the item's
  /// overall delivered/missing status — except items already marked missing,
  /// which are skipped for good.
  VendorPoItem? _nextItem(VendorDetailProvider p) {
    final v = p.vendor;
    final step = v?.currentStep;
    if (v == null || step == null) return null;
    final done = p.uploadedItemsForStep(step.id);
    for (final i in v.items) {
      if (i.status == ItemStatus.missing) continue;
      if (done.contains(i.id)) continue;
      return i;
    }
    return null;
  }

  /// The item the camera is currently aimed at: a manually-picked item if the
  /// user chose one, otherwise the next pending item from the auto-loop.
  VendorPoItem? _targetItem(VendorDetailProvider p) {
    final v = p.vendor;
    if (v == null) return null;
    if (_manualItemId != null) {
      for (final i in v.items) {
        if (i.id == _manualItemId && i.status != ItemStatus.missing) return i;
      }
    }
    return _nextItem(p);
  }

  Future<void> _pickItem() async {
    final p = context.read<VendorDetailProvider>();
    final v = p.vendor;
    final step = v?.currentStep;
    if (v == null || step == null) return;
    final done = p.uploadedItemsForStep(step.id);
    final selectable =
        v.items.where((i) => i.status != ItemStatus.missing).toList();

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _ItemPickerSheet(
        items: selectable,
        doneIds: done,
        activeId: _targetItem(p)?.id,
        t: AppL10n.of(context),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _manualItemId = picked;
      _pendingPhoto = null;
      _pendingForItemId = null;
    });
  }

  Future<void> _shutter(VendorPoItem target) async {
    final c = _camera;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return;
    if (_fix == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).shutterLocked)),
      );
      return;
    }
    try {
      final shot = await c.takePicture();
      if (!mounted) return;
      setState(() {
        _pendingPhoto = File(shot.path);
        _pendingForItemId = target.id;
      });
    } catch (e, st) {
      AppLog.error('GuidedItemsScreen._shutter', e, st);
    }
  }

  /// Pick a photo from the device gallery instead of taking one. Feeds the
  /// same confirm-then-upload flow as the live shutter.
  Future<void> _pickFromGallery(VendorPoItem target) async {
    if (_fix == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).shutterLocked)),
      );
      return;
    }
    try {
      final file = await context.read<CameraService>().pickFromGallery();
      if (!mounted || file == null) return;
      setState(() {
        _pendingPhoto = file;
        _pendingForItemId = target.id;
      });
    } catch (e, st) {
      AppLog.error('GuidedItemsScreen._pickFromGallery', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _retake() => setState(() {
        _pendingPhoto = null;
        _pendingForItemId = null;
      });

  Future<void> _markMissing(VendorPoItem item) async {
    final t = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(t.markMissingTitle),
        content: Text(t.markMissingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(t.confirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final p = context.read<VendorDetailProvider>();
    final success = await p.markItemMissing(item.id);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(p.error ?? 'Failed to mark missing')),
      );
      return;
    }
    _afterResolution(item);
  }

  Future<void> _markRejected(VendorPoItem item) async {
    final t = AppL10n.of(context);
    final p = context.read<VendorDetailProvider>();
    final step = p.vendor?.currentStep;
    if (step == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(t.markRejectedTitle),
        content: Text(t.markRejectedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(t.confirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final success = await p.markItemRejected(itemId: item.id, stepId: step.id);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(p.error ?? 'Failed to reject')),
      );
      return;
    }
    _afterResolution(item);
  }

  /// After missing/rejected, advance to the next item or to step-done.
  void _afterResolution(VendorPoItem item) {
    final p = context.read<VendorDetailProvider>();
    final v = p.vendor;
    final step = v?.currentStep;
    // Resolving the manually-picked item hands control back to the loop.
    if (_manualItemId == item.id) {
      setState(() => _manualItemId = null);
    }
    if (v == null || step == null) return;
    if (_nextItem(p) == null) {
      context.replace(Routes.stepDonePath(v.id, step.id));
    }
  }

  void _confirm() {
    final p = context.read<VendorDetailProvider>();
    final step = p.vendor?.currentStep;
    final file = _pendingPhoto;
    final itemId = _pendingForItemId;
    if (file == null || itemId == null || step == null) return;
    p.queueItemPhoto(
      itemId: itemId,
      stepId: step.id,
      file: file,
      lat: _fix?.lat,
      lng: _fix?.lng,
      accuracyMeters: _fix?.accuracyMeters,
    );
    setState(() {
      _pendingPhoto = null;
      _pendingForItemId = null;
      // The manual pick has been captured — resume the auto-loop.
      if (_manualItemId == itemId) _manualItemId = null;
    });
    // queueItemPhoto immediately marks the item DELIVERED locally, so if
    // there are no more pending items this was the last one — move on to
    // the step-done screen.
    final remaining = _nextItem(p);
    if (remaining == null) {
      final v = p.vendor;
      if (v != null) {
        context.replace(Routes.stepDonePath(v.id, step.id));
      }
    }
  }

  void _finishOut() {
    final p = context.read<VendorDetailProvider>();
    final v = p.vendor;
    final step = v?.currentStep;
    if (v == null || step == null) {
      context.pop();
      return;
    }
    if (_nextItem(p) == null) {
      context.replace(Routes.stepDonePath(v.id, step.id));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final p = context.watch<VendorDetailProvider>();
    final v = p.vendor;
    final step = v?.currentStep;
    final items = v?.items ?? const [];
    // Items that still need a photo this step (everything except missing).
    final stepEligible =
        items.where((i) => i.status != ItemStatus.missing).toList();
    final total = stepEligible.length;
    final done = step == null ? 0 : p.uploadedItemsForStep(step.id).length;
    final target = _targetItem(p);
    final hasPending = _pendingPhoto != null && _pendingForItemId != null;
    final hasSelectableItems =
        items.any((i) => i.status != ItemStatus.missing);
    // The "Reject" option is only available on the last workflow step that
    // requires item photos. All other item-photo steps offer capture + missing.
    final itemSteps = (v?.steps ?? const [])
        .where((s) => s.requiresItemPhoto)
        .toList();
    final canReject = step != null &&
        itemSteps.isNotEmpty &&
        itemSteps.last.id == step.id;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              t: t,
              target: target,
              index: done + 1,
              total: total,
              onClose: () => context.pop(),
              onPickItem: hasSelectableItems ? _pickItem : null,
            ),
            const SizedBox(height: 8),
            _GpsPill(
              busy: _gpsBusy,
              fix: _fix,
              error: _gpsError,
              onRetry: _acquireGps,
              t: t,
            ),
            const SizedBox(height: 10),
            _UploadBadge(
              pending: p.pendingUploadCount,
              failed: p.failedUploadCount,
              onRetry: p.failedUploadCount > 0 ? p.retryFailedUploads : null,
              t: t,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _Viewfinder(
                    initializing: _initializing,
                    error: _cameraError,
                    camera: _camera,
                    photo: _pendingPhoto,
                    target: target,
                    allDone: target == null,
                    t: t,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (target == null && !hasPending)
              _AllDoneBar(t: t, onFinalize: _finishOut)
            else if (hasPending)
              _ConfirmBar(t: t, busy: false, onRetake: _retake, onConfirm: _confirm)
            else
              _CaptureBar(
                t: t,
                canFlip: _cameras.length > 1,
                onFlip: _flip,
                onShutter: () => target == null ? null : _shutter(target),
                onPickGallery:
                    target == null ? null : () => _pickFromGallery(target),
                onMissing: target == null ? null : () => _markMissing(target),
                onReject: target == null || !canReject
                    ? null
                    : () => _markRejected(target),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.t,
    required this.target,
    required this.index,
    required this.total,
    required this.onClose,
    this.onPickItem,
  });
  final AppL10n t;
  final VendorPoItem? target;
  final int index;
  final int total;
  final VoidCallback onClose;
  final VoidCallback? onPickItem;

  @override
  Widget build(BuildContext context) {
    final eyebrow = target == null
        ? t.allItemsCaptured
        : t.itemOfTotal(index.clamp(1, total), total);
    final line = target == null
        ? t.noPendingItems
        : '${target!.itemCode} · ${target!.itemName}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoundButton(icon: Icons.close_rounded, onTap: onClose),
          Expanded(
            child: Column(
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: AppType.mono10.copyWith(
                    color: AppColors.gold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  line,
                  textAlign: TextAlign.center,
                  style: AppType.bodyLg.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onPickItem != null)
            _RoundButton(icon: Icons.list_rounded, onTap: onPickItem!)
          else
            const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFF222226),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _GpsPill extends StatelessWidget {
  const _GpsPill({
    required this.busy,
    required this.fix,
    required this.error,
    required this.onRetry,
    required this.t,
  });
  final bool busy;
  final GpsFix? fix;
  final String? error;
  final VoidCallback onRetry;
  final AppL10n t;

  @override
  Widget build(BuildContext context) {
    final ready = fix != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ready
                  ? const Color(0xFF7CD992)
                  : (busy ? Colors.orangeAccent : Colors.redAccent),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              ready
                  ? '${t.gpsLocked}  ·  ${fix!.lat.toStringAsFixed(4)}, ${fix!.lng.toStringAsFixed(4)}  ±  ${fix!.accuracyMeters.round()} m'
                  : busy
                      ? t.waitingGps
                      : (error ?? t.gpsBlocked),
              style: AppType.body.copyWith(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!ready && !busy) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onRetry,
              child: Text(
                t.retry,
                style: AppType.body.copyWith(color: Colors.cyanAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadBadge extends StatelessWidget {
  const _UploadBadge({
    required this.pending,
    required this.failed,
    required this.onRetry,
    required this.t,
  });
  final int pending;
  final int failed;
  final VoidCallback? onRetry;
  final AppL10n t;

  @override
  Widget build(BuildContext context) {
    if (pending == 0 && failed == 0) return const SizedBox.shrink();
    final children = <Widget>[];
    if (pending > 0) {
      children.add(_Pill(
        bg: AppColors.teal.withAlpha(60),
        border: AppColors.teal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(t.uploadingBadge(pending),
                style: AppType.mono10.copyWith(color: Colors.white)),
          ],
        ),
      ));
    }
    if (failed > 0) {
      children.add(GestureDetector(
        onTap: onRetry,
        child: _Pill(
          bg: AppColors.danger.withAlpha(60),
          border: AppColors.danger,
          child: Text(t.failedBadge(failed),
              style: AppType.mono10.copyWith(color: Colors.white)),
        ),
      ));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: children,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.bg, required this.border, required this.child});
  final Color bg;
  final Color border;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: child,
      );
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({
    required this.initializing,
    required this.error,
    required this.camera,
    required this.photo,
    required this.target,
    required this.allDone,
    required this.t,
  });
  final bool initializing;
  final String? error;
  final CameraController? camera;
  final File? photo;
  final VendorPoItem? target;
  final bool allDone;
  final AppL10n t;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF101013),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo != null)
            Image.file(photo!, fit: BoxFit.cover)
          else if (initializing)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
          else if (camera != null && camera!.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: camera!.value.previewSize?.height ?? 1,
                height: camera!.value.previewSize?.width ?? 1,
                child: CameraPreview(camera!),
              ),
            ),
          if (photo == null && !allDone) ...[
            const IgnorePointer(child: _Grid()),
            const Center(child: _Brackets()),
          ],
          if (allDone)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF7CD992), size: 64),
                  const SizedBox(height: 12),
                  Text(t.allItemsCaptured,
                      style: AppType.h2.copyWith(color: Colors.white)),
                ],
              ),
            ),
          if (photo == null && target != null)
            Positioned(
              left: 0,
              right: 0,
              top: 14,
              child: Center(
                child: Text(
                  target!.itemCode,
                  style: AppType.mono12.copyWith(color: const Color(0xFFFFE07A)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GridPainter());
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(40)
      ..strokeWidth = 1;
    final w3 = size.width / 3;
    final h3 = size.height / 3;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(Offset(w3 * i, 0), Offset(w3 * i, size.height), paint);
      canvas.drawLine(Offset(0, h3 * i), Offset(size.width, h3 * i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Brackets extends StatelessWidget {
  const _Brackets();
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 96,
        height: 96,
        child: CustomPaint(painter: _BracketsPainter()),
      );
}

class _BracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7CFF8C)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const len = 14.0;
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);
    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(size.width - len, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - len),
        Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CaptureBar extends StatelessWidget {
  const _CaptureBar({
    required this.t,
    required this.canFlip,
    required this.onFlip,
    required this.onShutter,
    this.onPickGallery,
    this.onMissing,
    this.onReject,
  });
  final AppL10n t;
  final bool canFlip;
  final VoidCallback onFlip;
  final VoidCallback? onShutter;
  final VoidCallback? onPickGallery;
  final VoidCallback? onMissing;
  final VoidCallback? onReject;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconLabel(
                icon: Icons.cached_rounded,
                label: t.flip,
                onTap: canFlip ? onFlip : null,
              ),
              GestureDetector(
                onTap: onShutter,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: onShutter == null ? Colors.white38 : Colors.white,
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: onShutter == null ? Colors.white38 : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              _IconLabel(
                icon: Icons.photo_library_outlined,
                label: t.uploadFromGallery,
                onTap: onPickGallery,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: t.markMissing,
                  variant: AppBtnVariant.danger,
                  height: 44,
                  leading: const Icon(Icons.block_rounded, size: 18),
                  onPressed: onMissing,
                ),
              ),
              if (onReject != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: t.markRejected,
                    variant: AppBtnVariant.danger,
                    height: 44,
                    leading: const Icon(Icons.do_not_disturb_alt_rounded, size: 18),
                    onPressed: onReject,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.t,
    required this.busy,
    required this.onRetake,
    required this.onConfirm,
  });
  final AppL10n t;
  final bool busy;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: t.retake,
              variant: AppBtnVariant.ghost,
              onPressed: busy ? null : onRetake,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: t.confirmPhoto,
              trailing: const Icon(Icons.check_rounded),
              onPressed: busy ? null : onConfirm,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllDoneBar extends StatelessWidget {
  const _AllDoneBar({required this.t, required this.onFinalize});
  final AppL10n t;
  final VoidCallback onFinalize;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppButton(
        label: t.finalize,
        trailing: const Icon(Icons.arrow_forward_rounded),
        onPressed: onFinalize,
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? Colors.white38 : Colors.cyanAccent;
    return InkResponse(
      onTap: onTap,
      radius: 30,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              style: AppType.mono10.copyWith(color: color, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _ItemPickerSheet extends StatelessWidget {
  const _ItemPickerSheet({
    required this.items,
    required this.doneIds,
    required this.activeId,
    required this.t,
  });
  final List<VendorPoItem> items;
  final Set<String> doneIds;
  final String? activeId;
  final AppL10n t;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              t.pickItemTitle,
              style: AppType.bodyLg.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: Colors.white10,
                ),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final isDone = doneIds.contains(item.id);
                  final isActive = item.id == activeId;
                  return InkWell(
                    onTap: () => Navigator.pop(context, item.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: isDone ? AppColors.gold : Colors.white38,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemCode,
                                  style: AppType.body.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.itemName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppType.caption.copyWith(
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isDone) ...[
                            const SizedBox(width: 8),
                            Text(
                              t.capturedBadge.toUpperCase(),
                              style: AppType.mono10.copyWith(
                                color: AppColors.gold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.my_location_rounded,
                                size: 16, color: Colors.cyanAccent),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
