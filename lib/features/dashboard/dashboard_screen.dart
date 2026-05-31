import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/top_bar.dart';
import '../../core/widgets/trail_logo.dart';
import '../../data/models/user.dart';
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
          child: const TrailLogo(size: 16, showText: false),
        ),
        title: 'Ocean Ship',
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
          children: [
            if (user != null) ...[
              _HeroHeader(user: user, todayLabel: _todayTitle(t), t: t),
              const SizedBox(height: 14),
              _StatRow(
                open: p.open.length,
                closed: p.closed.length,
                total: p.open.length + p.closed.length,
                t: t,
              ),
              const SizedBox(height: 16),
            ],
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.user,
    required this.todayLabel,
    required this.t,
  });
  final User user;
  final String todayLabel;
  final AppL10n t;

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return t.greetingMorning;
    if (h < 17) return t.greetingAfternoon;
    return t.greetingEvening;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.characters.first.toUpperCase();
    if (parts.length == 1) return first;
    final last = parts.last.characters.first.toUpperCase();
    return '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = user.fullName.split(' ').first;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, Color(0xFF02307D), AppColors.ink2],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withAlpha(60),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Decorative gold ring in the corner — kept subtle so it reads as
          // brand texture, not noise.
          Positioned(
            right: -28,
            top: -28,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold.withAlpha(60), width: 1.4),
              ),
            ),
          ),
          Positioned(
            right: -50,
            top: 36,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withAlpha(28),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.gold, Color(0xFFE8C969)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(user.fullName),
                      style: AppType.h3.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _timeGreeting(),
                          style: AppType.caption.copyWith(
                            color: AppColors.gold,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.h2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.mono10.copyWith(
                            color: Colors.white.withAlpha(180),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(28),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withAlpha(40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_outlined,
                        size: 14, color: Colors.white.withAlpha(200)),
                    const SizedBox(width: 8),
                    Text(
                      todayLabel,
                      style: AppType.body.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.open,
    required this.closed,
    required this.total,
    required this.t,
  });
  final int open;
  final int closed;
  final int total;
  final AppL10n t;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: t.statOpen,
            value: open,
            icon: Icons.radio_button_unchecked_rounded,
            accent: AppColors.warn,
            accentSoft: AppColors.warnSoft,
            accentInk: AppColors.warnInk,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: t.statClosed,
            value: closed,
            icon: Icons.check_circle_rounded,
            accent: AppColors.accent,
            accentSoft: AppColors.accentSoft,
            accentInk: AppColors.accentInk,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: t.statTotal,
            value: total,
            icon: Icons.layers_outlined,
            accent: AppColors.navy,
            accentSoft: const Color(0xFFE3E8F4),
            accentInk: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.accentInk,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final Color accentInk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: accentInk),
          ),
          const SizedBox(height: 10),
          Text(
            value.toString(),
            style: AppType.h2.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
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
    final hasQuery = _controller.text.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentSoft,
            ),
            child: const Icon(Icons.search_rounded,
                size: 18, color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.navy,
              style: AppType.body.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: AppType.body.copyWith(color: AppColors.muted2),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (hasQuery)
            GestureDetector(
              onTap: () {
                _controller.clear();
                widget.onChanged('');
              },
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.bgDeep,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.muted),
              ),
            )
          else ...[
            Container(width: 1, height: 18, color: AppColors.line),
            const SizedBox(width: 12),
            const Icon(Icons.qr_code_scanner_rounded,
                size: 20, color: AppColors.navy),
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
