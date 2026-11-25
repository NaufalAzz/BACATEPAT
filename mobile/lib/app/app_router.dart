import 'package:flutter/material.dart';

import '../core/components/route_message_page.dart';
import '../features/auth/login_page.dart';
import 'role_selection_page.dart';
import '../features/student/student_shell.dart';
import '../features/teacher/teacher_shell.dart';
import '../features/teacher/teacher_demo_store.dart';
import '../features/student/student_demo_store.dart';
import 'app_session.dart';
import '../core/api/learning_session.dart';
import 'navigation_plan.dart';

abstract final class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static final _screens = [
    ...NavigationPlan.teacher,
    ...NavigationPlan.student,
  ];

  static Route<void> onGenerateRoute(RouteSettings settings) {
    if (settings.name == '/welcome') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const RoleSelectionPage(),
      );
    }

    PlannedScreen? screen;
    for (final candidate in _screens) {
      if (candidate.path == settings.name) {
        screen = candidate;
        break;
      }
    }
    final resolvedScreen = screen;
    if (resolvedScreen == null) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => RouteMessagePage(
          title: 'Halaman tidak ditemukan',
          message: 'Tujuan ini tidak tersedia dalam pratinjau BacaTepat.',
          actionLabel: 'Pilih role',
          onAction: (context) => Navigator.pushNamedAndRemoveUntil(
            context,
            '/welcome',
            (_) => false,
          ),
        ),
      );
    }

    if (resolvedScreen.id == 'G1' || resolvedScreen.id == 'S1') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => LoginPage(role: resolvedScreen.role),
      );
    }

    final activeRole = AppSession.role;
    final hasValidIdentity = activeRole == AppRole.student
        ? StudentDemoStore.instance.currentStudentId != null
        : activeRole == AppRole.teacher &&
              AppSession.userId != null &&
              AppSession.teacherId == AppSession.userId &&
              (LearningSession.enabled ||
                  AppSession.teacherId ==
                      TeacherDemoStore.instance.demoTeacherId);
    if (activeRole == null || !hasValidIdentity) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const RoleSelectionPage(),
      );
    }
    if (activeRole != resolvedScreen.role) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => RouteMessagePage(
          title: 'Akses tidak tersedia',
          message: 'Halaman ini tidak termasuk dalam pratinjau role Anda.',
          actionLabel: 'Kembali ke beranda',
          onAction: (context) => Navigator.pushNamedAndRemoveUntil(
            context,
            activeRole == AppRole.teacher ? '/guru' : '/siswa',
            (_) => false,
          ),
        ),
      );
    }

    if (activeRole == AppRole.teacher) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) =>
            TeacherShell(screen: resolvedScreen, arguments: settings.arguments),
      );
    }

    if (resolvedScreen.placement == NavigationPlacement.primary) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) =>
            StudentShell(screen: resolvedScreen, arguments: settings.arguments),
      );
    }

    if (activeRole == AppRole.student) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) =>
            StudentShell(screen: resolvedScreen, arguments: settings.arguments),
      );
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => RouteMessagePage.forScreen(resolvedScreen),
    );
  }
}
