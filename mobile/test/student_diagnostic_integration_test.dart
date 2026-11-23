import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app_session.dart';
import 'package:mobile/features/student/diagnostic/student_diagnostic_page.dart';
import 'package:mobile/features/student/student_demo_store.dart';
import 'package:mobile/features/teacher/diagnostics/diagnostics_pages.dart';
import 'package:mobile/features/teacher/teacher_demo_store.dart';

void main() {
  final teacher = TeacherDemoStore.instance;
  final student = StudentDemoStore.instance;

  setUp(() {
    student.resetForTests();
    AppSession.startStudent(user: 101, student: 1);
  });

  test(
    'student receives only questions selected for the active class test',
    () {
      final active = teacher.activeDiagnosticForClass(1)!;
      final snapshots = teacher.diagnosticQuestionsFor(active);

      expect(active.id, 1);
      expect(snapshots.map((question) => question.id), active.questionIds);
      expect(snapshots.map((question) => question.aspect).toSet(), {
        'huruf',
        'suku_kata',
        'kata',
        'kalimat',
      });
      expect(teacher.activeDiagnosticForClass(2), isNull);
      expect(teacher.diagnosticQuestionsFor(teacher.diagnostics.last), isEmpty);
    },
  );

  test('invalid diagnostic selection cannot be activated or delivered', () {
    final invalid = DemoDiagnostic(
      id: 1001,
      title: 'Tes tidak lengkap',
      classId: 1,
      questionIds: [1, 1, 999],
    );
    teacher.diagnostics.add(invalid);
    addTearDown(() => teacher.diagnostics.remove(invalid));

    final issues = teacher.diagnosticValidationIssues(invalid.id);
    expect(issues.join(' '), contains('duplikat'));
    expect(issues.join(' '), contains('tidak ditemukan'));
    expect(teacher.activateDiagnostic(invalid.id), isFalse);
    expect(teacher.diagnosticQuestionsFor(invalid), isEmpty);
  });

  testWidgets(
    'class without an active test shows empty state without a result',
    (tester) async {
      final diagnostic = teacher.activeDiagnosticForClass(1)!;
      final priorStatus = diagnostic.status;
      final priorHistoryCount = student.diagnosticHistory.length;
      diagnostic.status = 'nonaktif';
      addTearDown(() => diagnostic.status = priorStatus);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StudentDiagnosticPage())),
      );

      expect(
        find.text(
          'Belum ada tes diagnostik yang tersedia untuk kelasmu. Tunggu Bapak/Ibu Guru ya!',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('diagnostic-next')), findsNothing);
      expect(student.diagnosticHistory, hasLength(priorHistoryCount));
    },
  );

  testWidgets('diagnostic scores the selected frozen questions only', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final diagnostic = teacher.activeDiagnosticForClass(1)!;
    final beforePractice = student.practiceHistory.length;
    final beforeHistory = student.diagnosticHistory.length;
    final beforePracticeScores = Map<String, int>.of(student.practiceScores);
    final snapshots = teacher.diagnosticQuestionsFor(diagnostic);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StudentDiagnosticPage())),
    );
    expect(find.text(diagnostic.title), findsOneWidget);
    for (var index = 0; index < snapshots.length; index++) {
      final question = snapshots[index];
      expect(find.text(question.prompt), findsOneWidget);
      expect(find.text(question.picture), findsOneWidget);
      await tester.tap(
        find.byKey(
          ValueKey('diagnostic-answer-${question.correctAnswerIndex}'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('diagnostic-next')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('diagnostic-next')));
      await tester.pumpAndSettle();
    }

    expect(find.text('Tes selesai! 🎉'), findsOneWidget);
    expect(student.diagnosticHistory, hasLength(beforeHistory + 1));
    final attempt = student.diagnosticHistory.first;
    expect(attempt.diagnosticId, diagnostic.id);
    expect(attempt.studentId, student.currentStudentId);
    expect(attempt.classId, 1);
    expect(
      attempt.answers.map((answer) => answer.questionId),
      diagnostic.questionIds,
    );
    expect(attempt.answers.every((answer) => answer.isCorrect), isTrue);
    expect(attempt.score, 100);
    expect(attempt.aspectScores.values, everyElement(100));
    expect(attempt.startedAt.isBefore(attempt.finishedAt), isTrue);
    expect(student.practiceHistory, hasLength(beforePractice));
    expect(student.diagnosticScores, attempt.aspectScores);
    expect(student.practiceScores, beforePracticeScores);
  });

  test(
    'question edits do not rewrite diagnostic versions or prior attempts',
    () {
      final diagnostic = teacher.activeDiagnosticForClass(1)!;
      final snapshots = teacher.diagnosticQuestionsFor(diagnostic);
      final original = snapshots.first;
      final storedCount = teacher.questions.length;
      final replacementId = teacher.saveQuestion(
        id: original.id,
        prompt: 'Pilih huruf awal nama benda pada gambar.',
        aspect: original.aspect,
        level: original.level,
        type: original.type,
        choices: ['b', 'd', 'm'],
        correctAnswerIndex: 0,
      );
      addTearDown(() {
        teacher.deleteQuestion(replacementId);
      });

      expect(replacementId, isNot(original.id));
      expect(teacher.questions, hasLength(storedCount + 1));
      expect(
        teacher.diagnosticQuestionsFor(diagnostic).first.prompt,
        original.prompt,
      );
      expect(snapshots.first.choices, original.choices);
    },
  );

  testWidgets(
    'a completed diagnostic cannot be recorded again for the same student and test',
    (tester) async {
      final diagnostic = teacher.activeDiagnosticForClass(1)!;
      final snapshots = teacher.diagnosticQuestionsFor(diagnostic);
      final before = student.diagnosticHistory.length;
      final first = _submitAttempt(
        student,
        diagnostic.id,
        snapshots,
        DateTime(2026, 1, 1),
      );
      final duplicate = _submitAttempt(
        student,
        diagnostic.id,
        snapshots,
        DateTime(2026, 1, 2),
      );
      final unknown = _submitAttempt(
        student,
        999,
        snapshots,
        DateTime(2026, 1, 3),
      );

      final thisTest = student.diagnosticHistory
          .where((attempt) => attempt.diagnosticId == diagnostic.id)
          .toList();
      expect(first, isNotNull);
      expect(duplicate, isNull);
      expect(unknown, isNull);
      expect(thisTest, hasLength(1));
      expect(student.diagnosticHistory, hasLength(before + 1));

      AppSession.startTeacher(user: 1, teacher: 1);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticResultsPage(diagnosticId: diagnostic.id),
          ),
        ),
      );
      expect(find.text(diagnostic.title), findsOneWidget);
      expect(find.text('Andi Pratama'), findsOneWidget);
      expect(find.text('100'), findsWidgets);
      expect(find.text('75'), findsNothing);
    },
  );

  test('an unfinished diagnostic cannot create a result', () {
    final snapshots = teacher.diagnosticQuestionsFor(
      teacher.activeDiagnosticForClass(1)!,
    );
    final before = student.diagnosticHistory.length;
    final result = student.completeDiagnostic(
      diagnosticId: 1,
      classId: 1,
      title: 'Diagnostik Awal Kelas 1A',
      questionSnapshots: snapshots,
      answers: const [],
      startedAt: DateTime(2026),
      finishedAt: DateTime(2026, 1, 1),
    );
    expect(result, isNull);
    expect(student.diagnosticHistory, hasLength(before));
  });
}

DiagnosticAttempt? _submitAttempt(
  StudentDemoStore store,
  int diagnosticId,
  List<DemoQuestion> questions,
  DateTime startedAt,
) {
  final answers = [
    for (final question in questions)
      DiagnosticAnswerRecord(
        questionId: question.id,
        prompt: question.prompt,
        picture: question.picture,
        aspect: question.aspect,
        level: question.level,
        choices: question.choices,
        correctAnswerIndex: question.correctAnswerIndex!,
        answer: question.correctAnswer!,
        correctAnswer: question.correctAnswer!,
        isCorrect: true,
        hint: question.hint,
        correctFeedback: question.correctFeedback,
      ),
  ];
  return store.completeDiagnostic(
    diagnosticId: diagnosticId,
    classId: 1,
    title: 'Tes $diagnosticId',
    questionSnapshots: questions,
    answers: answers,
    startedAt: startedAt,
    finishedAt: startedAt.add(const Duration(minutes: 1)),
  );
}
