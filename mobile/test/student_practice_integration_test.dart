import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/student/practice/student_practice_pages.dart';
import 'package:mobile/features/student/student_demo_store.dart';
import 'package:mobile/features/teacher/teacher_demo_store.dart';
import 'package:mobile/app/app_session.dart';

void main() {
  final teacherStore = TeacherDemoStore.instance;
  final studentStore = StudentDemoStore.instance;

  setUp(() {
    studentStore.resetForTests();
    AppSession.startStudent(user: 101, student: 1);
  });

  test(
    'approved teacher questions are filtered for the exact material and use',
    () {
      final matchingId = teacherStore.saveQuestion(
        prompt: 'Latihan khusus materi kedua.',
        aspect: 'suku_kata',
        level: 1,
        type: 'Pilihan ganda',
        materialId: 2,
        choices: ['ka', 'ki', 'ku'],
        correctAnswerIndex: 0,
        usage: 'latihan',
      );
      final draftId = teacherStore.saveQuestion(
        prompt: 'Soal draf.',
        aspect: 'suku_kata',
        level: 1,
        type: 'Pilihan ganda',
        materialId: 2,
        choices: ['ka', 'ki'],
        correctAnswerIndex: 0,
      );
      final diagnosticOnlyId = teacherStore.saveQuestion(
        prompt: 'Khusus diagnostik.',
        aspect: 'suku_kata',
        level: 1,
        type: 'Pilihan ganda',
        materialId: 2,
        choices: ['ka', 'ki'],
        correctAnswerIndex: 0,
        usage: 'diagnostik',
      );
      final wrongLevelId = teacherStore.saveQuestion(
        prompt: 'Tingkat berbeda.',
        aspect: 'suku_kata',
        level: 2,
        type: 'Pilihan ganda',
        materialId: 2,
        choices: ['ka', 'ki'],
        correctAnswerIndex: 0,
      );

      expect(teacherStore.practiceQuestionsForMaterial(2), isEmpty);
      expect(teacherStore.setQuestionStatus(matchingId, 'disetujui'), isTrue);
      expect(
        teacherStore.setQuestionStatus(diagnosticOnlyId, 'disetujui'),
        isTrue,
      );
      expect(teacherStore.setQuestionStatus(wrongLevelId, 'disetujui'), isTrue);
      expect(
        teacherStore.practiceQuestionsForMaterial(2).map((item) => item.id),
        [matchingId],
      );
      expect(
        teacherStore
            .practiceQuestionsForMaterial(1)
            .any((item) => item.id == matchingId),
        isFalse,
      );
      expect(teacherStore.questionById(draftId)!.status, 'draf');

      teacherStore.setQuestionStatus(matchingId, 'nonaktif');
      expect(teacherStore.practiceQuestionsForMaterial(2), isEmpty);
      expect(teacherStore.deleteQuestion(matchingId), isTrue);
      expect(teacherStore.deleteQuestion(draftId), isTrue);
      expect(teacherStore.deleteQuestion(diagnosticOnlyId), isTrue);
      expect(teacherStore.deleteQuestion(wrongLevelId), isTrue);
    },
  );

  testWidgets('practice scores answers from a frozen teacher question snapshot', (
    tester,
  ) async {
    final firstId = teacherStore.saveQuestion(
      prompt: 'Soal integrasi satu.',
      aspect: 'suku_kata',
      level: 1,
      type: 'Pilihan ganda',
      materialId: 2,
      picture: '🚲',
      choices: ['ka', 'ki', 'ku'],
      correctAnswerIndex: 1,
      hint: 'Dengarkan suku kata awal.',
      correctFeedback: 'Tepat!',
      usage: 'latihan',
    );
    final secondId = teacherStore.saveQuestion(
      prompt: 'Soal integrasi dua.',
      aspect: 'suku_kata',
      level: 1,
      type: 'Pilihan ganda',
      materialId: 2,
      choices: ['ba', 'bi', 'bu'],
      correctAnswerIndex: 2,
      hint: 'Coba dengarkan lagi.',
      correctFeedback: 'Bagus!',
      usage: 'latihan',
    );
    teacherStore.setQuestionStatus(firstId, 'disetujui');
    teacherStore.setQuestionStatus(secondId, 'disetujui');

    final priorHistoryCount = studentStore.practiceHistory.length;
    final diagnosticScores = Map<String, int>.of(studentStore.diagnosticScores);
    final first = teacherStore.questionById(firstId)!;
    await tester.pumpWidget(
      MaterialApp(home: StudentExercisePage(materialId: 2)),
    );

    final firstPrompt = find.text('Soal integrasi satu.');
    final secondPrompt = find.text('Soal integrasi dua.');
    final displayedFirst = firstPrompt.evaluate().isNotEmpty
        ? first
        : teacherStore.questionById(secondId)!;
    expect(find.text('1 dari 2'), findsOneWidget);
    await tester.tap(
      find.byKey(
        ValueKey('exercise-answer-${displayedFirst.correctAnswerIndex}'),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('exercise-next')));
    await tester.pump();

    expect(find.text('2 dari 2'), findsOneWidget);
    expect(
      firstPrompt.evaluate().isNotEmpty || secondPrompt.evaluate().isNotEmpty,
      isTrue,
    );
    final remaining = displayedFirst.id == firstId
        ? teacherStore.questionById(secondId)!
        : first;
    await tester.tap(
      find.byKey(
        ValueKey(
          'exercise-answer-${(remaining.correctAnswerIndex! + 1) % remaining.choices.length}',
        ),
      ),
    );
    await tester.pump();

    teacherStore.saveQuestion(
      id: firstId,
      prompt: 'Versi edit setelah sesi mulai.',
      aspect: 'suku_kata',
      level: 1,
      type: 'Pilihan ganda',
      materialId: 2,
      choices: ['ga', 'gi', 'gu'],
      correctAnswerIndex: 2,
    );
    await tester.tap(find.byKey(const ValueKey('exercise-next')));
    await tester.pump();

    expect(find.text('50%'), findsOneWidget);
    expect(studentStore.practiceHistory.length, priorHistoryCount + 1);
    final attempt = studentStore.practiceHistory.first;
    expect(attempt.studentId, studentStore.currentStudentId);
    expect(attempt.materialId, 2);
    expect(attempt.aspect, 'suku_kata');
    expect(attempt.answers, hasLength(2));
    expect(attempt.answers.map((answer) => answer.questionId).toSet(), {
      firstId,
      secondId,
    });
    expect(attempt.correctCount, 1);
    expect(attempt.answeredQuestionCount, 2);
    expect(attempt.score, 50);
    expect(attempt.finishedAt.isAfter(attempt.startedAt), isTrue);
    expect(studentStore.diagnosticScores, diagnosticScores);
    expect(studentStore.diagnosticCompleted, isFalse);

    teacherStore.deleteQuestion(firstId);
    teacherStore.deleteQuestion(secondId);
  });

  testWidgets(
    'material without eligible questions shows empty state and records nothing',
    (tester) async {
      final priorHistoryCount = studentStore.practiceHistory.length;
      final priorScore = studentStore.lastPracticeScore;
      await tester.pumpWidget(
        const MaterialApp(home: StudentExercisePage(materialId: 2)),
      );
      expect(
        find.text(
          'Latihan untuk materi ini belum tersedia. Coba materi lain ya!',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('exercise-next')), findsNothing);
      expect(studentStore.practiceHistory.length, priorHistoryCount);
      expect(studentStore.lastPracticeScore, priorScore);
    },
  );
}
