import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'l10n/app_l10n.dart';
import 'routing/app_router.dart';
import 'services/locale_service.dart';

class TrailApp extends StatefulWidget {
  const TrailApp({super.key});
  @override
  State<TrailApp> createState() => _TrailAppState();
}

class _TrailAppState extends State<TrailApp> {
  late final _router = buildRouter(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleService>();
    return MaterialApp.router(
      title: 'Trail',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
      locale: locale.locale,
      supportedLocales: AppL10n.supported,
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
