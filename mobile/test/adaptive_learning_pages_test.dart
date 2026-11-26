import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app_session.dart';
import 'package:mobile/features/student/dashboard/student_dashboard_page.dart';
import 'package:mobile/features/student/mastery_history_chart.dart';
import 'package:mobile/features/student/progress/student_progress_page.dart';
import 'package:mobile/features/student/student_demo_store.dart';
import 'package:mobile/features/teacher/dashboard/dashboard_page.dart';
import 'package:mobile/features/teacher/progress/progress_page.dart';
import 'package:mobile/features/teacher/teacher_demo_store.dart';

void main() {
  final teacher = TeacherDemoStore.instance;
  final student = StudentDemoStore.instance;

  setUp(() {
    student.resetForTests();
    AppSession.startStudent(user: 101, student: 1);
  });

  testWidgets('student dashboard recommends only after complete diagnostic', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StudentDashboardPage())),
    );
    expect(
      find.text('Ayo mulai dengan tes membaca bersama Gurumu.'),
      findsOneWidget,
    );
    expect(find.text('Suku kata ba bi bu be bo'), findsNothing);

    _submitDiagnostic(teacher, student, correct: false);
    await tester.pump();
    expect(find.text('Mengenal huruf vokal'), findsOneWidget);
    expect(
      find.text('Kita mulai dari bagian yang masih perlu dilatih.'),
      findsOneWidget,
    );
  });

  testWidgets('student progress uses actual mastery history', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StudentProgressPage())),
    );
    expect(find.byKey(const ValueKey('student-progress-chart')), findsNothing);

    _submitDiagnostic(teacher, student, correct: true);
    final material = teacher.materialById(5)!;
    final question = teacher.practiceQuestionsForMaterial(material.id).first;
    student.completePractice(
      materialId: material.id,
      title: material.title,
      aspect: material.aspect,
      availableQuestionCount: 1,
      questionSnapshots: [question],
      answers: [
        PracticeAnswerRecord(
          questionId: question.id,
          aspect: question.aspect,
          answer:
              question.choices[(question.correctAnswerIndex! + 1) %
                  question.choices.length],
          correctAnswer: question.correctAnswer!,
          isCorrect: false,
        ),
      ],
      startedAt: DateTime(2026, 1, 1, 0, 2),
      finishedAt: DateTime(2026, 1, 1, 0, 3),
      completionToken: 'student-progress-practice-1',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('student-progress-chart')),
      findsOneWidget,
    );
    expect(find.text('HASIL TES DIAGNOSTIK'), findsOneWidget);
    expect(find.textContaining('Suku kata: 100%'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('progress-aspect-huruf')));
    await tester.pump();
    expect(find.textContaining('Huruf: 100%'), findsOneWidget);
    expect(find.text('PERKEMBANGAN HURUF'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('student-mastery-history-chart')),
      findsOneWidget,
    );
    final studentChartFinder = find.ancestor(
      of: find.byKey(const ValueKey('student-mastery-history-chart')),
      matching: find.byType(MasteryHistoryChart),
    );
    final studentChart = tester.widget<MasteryHistoryChart>(studentChartFinder);
    expect(studentChart.points.map((point) => point.score), [100, 0]);
    final historyHeading = find.text('RIWAYAT PENGUASAAN');
    expect(historyHeading, findsOneWidget);
    expect(find.textContaining('Tes diagnostik'), findsWidgets);
  });

  testWidgets('teacher dashboard and progress use scoped mastery records', (
    tester,
  ) async {
    _submitDiagnostic(teacher, student, correct: false);
    AppSession.startTeacher(user: 1, teacher: 1);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DashboardPage())),
    );
    final recommendedTitle = teacher
        .materialById(
          student.activeRecommendationsForTeacher(1).first.materialId,
        )!
        .title;
    await tester.scrollUntilVisible(
      find.text(recommendedTitle),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(recommendedTitle), findsOneWidget);
    expect(find.text('Belum ada rekomendasi aktif.'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProgressPage())),
    );
    expect(
      find.byKey(const ValueKey('teacher-mastery-history-chart')),
      findsOneWidget,
    );
    final teacherChartFinder = find.ancestor(
      of: find.byKey(const ValueKey('teacher-mastery-history-chart')),
      matching: find.byType(MasteryHistoryChart),
    );
    final teacherChart = tester.widget<MasteryHistoryChart>(teacherChartFinder);
    expect(teacherChart.points.map((point) => point.score), [0]);
    await tester.scrollUntilVisible(
      find.text('Riwayat penguasaan'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Riwayat penguasaan'), findsOneWidget);
    expect(find.textContaining('Diagnostik'), findsOneWidget);
    expect(find.text('0%'), findsWidgets);
  });
}

void _submitDiagnostic(
  TeacherDemoStore teacher,
  StudentDemoStore student, {
  required bool correct,
}) {
  final test = teacher.diagnostics.firstWhere((item) => item.id == 1);
  final questions = teacher.diagnosticQuestionsFor(test);
  final answers = [
    for (final question in questions)
      () {
        final index = correct
            ? question.correctAnswerIndex!
            : (question.correctAnswerIndex! + 1) % question.choices.length;
        return DiagnosticAnswerRecord(
          questionId: question.id,
          prompt: question.prompt,
          picture: question.picture,
          aspect: question.aspect,
          level: question.level,
          choices: question.choices,
          correctAnswerIndex: question.correctAnswerIndex!,
          answer: question.choices[index],
          correctAnswer: question.correctAnswer!,
          isCorrect: correct,
          hint: question.hint,
          correctFeedback: question.correctFeedback,
        );
      }(),
  ];
  student.completeDiagnostic(
    diagnosticId: test.id,
    classId: test.classId,
    title: test.title,
    questionSnapshots: questions,
    answers: answers,
    startedAt: DateTime(2026, 1, 1),
    finishedAt: DateTime(2026, 1, 1, 0, 1),
  );
}
