import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/captured_photo.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../../services/camera_service.dart';
import '../../services/location_service.dart';
import '../vendor_detail/vendor_detail_provider.dart';

class ShipmentCaptureScreen extends StatefulWidget {
  const ShipmentCaptureScreen({super.key, required this.vendorId});
  final String vendorId;
  @override
  State<ShipmentCaptureScreen> createState() => _ShipmentCaptureScreenState();
}

class _ShipmentCaptureScreenState extends State<ShipmentCaptureScreen> {
  GpsFix? _fix;
  File? _photo;
  bool _gpsBusy = true;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ensure detail data is loaded
      final p = context.read<VendorDetailProvider>();
      if (p.vendor?.id != widget.vendorId) {
        await p.load(widget.vendorId);
      }
      _acquireGps();
    });
  }

  Future<void> _acquireGps() async {
    setState(() {
      _gpsBusy = true;
      _gpsError = null;
    });
    try {
      final fix = await context.read<LocationService>().currentFix();
      setState(() {
        _fix = fix;
        _gpsBusy = false;
        if (fix == null) _gpsError = AppL10n.of(context).gpsBlocked;
      });
    } catch (e, st) {
      AppLog.error('ShipmentCaptureScreen._acquireGps', e, st);
      setState(() {
        _gpsBusy = false;
        _gpsError = e.toString();
      });
    }
  }

  Future<void> _capture() async {
    final t = AppL10n.of(context);
    if (_fix == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.shutterLocked)));
      return;
    }
    final file = await context.read<CameraService>().takePhoto();
    if (file == null || !mounted) return;
    setState(() => _photo = file);
  }

  Future<void> _submit() async {
    final p = context.read<VendorDetailProvider>();
    final step = p.vendor?.currentStep;
    if (_photo == null || step == null) return;
    final ok = await p.uploadShipmentPhoto(
      stepId: step.id,
      file: _photo!,
      lat: _fix?.lat,
      lng: _fix?.lng,
    );
    if (!ok || !mounted) return;
    final v = p.vendor;
    if (v == null) return;
    final next = v.currentStep;
    if (next != null && next.requiresShipmentPhoto && !next.shipmentCompleted) {
      // stay; new step is also shipment-level
      setState(() {
        _photo = null;
      });
      _acquireGps();
    } else if (next != null && next.requiresItemPhoto) {
      context.replace(Routes.itemLoopPath(v.id));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final p = context.watch<VendorDetailProvider>();
    final step = p.vendor?.currentStep;
    final gpsReady = _fix != null;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            t.shipmentCaptureTitle,
                            style: AppType.label.copyWith(color: Colors.white),
                          ),
                          if (step != null)
                            Text(step.nameFor(t.locale.languageCode),
                                style: AppType.caption.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _photo == null ? null : () => setState(() => _photo = null),
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _photo != null
                          ? Image.file(_photo!, fit: BoxFit.cover)
                          : const CapturedPhoto(tone: 1, radius: 24),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: _GpsBanner(
                        ready: gpsReady,
                        busy: _gpsBusy,
                        fix: _fix,
                        error: _gpsError,
                        onRetry: _acquireGps,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _photo == null
                        ? AppButton(
                            label: t.captureNow,
                            variant: AppBtnVariant.primary,
                            leading: const Icon(Icons.photo_camera_outlined),
                            onPressed: gpsReady ? _capture : null,
                          )
                        : AppButton(
                            label: t.submit,
                            loading: p.busy,
                            trailing: const Icon(Icons.check_rounded),
                            onPressed: _submit,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpsBanner extends StatelessWidget {
  const _GpsBanner({
    required this.ready,
    required this.busy,
    required this.fix,
    required this.error,
    required this.onRetry,
  });
  final bool ready;
  final bool busy;
  final GpsFix? fix;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final bg = ready ? AppColors.accentInk.withAlpha(217) : Colors.black.withAlpha(140);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          else
            Icon(
              ready ? Icons.location_on_rounded : Icons.location_searching_rounded,
              color: Colors.white,
              size: 18,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready ? t.gpsLocked : busy ? t.waitingGps : (error ?? t.shutterLocked),
                  style: AppType.body.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                if (fix != null)
                  Text(
                    Fmt.gps(fix!.lat, fix!.lng),
                    style: AppType.mono10.copyWith(color: Colors.white70),
                  ),
              ],
            ),
          ),
          if (!ready && !busy)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
