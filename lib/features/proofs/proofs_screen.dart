import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/captured_photo.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/proof_log.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../../services/locale_service.dart';
import '../vendor_detail/vendor_detail_provider.dart';

class ProofsScreen extends StatefulWidget {
  const ProofsScreen({super.key, required this.vendorId});
  final String vendorId;

  @override
  State<ProofsScreen> createState() => _ProofsScreenState();
}

class _ProofsScreenState extends State<ProofsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<VendorDetailProvider>();
      if (p.vendor?.id != widget.vendorId) await p.load(widget.vendorId);
      await p.loadProofs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final p = context.watch<VendorDetailProvider>();
    final proofs = p.proofs;
    final locale = context.watch<LocaleService>().locale.languageCode;

    return Scaffold(
      appBar: TrailTopBar(
        leading: RoundIconBtn(
          icon: Icons.chevron_left_rounded,
          onPressed: () => context.pop(),
        ),
        title: t.proofsTitle,
      ),
      body: proofs == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentInk))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
              children: [
                Text(proofs.supplierName, style: AppType.h2),
                const SizedBox(height: 6),
                Text(
                  '${proofs.shipmentProofs.length + proofs.itemProofs.length} ${t.proofsTitle.toLowerCase()}',
                  style: AppType.caption,
                ),
                const SizedBox(height: 18),
                _Section(
                  title: t.shipmentProofs,
                  logs: proofs.shipmentProofs,
                  localeCode: locale,
                  empty: t.noProofs,
                ),
                const SizedBox(height: 18),
                _Section(
                  title: t.itemProofs,
                  logs: proofs.itemProofs,
                  localeCode: locale,
                  empty: t.noProofs,
                ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.logs,
    required this.localeCode,
    required this.empty,
  });
  final String title;
  final List<ProofLog> logs;
  final String localeCode;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow('$title · ${logs.length}'),
        const SizedBox(height: 10),
        if (logs.isEmpty)
          AppCard(child: Center(child: Text(empty, style: AppType.bodyMuted)))
        else
          for (var i = 0; i < logs.length; i++) ...[
            _ProofTile(log: logs[i], localeCode: localeCode),
            if (i < logs.length - 1) const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _ProofTile extends StatelessWidget {
  const _ProofTile({required this.log, required this.localeCode});
  final ProofLog log;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final repo = context.read<DeliveryRepository>();
    final attachment = log.attachment;
    final url = attachment == null ? '' : repo.fileUrl(attachment.fileUrl);
    final isHttp = url.startsWith('http');

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () =>
          context.push(Routes.proofViewerPath(log.vendorPoId, log.id)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 76,
              height: 76,
              child: isHttp
                  ? CachedNetworkImage(
                      imageUrl: url,
                      httpHeaders: repo.authHeaders,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const CapturedPhoto(tone: 2, height: 76, radius: 10),
                      errorWidget: (_, __, ___) =>
                          const CapturedPhoto(tone: 0, height: 76, radius: 10),
                    )
                  : CapturedPhoto(
                      tone: log.id.hashCode,
                      height: 76,
                      radius: 10,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.stepNameFor(localeCode),
                  style: AppType.body.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                if (log.itemName != null)
                  Text(log.itemName!, style: AppType.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    AppChip(label: Fmt.time(log.loggedAt)),
                    if (log.attachment != null)
                      AppChip(label: log.attachment!.prettySize),
                    if (log.location != null)
                      const AppChip(label: '📍', tone: ChipTone.soft),
                    if (log.isAutoCompleted)
                      AppChip(label: t.autoCompleted, tone: ChipTone.green),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: AppColors.muted),
        ],
      ),
    );
  }
}
