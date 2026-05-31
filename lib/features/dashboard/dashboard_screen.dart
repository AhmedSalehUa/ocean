import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/top_bar.dart';
import '../../core/widgets/trail_logo.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../../services/locale_service.dart';
import '../auth/auth_provider.dart';
import 'master_pos_provider.dart';
import 'widgets/master_po_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterPosProvider>().refresh();
    });
  }

  bool _matches(String poNumber) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return poNumber.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final p = context.watch<MasterPosProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: TrailTopBar(
        leading: GestureDetector(
          onTap: () => _showAccountSheet(context),
          child: const TrailLogo(size: 16),
        ),
        title: _todayTitle(t),
        trailing: RoundIconBtn(
          icon: Icons.translate,
          tooltip: t.toggleLanguage,
          onPressed: () => context.read<LocaleService>().toggle(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => p.refresh(),
        color: AppColors.accentInk,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
          children: [
            if (user != null) ...[
              Eyebrow(t.greeting(user.fullName.split(' ').first, user.role)),
              const SizedBox(height: 4),
              Text(t.mastersToClear(p.open.length), style: AppType.h2),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 16),
            _SearchBar(
              hint: t.searchHint,
              value: _query,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 18),
            if (p.state == LoadState.loading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator(color: AppColors.accentInk)),
              )
            else if (p.state == LoadState.error)
              _ErrorBox(message: p.error ?? '—', onRetry: p.refresh)
            else ...[
              () {
                final open = p.open.where((m) => _matches(m.masterPoNumber)).toList();
                final closed = p.closed.where((m) => _matches(m.masterPoNumber)).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Eyebrow('● ${t.openSection} · ${open.length}'),
                    const SizedBox(height: 10),
                    for (final m in open) ...[
                      MasterPoCard(
                        master: m,
                        onTap: () => context.push(Routes.vendorListPath(m.id)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (closed.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Eyebrow('${t.recentlyClosedSection} · ${closed.length}'),
                      const SizedBox(height: 10),
                      for (final m in closed) ...[
                        MasterPoCard(
                          master: m,
                          muted: true,
                          onTap: () => context.push(Routes.vendorListPath(m.id)),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                    if (_query.trim().isNotEmpty && open.isEmpty && closed.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          '—',
                          textAlign: TextAlign.center,
                          style: AppType.bodyMuted,
                        ),
                      ),
                  ],
                );
              }(),
            ],
          ],
        ),
      ),
    );
  }

  String _todayTitle(AppL10n t) {
    final now = DateTime.now();
    final months = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final monthsAr = const [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    final m = t.isAr ? monthsAr[now.month - 1] : months[now.month - 1];
    return '${t.isAr ? 'اليوم' : 'Today'} · ${now.day} $m';
  }

  void _showAccountSheet(BuildContext context) {
    final t = AppL10n.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 20),
              AppButton(
                label: t.logout,
                variant: AppBtnVariant.danger,
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) context.go(Routes.login);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.hint,
    required this.value,
    required this.onChanged,
  });
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: AppType.body,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: AppType.body.copyWith(color: AppColors.muted2),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                widget.onChanged('');
              },
              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.muted),
            )
          else ...[
            Container(width: 1, height: 16, color: AppColors.line),
            const SizedBox(width: 10),
            const Icon(Icons.qr_code_2, size: 16, color: AppColors.ink2),
          ],
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppType.body.copyWith(color: AppColors.danger)),
          const SizedBox(height: 12),
          AppButton(
            label: 'Retry',
            variant: AppBtnVariant.dark,
            full: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
