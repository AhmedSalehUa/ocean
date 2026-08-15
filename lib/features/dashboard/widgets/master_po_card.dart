import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/widgets/capture_source_sheet.dart';
import '../../../data/models/delivery_note.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/master_po.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../../l10n/app_l10n.dart';
import '../../../services/camera_service.dart';
import '../../../services/file_pick_service.dart';
import '../../../services/location_service.dart';
import '../master_pos_provider.dart';

bool _has(String? s) => s != null && s.trim().isNotEmpty;

class MasterPoCard extends StatelessWidget {
  const MasterPoCard({
    super.key,
    required this.master,
    required this.onTap,
    this.muted = false,
  });
  final MasterPo master;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final pct = (master.progress * 100).round();
    final allDone = master.isClosed;
    final locale = t.locale.languageCode;
    final status = _statusStyle(t);

    final hero = _has(master.vesselName)
        ? master.vesselName!
        : (_has(master.site) ? master.site! : '${t.masterFallbackTitle} ${master.masterPoNumber}');

    return AppCard(
      onTap: onTap,
      muted: muted,
      borderColor: master.urgent && !muted ? AppColors.accent : null,
      glow: master.urgent && !muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: ship tile + hero + status ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: allDone
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.navy, AppColors.ink2],
                        ),
                  color: allDone ? AppColors.accentSoft : null,
                ),
                child: Icon(
                  allDone ? Icons.check_rounded : Icons.directions_boat_rounded,
                  size: 22,
                  color: allDone ? AppColors.accentInk : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            hero,
                            style: AppType.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(label: status.label, tone: status.tone),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '#${master.masterPoNumber}',
                          style: AppType.mono10.copyWith(color: AppColors.muted),
                        ),
                        if (master.urgent) ...[
                          const SizedBox(width: 8),
                          AppChip(label: master.priorityLabel ?? '⏱', tone: ChipTone.warn),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Info pills ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.local_shipping_outlined,
                label: t.vendors(master.vendorPoCount),
              ),
              if (_has(master.portName))
                _InfoChip(icon: Icons.anchor_outlined, label: master.portName!),
              if (master.etaDate != null)
                _InfoChip(
                  icon: Icons.event_available_outlined,
                  label: Fmt.date(master.etaDate!),
                ),
              if (master.operationDate != null)
                _InfoChip(
                  icon: Icons.schedule_outlined,
                  label: Fmt.relativeDay(master.operationDate!, locale: locale),
                ),
            ],
          ),
          if (_has(master.representativeName) || _has(master.assistantName)) ...[
            const SizedBox(height: 12),
            if (_has(master.representativeName))
              _PersonLine(
                label: t.primaryRepresentative,
                name: master.representativeName!,
              ),
            if (_has(master.assistantName)) ...[
              if (_has(master.representativeName)) const SizedBox(height: 6),
              _PersonLine(
                label: t.subRepresentative,
                name: master.assistantName!,
              ),
            ],
          ],
          const SizedBox(height: 16),
          // ── Progress ──
          Row(
            children: [
              Expanded(
                child: Text(
                  t.clearedRatio(master.deliveredVendorPoCount, master.vendorPoCount),
                  style: AppType.caption.copyWith(color: AppColors.muted),
                ),
              ),
              Text(
                '$pct%',
                style: AppType.mono11.copyWith(
                  color: allDone ? AppColors.accentInk : AppColors.ink2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SimpleProgressBar(
            value: master.progress,
            color: allDone ? AppColors.accent : AppColors.accentInk,
          ),
          if (master.currentStep?.isLpo ?? false) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.lineSoft),
            const SizedBox(height: 12),
            _LpoStrip(master: master, step: master.currentStep!),
          ],
          if (master.deliveryNote != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.lineSoft),
            const SizedBox(height: 12),
            _DeliveryNoteStrip(master: master),
          ],
        ],
      ),
    );
  }

  ({String label, ChipTone tone}) _statusStyle(AppL10n t) {
    return switch (master.status) {
      MasterStatus.open => (label: t.masterStatusNew, tone: ChipTone.neutral),
      MasterStatus.inProgress =>
        (label: t.masterStatusInProgress, tone: ChipTone.warn),
      MasterStatus.fullyDelivered =>
        (label: t.masterStatusDelivered, tone: ChipTone.green),
      MasterStatus.partiallyDelivered =>
        (label: t.masterStatusPartial, tone: ChipTone.warn),
      MasterStatus.closed => (label: t.masterStatusClosed, tone: ChipTone.green),
    };
  }
}

/// Compact status pill for the master card header.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});
  final String label;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      ChipTone.green => (AppColors.accentSoft, AppColors.accentInk),
      ChipTone.warn => (AppColors.warnSoft, AppColors.warnInk),
      ChipTone.danger => (AppColors.dangerSoft, AppColors.danger),
      _ => (AppColors.bgDeep, AppColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label.toUpperCase(),
        style: AppType.mono10.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Icon + label pill used for the master card's meta row.
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.ink2),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppType.caption.copyWith(
              color: AppColors.ink2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled person row (المندوب الرئيسي / المندوب الفرعي) shown on the
/// master card when the API surfaces the assigned rep and/or assistant.
class _PersonLine extends StatelessWidget {
  const _PersonLine({required this.label, required this.name});
  final String label;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.person_outline_rounded, size: 14, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppType.caption.copyWith(color: AppColors.muted),
        ),
        Expanded(
          child: Text(
            name,
            style: AppType.caption.copyWith(
              color: AppColors.ink2,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Download + upload strip that surfaces the delivery-note attachment
/// under each master card. Download is always available (as long as the
/// server has a file). Upload is gated on [MasterPo.canUploadDeliveryNote]
/// — i.e. the master PO has to be past IN_PROGRESS.
class _DeliveryNoteStrip extends StatefulWidget {
  const _DeliveryNoteStrip({required this.master});
  final MasterPo master;

  @override
  State<_DeliveryNoteStrip> createState() => _DeliveryNoteStripState();
}

class _DeliveryNoteStripState extends State<_DeliveryNoteStrip> {
  bool _busy = false;

  DeliveryNote get _note => widget.master.deliveryNote!;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final note = _note;
    final canUpload = widget.master.canUploadDeliveryNote;
    final statusLabel = note.status.isCompleted ? t.deliveryNoteCompleted : t.deliveryNoteTemplate;
    final statusTone = note.status.isCompleted ? ChipTone.green : ChipTone.warn;

    return Row(
      children: [
        Icon(_iconFor(note.extension), size: 18, color: AppColors.ink2),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.fileName,
                      style: AppType.caption
                          .copyWith(color: AppColors.ink2, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AppChip(label: statusLabel, tone: statusTone),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${t.deliveryNote} · ${note.prettySize}',
                style: AppType.mono10.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _StripButton(
          icon: Icons.download_rounded,
          tooltip: t.downloadDeliveryNote,
          busy: _busy,
          onPressed: _busy ? null : _download,
        ),
        const SizedBox(width: 4),
        if (canUpload) ...[
          const SizedBox(width: 4),
          _StripButton(
            icon: Icons.upload_rounded,
            tooltip: t.uploadCompletedNote,
            busy: _busy,
            onPressed: _busy ? null : _upload,
          ),
        ],
      ],
    );
  }

  Future<void> _download() async {
    final t = AppL10n.of(context);
    final repo = context.read<DeliveryRepository>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      duration: const Duration(minutes: 1),
      content: _InlineSpinner(label: t.downloadingDeliveryNote),
    ));
    try {
      final file = await repo.downloadDeliveryNote(
        widget.master.id,
        note: widget.master.deliveryNote,
      );
      messenger.hideCurrentSnackBar();
      final size = await file.length();
      AppLog.info('deliveryNote.download', 'saved ${file.path} (${size}B)');
      final result = await OpenFilex.open(file.path);
      AppLog.info('deliveryNote.open', 'result=${result.type} message=${result.message}');
      if (result.type == ResultType.done && mounted) {
        // Silent success — the OS handler is now on screen. Still surface
        // where the file was persisted so the user can find it later.
        messenger.showSnackBar(SnackBar(
          content: Text(t.savedToDownloads),
          duration: const Duration(seconds: 3),
        ));
      } else if (result.type != ResultType.done && mounted) {
        // Distinguish "no OS handler" from a real download failure so the
        // user isn't told the download broke when it actually succeeded.
        final label = result.type == ResultType.noAppToOpen
            ? '${t.deliveryNoteNoOpener(file.uri.pathSegments.last)}\n${t.savedToDownloads}'
            : '${t.deliveryNoteDownloadFailed} (${result.message})';
        messenger.showSnackBar(SnackBar(
          content: Text(label),
          duration: const Duration(seconds: 6),
        ));
      }
    } on ApiException catch (e, st) {
      messenger.hideCurrentSnackBar();
      AppLog.error('deliveryNote.download', e, st);
      final msg = e.statusCode == 404
          ? t.deliveryNoteNotAvailable
          : '${t.deliveryNoteDownloadFailed} (${e.message})';
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (e, st) {
      messenger.hideCurrentSnackBar();
      AppLog.error('deliveryNote.download', e, st);
      messenger.showSnackBar(SnackBar(content: Text('${t.deliveryNoteDownloadFailed} ($e)')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    final t = AppL10n.of(context);
    final repo = context.read<DeliveryRepository>();
    final masters = context.read<MasterPosProvider>();
    final camera = context.read<CameraService>();
    final messenger = ScaffoldMessenger.of(context);

    // Let the rep either snap a photo of the filled note or pick a document.
    final source = await showCaptureSourceSheet(context);
    if (source == null || !mounted) return;
    final picked = source == CaptureSource.camera
        ? await camera.takePhoto()
        : await const FilePickService().pickDeliveryNote();
    if (picked == null || !mounted) return;
    if (!FilePickService.isAllowedForDeliveryNote(picked.uri.pathSegments.last)) {
      messenger.showSnackBar(SnackBar(content: Text(t.unsupportedFileType)));
      return;
    }
    setState(() => _busy = true);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      duration: const Duration(minutes: 1),
      content: _InlineSpinner(label: t.uploadingDeliveryNote),
    ));
    try {
      await repo.uploadDeliveryNote(masterPoId: widget.master.id, file: picked);
      messenger.hideCurrentSnackBar();
      await masters.refresh();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(t.deliveryNoteUploaded)));
    } catch (e, st) {
      messenger.hideCurrentSnackBar();
      AppLog.error('deliveryNote.upload', e, st);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(t.deliveryNoteUploadFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  IconData _iconFor(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.grid_on_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}

/// Capture/upload strip for a Master-PO-level (LPO) step, shown on the card
/// when the master's current step is LPO. Upload-only: the rep captures a
/// photo or picks a document, GPS is attached, and it's posted to the
/// master-scoped lpo-steps endpoint.
class _LpoStrip extends StatefulWidget {
  const _LpoStrip({required this.master, required this.step});
  final MasterPo master;
  final MasterCurrentStep step;

  @override
  State<_LpoStrip> createState() => _LpoStripState();
}

class _LpoStripState extends State<_LpoStrip> {
  bool _busy = false;

  Future<void> _upload() async {
    final t = AppL10n.of(context);
    final repo = context.read<DeliveryRepository>();
    final masters = context.read<MasterPosProvider>();
    final camera = context.read<CameraService>();
    final location = context.read<LocationService>();
    final messenger = ScaffoldMessenger.of(context);

    final source = await showCaptureSourceSheet(context);
    if (source == null || !mounted) return;
    final file = source == CaptureSource.camera
        ? await camera.takePhoto()
        : await const FilePickService().pickDeliveryNote();
    if (file == null || !mounted) return;

    setState(() => _busy = true);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      duration: const Duration(minutes: 1),
      content: _InlineSpinner(label: t.uploadingLpoProof),
    ));
    try {
      final fix = await location.currentFix();
      await repo.lpoPhoto(
        masterPoId: widget.master.id,
        stepId: widget.step.id,
        file: file,
        lat: fix?.lat,
        lng: fix?.lng,
        accuracyMeters: fix?.accuracyMeters,
      );
      messenger.hideCurrentSnackBar();
      await masters.refresh();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(t.lpoProofUploaded)));
    } catch (e, st) {
      messenger.hideCurrentSnackBar();
      AppLog.error('lpo.upload', e, st);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('${t.lpoProofUploadFailed} ($e)')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final name = widget.step.nameFor(locale);
    return Row(
      children: [
        const Icon(Icons.assignment_turned_in_outlined, size: 18, color: AppColors.ink2),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name.isEmpty ? t.lpoStepTitle : name,
                style: AppType.caption.copyWith(color: AppColors.ink2, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(t.lpoStepTitle, style: AppType.mono10.copyWith(color: AppColors.muted)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _StripButton(
          icon: Icons.upload_rounded,
          tooltip: t.uploadLpoProof,
          busy: _busy,
          onPressed: _busy ? null : _upload,
        ),
      ],
    );
  }
}

class _StripButton extends StatelessWidget {
  const _StripButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.busy = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: disabled ? AppColors.bgDeep : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 18,
              color: disabled ? AppColors.muted : AppColors.accentInk,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineSpinner extends StatelessWidget {
  const _InlineSpinner({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    );
  }
}
