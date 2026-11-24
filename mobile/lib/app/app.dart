import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import 'app_router.dart';
import '../features/auth/restore_session_page.dart';

class BacaTepatApp extends StatelessWidget {
  const BacaTepatApp({
    super.key,
    this.preview = const bool.fromEnvironment('DEMO_MODE'),
  });
  final bool preview;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BacaTepat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('id'),
      supportedLocales: const [Locale('id')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: (settings) =>
          AppRouter.onGenerateRoute(settings, preview: preview),
      onGenerateInitialRoutes: (_) => [
        if (preview)
          AppRouter.onGenerateRoute(const RouteSettings(name: '/welcome'))
        else
          MaterialPageRoute<void>(builder: (_) => const RestoreSessionPage()),
      ],
      initialRoute: '/welcome',
    );
  }
}
