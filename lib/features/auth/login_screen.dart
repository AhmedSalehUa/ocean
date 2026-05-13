import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/trail_logo.dart';
import '../../l10n/app_l10n.dart';
import '../../routing/routes.dart';
import '../../services/locale_service.dart';
import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController(text: 'rep1');
  final _password = TextEditingController(text: 'Rep@123');
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await context.read<AuthProvider>().signIn(
          username: _username.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    if (ok) {
      context.go(Routes.dashboard);
    } else {
      final err = context.read<AuthProvider>().error;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleService>();

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(color: AppColors.bg),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const TrailLogo(size: 20),
                  Row(
                    children: [
                      TextButton(
                        onPressed: locale.toggle,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          locale.isRtl ? t.languageEnglish : t.languageArabic,
                          style: AppType.mono11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const AppChip(label: 'v 2.4.1', tone: ChipTone.ghost),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Eyebrow(t.loginEyebrow),
              const SizedBox(height: 10),
              Text(t.tagline, style: AppType.h1),
              const SizedBox(height: 28),
              _Field(
                controller: _username,
                hint: t.username,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 10),
              _Field(
                controller: _password,
                hint: t.password,
                icon: Icons.lock_outline,
                obscure: _obscure,
                trailing: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  color: AppColors.muted2,
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: auth.status == AuthStatus.signingIn ? t.verifyingToken : t.continueAction,
                loading: auth.status == AuthStatus.signingIn,
                trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text(t.jwtFooter, style: AppType.caption),
                ],
              ),
              const Spacer(),
              Text(
                t.copyright,
                textAlign: TextAlign.center,
                style: AppType.mono10.copyWith(color: AppColors.muted2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.trailing,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: AppType.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppType.body.copyWith(color: AppColors.muted2),
        prefixIcon: Icon(icon, color: AppColors.muted, size: 18),
        suffixIcon: trailing,
      ),
    );
  }
}
