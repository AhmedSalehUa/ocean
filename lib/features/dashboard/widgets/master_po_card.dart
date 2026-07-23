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
import '../../../data/models/delivery_note.dart';
import '../../../data/models/master_po.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../../l10n/app_l10n.dart';
import '../../../services/file_pick_service.dart';
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

    return AppCard(
      onTap: onTap,
      muted: muted,
      borderColor: master.urgent && !muted ? AppColors.accent : null,
      glow: master.urgent && !muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          master.masterPoNumber,
                          style: AppType.mono10.copyWith(color: AppColors.muted),
                        ),
                        if (master.urgent)
                          AppChip(label: master.priorityLabel ?? '⏱', tone: ChipTone.warn),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t.vendors(master.vendorPoCount)} · ${master.site ?? ''}',
                      style: AppType.bodyLg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_has(master.vesselName)) ...[
                      const SizedBox(height: 6),
                      _DetailRow(
                        icon: Icons.directions_boat_outlined,
                        title: t.vesselName,
                        value: master.vesselName!,
                      ),
                    ],
                    if (_has(master.portName)) ...[
                      const SizedBox(height: 4),
                      _DetailRow(
                        icon: Icons.anchor_outlined,
                        title: t.portName,
                        value: master.portName!,
                      ),
                    ],
                    if (master.etaDate != null) ...[
                      const SizedBox(height: 4),
                      _DetailRow(
                        icon: Icons.event_available_outlined,
                        title: t.etaDate,
                        value: Fmt.date(master.etaDate!),
                      ),
                    ],
                    const SizedBox(height: 2),
                    if (master.operationDate != null)
                      Text(
                        Fmt.relativeDay(master.operationDate!, locale: t.locale.languageCode),
                        style: AppType.caption,
                      ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: allDone ? AppColors.accentSoft : AppColors.accentInk,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  allDone ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  size: 18,
                  color: allDone ? AppColors.accentInk : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  t.clearedRatio(master.deliveredVendorPoCount, master.vendorPoCount),
                  style: AppType.mono10.copyWith(color: AppColors.muted),
                ),
              ),
              Text('$pct%', style: AppType.mono10.copyWith(color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 6),
          SimpleProgressBar(
            value: master.progress,
            color: allDone ? AppColors.accent : AppColors.accentInk,
          ),
          if (master.deliveryNote != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.lineSoft),
            const SizedBox(height: 10),
            _DeliveryNoteStrip(master: master),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 5),
        Text(
          '$title: ',
          style: AppType.caption.copyWith(color: AppColors.muted),
        ),
        Expanded(
          child: Text(
            value,
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
      if (result.type != ResultType.done && mounted) {
        // Distinguish "no OS handler" from a real download failure so the
        // user isn't told the download broke when it actually succeeded.
        final label = result.type == ResultType.noAppToOpen
            ? t.deliveryNoteNoOpener(file.uri.pathSegments.last)
            : '${t.deliveryNoteDownloadFailed} (${result.message})';
        messenger.showSnackBar(SnackBar(
          content: Text(label),
          duration: const Duration(seconds: 5),
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
    final messenger = ScaffoldMessenger.of(context);
    final picked = await const FilePickService().pickDeliveryNote();
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
