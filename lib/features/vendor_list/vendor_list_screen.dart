import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/master_po.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../dashboard/master_pos_provider.dart';
import 'vendor_list_provider.dart';
import 'widgets/vendor_po_card.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key, required this.masterId});
  final String masterId;

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorListProvider>().load(widget.masterId);
    });
  }

  MasterPo? _master(BuildContext context) {
    final all = context.read<MasterPosProvider>().items;
    for (final m in all) {
      if (m.id == widget.masterId) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final p = context.watch<VendorListProvider>();
    final master = _master(context);

    return Scaffold(
      appBar: TrailTopBar(
        leading: RoundIconBtn(
          icon: Icons.chevron_left_rounded,
          onPressed: () => context.pop(),
        ),
        title: p.masterPoNumber.isEmpty ? (master?.masterPoNumber ?? '') : p.masterPoNumber,
        trailing: const SizedBox(
          width: 30,
        ),
      ),
      body: p.state == LoadState.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentInk))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
              children: [
                if (master != null) ...[
                  Eyebrow(t.masterPurchaseOrder),
                  const SizedBox(height: 4),
                  Text(master.site ?? '', style: AppType.h2),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (master.operationDate != null)
                        AppChip(
                            label: Fmt.relativeDay(master.operationDate!,
                                locale: t.locale.languageCode)),
                      AppChip(label: t.vendors(master.vendorPoCount)),
                      AppChip(
                        label: t.clearedShort(master.deliveredVendorPoCount, master.vendorPoCount),
                        tone: master.isClosed ? ChipTone.green : ChipTone.warn,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
                Eyebrow('${t.vendorPos} · ${p.items.length}'),
                const SizedBox(height: 10),
                for (final v in p.items) ...[
                  VendorPoCard(
                    vendor: v,
                    onTap: () => context.push(Routes.vendorDetailPath(v.id)),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}
