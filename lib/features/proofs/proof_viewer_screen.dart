import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/proof_log.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../l10n/app_l10n.dart';
import '../../services/locale_service.dart';
import '../vendor_detail/vendor_detail_provider.dart';

/// Full-screen view of a single proof photo with action buttons (open
/// location on map, etc.). Picks the matching ProofLog out of the loaded
/// ProofHistory by id, so navigating here only needs the proof id.
class ProofViewerScreen extends StatefulWidget {
  const ProofViewerScreen({
    super.key,
    required this.vendorId,
    required this.proofId,
  });
  final String vendorId;
  final String proofId;

  @override
  State<ProofViewerScreen> createState() => _ProofViewerScreenState();
}

class _ProofViewerScreenState extends State<ProofViewerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<VendorDetailProvider>();
      if (p.vendor?.id != widget.vendorId) await p.load(widget.vendorId);
      if (p.proofs == null) await p.loadProofs();
    });
  }

  ProofLog? _findProof(VendorDetailProvider p) {
    final h = p.proofs;
    if (h == null) return null;
    for (final l in h.shipmentProofs) {
      if (l.id == widget.proofId) return l;
    }
    for (final l in h.itemProofs) {
      if (l.id == widget.proofId) return l;
    }
    return null;
  }

  Future<void> _openMap(ProofLocation loc) async {
    final lat = loc.latitude;
    final lng = loc.longitude;
    final messenger = ScaffoldMessenger.of(context);
    final t = AppL10n.of(context);

    final googleUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(googleUri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      AppLog.error('ProofViewerScreen._openMap', e, st);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(t.mapOpenFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final p = context.watch<VendorDetailProvider>();
    final repo = context.read<DeliveryRepository>();
    final locale = context.watch<LocaleService>().locale.languageCode;
    final log = _findProof(p);
    final attachment = log?.attachment;
    final url = attachment == null ? null : repo.fileUrl(attachment.fileUrl);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withAlpha(180),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          log?.stepNameFor(locale) ?? t.proofsTitle,
          style: AppType.body.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
      body: log == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: url == null
                        ? Text(t.noProofs,
                            style: AppType.body.copyWith(color: Colors.white))
                        : InteractiveViewer(
                            child: CachedNetworkImage(
                              imageUrl: url,
                              httpHeaders: repo.authHeaders,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white)),
                              errorWidget: (_, __, ___) => Center(
                                child: Text(t.imageLoadFailed,
                                    style: AppType.body
                                        .copyWith(color: Colors.white)),
                              ),
                            ),
                          ),
                  ),
                ),
                _MetaPanel(log: log, localeCode: locale, onOpenMap: _openMap, t: t),
              ],
            ),
    );
  }
}

class _MetaPanel extends StatelessWidget {
  const _MetaPanel({
    required this.log,
    required this.localeCode,
    required this.onOpenMap,
    required this.t,
  });
  final ProofLog log;
  final String localeCode;
  final ValueChanged<ProofLocation> onOpenMap;
  final AppL10n t;

  @override
  Widget build(BuildContext context) {
    final loc = log.location;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow(log.stepNameFor(localeCode)),
            const SizedBox(height: 6),
            if (log.itemName != null) ...[
              Text(
                log.itemName!,
                style: AppType.bodyLg.copyWith(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],
            Text(
              Fmt.time(log.loggedAt),
              style: AppType.caption.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            if (loc == null)
              Text(t.locationUnavailable,
                  style: AppType.bodyMuted.copyWith(color: Colors.white60))
            else ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  AppChip(
                    label: Fmt.gps(loc.latitude, loc.longitude),
                    tone: ChipTone.dark,
                  ),
                  if (loc.accuracyMeters != null)
                    AppChip(label: '±${loc.accuracyMeters!.round()} m', tone: ChipTone.dark),
                ],
              ),
              const SizedBox(height: 14),
              AppButton(
                label: t.viewOnMap,
                leading: const Icon(Icons.map_outlined),
                onPressed: () => onOpenMap(loc),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
