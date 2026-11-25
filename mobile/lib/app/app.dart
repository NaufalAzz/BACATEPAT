import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import 'app_router.dart';
import 'app_session.dart';
import '../core/api/learning_session.dart';
import 'navigation_plan.dart';

class BacaTepatApp extends StatelessWidget {
  const BacaTepatApp({super.key});

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
      onGenerateRoute: AppRouter.onGenerateRoute,
      onGenerateInitialRoutes: (_) => [
        AppRouter.onGenerateRoute(
          RouteSettings(
            name: LearningSession.enabled && AppSession.role != null
                ? (AppSession.role == AppRole.teacher ? '/guru' : '/siswa')
                : '/welcome',
          ),
        ),
      ],
      initialRoute: '/welcome',
    );
  }
}
