import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/vendor_po.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../dashboard/master_pos_provider.dart';
import '../vendor_detail/vendor_detail_provider.dart';
import '../vendor_list/vendor_list_provider.dart';
import '../vendor_list/widgets/vendor_po_card.dart';

/// Vendor picker for the assignment flow. Choosing a vendor goes straight to
/// the assign-assistant screen — no vendor-detail hop in between.
class AssignVendorsScreen extends StatefulWidget {
  const AssignVendorsScreen({super.key, required this.masterId});
  final String masterId;

  @override
  State<AssignVendorsScreen> createState() => _AssignVendorsScreenState();
}

class _AssignVendorsScreenState extends State<AssignVendorsScreen> {
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorListProvider>().load(widget.masterId);
    });
  }

  // The assign screen reads the vendor's steps from VendorDetailProvider, so
  // load that vendor first, then open the assign screen directly.
  Future<void> _openAssign(VendorPo vendor) async {
    if (_opening) return;
    setState(() => _opening = true);
    final detail = context.read<VendorDetailProvider>();
    try {
      await detail.load(vendor.id);
      if (!mounted) return;
      context.push(Routes.assignAssistantPath(vendor.id));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final p = context.watch<VendorListProvider>();

    return Scaffold(
      appBar: TrailTopBar(
        leading: RoundIconBtn(
          icon: Icons.chevron_left_rounded,
          onPressed: () => context.pop(),
        ),
        title: t.assignAssistant,
        trailing: RoundIconBtn(icon: Icons.more_horiz_rounded, onPressed: () {}),
      ),
      body: Stack(
        children: [
          p.state == LoadState.loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentInk))
              : p.state == LoadState.error
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(p.error ?? '—',
                            style: AppType.body.copyWith(color: AppColors.danger)),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                      children: [
                        Eyebrow(t.assignAssistant),
                        const SizedBox(height: 4),
                        Text(t.assignAssistantSubtitle, style: AppType.bodyMuted),
                        const SizedBox(height: 16),
                        Eyebrow('${t.vendorPos} · ${p.items.length}'),
                        const SizedBox(height: 10),
                        for (final v in p.items) ...[
                          VendorPoCard(
                            vendor: v,
                            onTap: () => _openAssign(v),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (p.items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text('—',
                                textAlign: TextAlign.center, style: AppType.bodyMuted),
                          ),
                      ],
                    ),
          if (_opening)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
