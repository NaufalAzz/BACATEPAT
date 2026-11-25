import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/bacatepat_api.dart';
import 'package:mobile/features/auth/account_home.dart';
import 'package:mobile/features/student/dashboard/student_dashboard_page.dart';
import 'package:mobile/features/teacher/dashboard/dashboard_page.dart';

class DashboardApi extends BacaTepatApi {
  DashboardApi(this.role);
  final String role;
  Map<String, dynamic> get user => {
    'role': role,
    'nama': 'Nadia API',
    'kelas': '3A',
  };
  @override
  Future<Map<String, dynamic>> request(
    String path, {
    String? method,
    Map<String, dynamic>? body,
  }) async => switch (path) {
    'auth/me' => {'data': user},
    'guru/dashboard' => {
      'data': {
        'aktif': 12,
        'kelas': 2,
        'pending': 1,
        'diagnosed': 3,
        'averages': [],
        'recordings': [],
        'gaps': [],
        'recommendations': [],
      },
    },
    'guru/pendampingan' || 'guru/kelas' => {'data': []},
    'siswa/beranda' => {
      'data': {
        'active_test': false,
        'has_diagnostic': false,
        'completed': false,
        'rekomendasi': null,
        'latihan': [],
      },
    },
    _ => throw StateError(path),
  };
}

void main() {
  for (final role in ['guru', 'siswa']) {
    testWidgets('Dashboard asli dengan akun API $role', (tester) async {
      final api = DashboardApi(role);
      await tester.pumpWidget(
        MaterialApp(
          home: AccountHome(api: api, user: api.user),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(role == 'guru' ? DashboardOverview : StudentOverview),
        findsOneWidget,
      );
      expect(find.text(role == 'guru' ? '12' : 'Nadia'), findsOneWidget);
      expect(
        find.text(role == 'guru' ? 'Ringkasan' : 'Beranda'),
        findsOneWidget,
      );
      if (role == 'guru') {
        await tester.tap(find.text('Lainnya'));
        await tester.pumpAndSettle();
      }
      if (role == 'guru') {
        await tester.scrollUntilVisible(
          find.text('Profil'),
          80,
          scrollable: find.descendant(
            of: find.byType(GridView),
            matching: find.byType(Scrollable),
          ),
        );
      }
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Nadia API'), findsWidgets);
      final logout = find.byKey(
        ValueKey(role == 'guru' ? 'teacher-logout' : 'student-logout'),
      );
      await tester.scrollUntilVisible(
        logout,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(logout, findsOneWidget);
    });
  }
}
