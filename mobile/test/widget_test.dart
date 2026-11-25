import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/app_router.dart';
import 'package:mobile/app/app_session.dart';
import 'package:mobile/app/navigation_plan.dart';
import 'package:mobile/core/theme/app_tokens.dart';
import 'package:mobile/features/student/student_demo_store.dart';
import 'package:mobile/features/teacher/teacher_demo_store.dart';

void main() {
  setUp(AppSession.end);

  testWidgets('cold app launch shows Welcome before automatic login', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BacaTepatApp());
    await tester.pump();
    expect(find.byKey(const ValueKey('welcome-skip')), findsOneWidget);
    expect(find.text('Siap membaca hari ini?'), findsNothing);
    expect(AppRouter.navigatorKey.currentState!.canPop(), isFalse);
    final welcomeLogo = tester.widget<Image>(
      find.byKey(const ValueKey('welcome-book-logo')),
    );
    expect(welcomeLogo.image, isA<AssetImage>());
    expect(
      (welcomeLogo.image as AssetImage).assetName,
      'assets/illustrations/welcome-open-book.png',
    );
    expect(
      tester
          .widget<Opacity>(find.byKey(const ValueKey('welcome-book-fade')))
          .opacity,
      0,
    );
    expect(
      tester
          .widget<Opacity>(find.byKey(const ValueKey('welcome-letter-b-fade')))
          .opacity,
      0,
    );

    await tester.pump(const Duration(milliseconds: 1100));
    expect(
      tester
          .widget<Opacity>(find.byKey(const ValueKey('welcome-letter-b-fade')))
          .opacity,
      greaterThan(0),
    );
    expect(
      tester
          .widget<Opacity>(find.byKey(const ValueKey('welcome-letter-a-fade')))
          .opacity,
      0,
    );
    expect(
      tester
          .widget<Opacity>(find.byKey(const ValueKey('welcome-letter-ca-fade')))
          .opacity,
      0,
    );

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const ValueKey('welcome-skip')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('welcome-book-animation')),
      findsOneWidget,
    );
    expect(find.text('Siap membaca hari ini?'), findsNothing);
    expect(AppRouter.navigatorKey.currentState!.canPop(), isFalse);
    expect(
      tester
          .widget<Opacity>(find.byKey(const ValueKey('welcome-book-fade')))
          .opacity,
      1,
    );
    expect(
      tester
          .widget<Transform>(find.byKey(const ValueKey('welcome-book-rise')))
          .transform
          .getTranslation()
          .y,
      0,
    );
    expect(
      tester
          .widget<Transform>(find.byKey(const ValueKey('welcome-book-scale')))
          .transform
          .getMaxScaleOnAxis(),
      1,
    );
    expect(find.byKey(const ValueKey('welcome-book-rise')), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome-book-scale')), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome-book-sparkles')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2999));
    expect(find.byKey(const ValueKey('welcome-skip')), findsOneWidget);
    expect(find.text('Siap membaca hari ini?'), findsNothing);
    expect(
      tester
          .widget<Opacity>(find.byKey(const ValueKey('welcome-book-fade')))
          .opacity,
      1,
    );
    for (final id in const ['b', 'a', 'ca']) {
      expect(
        tester
            .widget<Opacity>(find.byKey(ValueKey('welcome-letter-$id-fade')))
            .opacity,
        1,
      );
    }

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('welcome-skip')), findsNothing);
    expect(find.text('Siap membaca hari ini?'), findsOneWidget);
    expect(AppRouter.navigatorKey.currentState!.canPop(), isFalse);
  });

  testWidgets('Welcome advances to login and role can be selected there', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const BacaTepatApp());
    await tester.pump();
    expect(find.byKey(const ValueKey('welcome-skip')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('welcome-skip')));
    await tester.pumpAndSettle();
    expect(find.text('Siap membaca hari ini?'), findsOneWidget);
    expect(find.byKey(const ValueKey('choose-teacher')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('login-toggle-role')));
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke ruang kelas'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('login-username')),
      'guru-demo',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'demo',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();
    expect(AppSession.role, AppRole.teacher);
    expect(AppSession.userId, 1);
    expect(AppSession.teacherId, 1);
    expect(find.text('Ringkasan kelas'), findsOneWidget);
  });

  testWidgets('student login opens the student home and bottom navigation', (
    tester,
  ) async {
    await _openRoute(tester, '/siswa/login', width: 390);
    expect(find.text('Siap membaca hari ini?'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('login-username')),
      'andi.1a',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'demo',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();
    expect(AppSession.role, AppRole.student);
    expect(AppSession.userId, 101);
    expect(AppSession.studentId, 1);
    expect(find.text('Selamat pagi,'), findsOneWidget);
    expect(find.byKey(const ValueKey('student-tab-S4')), findsOneWidget);
    expect(find.byKey(const ValueKey('student-tab-S9')), findsOneWidget);
  });

  testWidgets('all planned routes render at phone and wide widths', (
    tester,
  ) async {
    for (final width in const [320.0, 390.0, 1280.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, width == 1280 ? 900 : 844);
      for (final screen in NavigationPlan.teacher) {
        await _openRoute(
          tester,
          screen.path,
          width: width,
          role: AppRole.teacher,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.id} at $width',
        );
      }
      for (final screen in NavigationPlan.student) {
        await _openRoute(
          tester,
          screen.path,
          width: width,
          role: AppRole.student,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.id} at $width',
        );
      }
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  test('navigation inventory and main theme contrast are preserved', () {
    expect(NavigationPlan.teacher, hasLength(17));
    expect(NavigationPlan.student, hasLength(10));
    expect(
      _contrastRatio(AppTokens.text, AppTokens.background),
      greaterThan(7),
    );
    expect(_contrastRatio(Colors.white, AppTokens.primary), greaterThan(4.5));
  });

  testWidgets('practice follows its material and scores the matching aspect', (
    tester,
  ) async {
    final question = TeacherDemoStore.instance
        .practiceQuestionsForMaterial(5)
        .single;
    await _openRoute(
      tester,
      '/siswa/latihan',
      width: 390,
      role: AppRole.student,
    );
    await tester.tap(find.byKey(const ValueKey('practice-material-5')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('material-start-exercise')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('material-start-exercise')));
    await tester.pumpAndSettle();

    expect(find.text('Soal 1 dari 1'), findsOneWidget);
    expect(find.text(question.prompt), findsOneWidget);
    expect(find.text(question.picture), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey('exercise-answer-${question.correctAnswerIndex}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-next')));
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);
    expect(StudentDemoStore.instance.practiceScores['huruf'], 100);
  });

  testWidgets('wrong practice answer shows a hint without marking the key', (
    tester,
  ) async {
    final question = TeacherDemoStore.instance
        .practiceQuestionsForMaterial(5)
        .single;
    await _openRoute(
      tester,
      '/siswa/latihan',
      width: 390,
      role: AppRole.student,
    );
    await tester.tap(find.byKey(const ValueKey('practice-material-5')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('material-start-exercise')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('material-start-exercise')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        ValueKey(
          'exercise-answer-${(question.correctAnswerIndex! + 1) % question.choices.length}',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tidak apa-apa. ${question.hint}'), findsOneWidget);
    expect(find.text(question.correctFeedback), findsNothing);
  });
  testWidgets('diagnostic feedback responds to the selected answer', (
    tester,
  ) async {
    await _openRoute(
      tester,
      '/siswa/diagnostik',
      width: 390,
      role: AppRole.student,
    );
    await tester.tap(find.byKey(const ValueKey('diagnostic-answer-1')));
    await tester.pumpAndSettle();
    expect(
      find.text('Sebutkan nama bendanya, lalu dengarkan bunyi paling awal.'),
      findsOneWidget,
    );
    expect(
      find.text('Tepat! Kamu menemukan bunyi huruf awalnya.'),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('diagnostic-answer-0')));
    await tester.pumpAndSettle();
    expect(
      find.text('Tepat! Kamu menemukan bunyi huruf awalnya.'),
      findsOneWidget,
    );
  });
}

Future<void> _openRoute(
  WidgetTester tester,
  String path, {
  required double width,
  AppRole? role,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, width == 1280 ? 900 : 844);
  await tester.pumpWidget(const BacaTepatApp());
  await tester.pump();
  AppSession.end();
  StudentDemoStore.instance.resetForTests();
  if (role == AppRole.student) {
    AppSession.startStudent(user: 101, student: 1);
  } else if (role == AppRole.teacher) {
    AppSession.startTeacher(user: 1, teacher: 1);
  }
  AppRouter.navigatorKey.currentState!.pushNamedAndRemoveUntil(
    path,
    (_) => false,
  );
  await tester.pumpAndSettle();
}

double _contrastRatio(Color foreground, Color background) {
  double luminance(Color color) {
    double channel(double normalized) => normalized <= 0.04045
        ? normalized / 12.92
        : math.pow((normalized + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  final values = [luminance(foreground), luminance(background)]..sort();
  return (values[1] + 0.05) / (values[0] + 0.05);
}
