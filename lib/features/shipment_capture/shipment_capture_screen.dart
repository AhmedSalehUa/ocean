import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/typography.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/app_button.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../../services/location_service.dart';
import '../vendor_detail/vendor_detail_provider.dart';

class ShipmentCaptureScreen extends StatefulWidget {
  const ShipmentCaptureScreen({super.key, required this.vendorId});
  final String vendorId;
  @override
  State<ShipmentCaptureScreen> createState() => _ShipmentCaptureScreenState();
}

class _ShipmentCaptureScreenState extends State<ShipmentCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _initializing = true;
  String? _cameraError;

  GpsFix? _fix;
  bool _gpsBusy = true;
  String? _gpsError;

  File? _photo;
  Timer? _clock;
  String _now = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tickClock();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tickClock());
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
    _clock?.cancel();
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

  void _tickClock() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    if (mounted) setState(() => _now = '$hh:$mm');
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
      AppLog.error('ShipmentCaptureScreen._bootstrapCamera', e, st);
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
      AppLog.error('ShipmentCaptureScreen._initController', e, st);
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
      AppLog.error('ShipmentCaptureScreen._acquireGps', e, st);
      if (!mounted) return;
      setState(() {
        _gpsBusy = false;
        _gpsError = e.toString();
      });
    }
  }

  Future<void> _shutter() async {
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
      setState(() => _photo = File(shot.path));
    } catch (e, st) {
      AppLog.error('ShipmentCaptureScreen._shutter', e, st);
    }
  }

  void _retake() => setState(() => _photo = null);

  Future<void> _submit() async {
    final t = AppL10n.of(context);
    final p = context.read<VendorDetailProvider>();
    final step = p.vendor?.currentStep;
    if (_photo == null || step == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      duration: const Duration(minutes: 1),
      content: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(t.uploadingShipment)),
        ],
      ),
    ));
    final ok = await p.uploadShipmentPhoto(
      stepId: step.id,
      file: _photo!,
      lat: _fix?.lat,
      lng: _fix?.lng,
      accuracyMeters: _fix?.accuracyMeters,
    );
    messenger.hideCurrentSnackBar();
    if (!mounted) return;
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(p.error ?? 'Upload failed')));
      return;
    }
    final v = p.vendor;
    if (v == null) return;
    final next = v.currentStep;
    // Still on the same shipment step (rare — multiple shipment photos for
    // one step). Stay and let the user shoot the next one.
    if (next != null &&
        next.id == step.id &&
        next.requiresShipmentPhoto &&
        !next.shipmentCompleted) {
      setState(() => _photo = null);
      _acquireGps();
      return;
    }
    // Step transitioned → show the "step done" page; user taps Continue to
    // move into the next capture screen (or finalize for the last step).
    context.replace(Routes.stepDonePath(v.id, step.id));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final p = context.watch<VendorDetailProvider>();
    final step = p.vendor?.currentStep;
    final ref = p.vendor?.vendorRef ?? p.vendor?.supplierName ?? '';
    final stepEn = step?.nameEn ?? '';
    final stepAr = step?.nameAr ?? '';
    final stepLine = stepEn.isEmpty
        ? stepAr
        : (stepAr.isEmpty ? stepEn : '$stepEn · $stepAr');

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              eyebrow: t.shipmentProofEyebrow,
              stepLine: stepLine,
              onClose: () => context.pop(),
            ),
            const SizedBox(height: 8),
            _GpsPill(
              busy: _gpsBusy,
              fix: _fix,
              error: _gpsError,
              onRetry: _acquireGps,
              t: t,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _Viewfinder(
                    initializing: _initializing,
                    error: _cameraError,
                    camera: _camera,
                    photo: _photo,
                    hint: t.frameUnloadingScene,
                    refCode: ref,
                    timeText: _now,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _BottomBar(
              t: t,
              hasPhoto: _photo != null,
              busy: p.busy,
              canFlip: _cameras.length > 1 && _photo == null,
              onFlip: _flip,
              onShutter: _shutter,
              onRetake: _retake,
              onSubmit: _submit,
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
    required this.eyebrow,
    required this.stepLine,
    required this.onClose,
  });
  final String eyebrow;
  final String stepLine;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          _RoundButton(icon: Icons.close_rounded, onTap: onClose),
          Expanded(
            child: Column(
              children: [
                Text(
                  eyebrow,
                  style: AppType.mono10.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stepLine,
                  style: AppType.bodyLg.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
          _StatusDot(busy: busy, ready: ready),
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

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.busy, required this.ready});
  final bool busy;
  final bool ready;
  @override
  Widget build(BuildContext context) {
    final color = ready
        ? const Color(0xFF7CD992)
        : (busy ? Colors.orangeAccent : Colors.redAccent);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({
    required this.initializing,
    required this.error,
    required this.camera,
    required this.photo,
    required this.hint,
    required this.refCode,
    required this.timeText,
  });

  final bool initializing;
  final String? error;
  final CameraController? camera;
  final File? photo;
  final String hint;
  final String refCode;
  final String timeText;

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
          if (photo == null) ...[
            const _GridOverlay(),
            const Center(child: _FocusBrackets()),
            Positioned(
              left: 0,
              right: 0,
              top: 14,
              child: Center(
                child: Text(
                  hint,
                  style: AppType.body.copyWith(color: const Color(0xFFFFE07A)),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    refCode,
                    style: AppType.mono10.copyWith(color: Colors.white70),
                  ),
                  Text(
                    timeText,
                    style: AppType.mono10.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _GridPainter()));
  }
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

class _FocusBrackets extends StatelessWidget {
  const _FocusBrackets();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: CustomPaint(painter: _FocusPainter()),
    );
  }
}

class _FocusPainter extends CustomPainter {
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
    canvas.drawLine(
        Offset(0, size.height - len), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(size.width - len, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - len),
        Offset(size.width, size.height), paint);
    final innerPaint = Paint()
      ..color = Colors.white.withAlpha(160)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final cx = size.width / 2, cy = size.height / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 28, height: 28),
        const Radius.circular(6),
      ),
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.t,
    required this.hasPhoto,
    required this.busy,
    required this.canFlip,
    required this.onFlip,
    required this.onShutter,
    required this.onRetake,
    required this.onSubmit,
  });
  final AppL10n t;
  final bool hasPhoto;
  final bool busy;
  final bool canFlip;
  final VoidCallback onFlip;
  final VoidCallback onShutter;
  final VoidCallback onRetake;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (hasPhoto) {
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
                label: t.submit,
                loading: busy,
                trailing: const Icon(Icons.check_rounded),
                onPressed: busy ? null : onSubmit,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
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
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          _IconLabel(
            icon: Icons.auto_awesome_outlined,
            label: t.hdr,
            onTap: null, // HDR is cosmetic for now
          ),
        ],
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
          Text(
            label.toUpperCase(),
            style: AppType.mono10.copyWith(color: color, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}
