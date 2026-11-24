import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app_session.dart';
import 'package:mobile/features/student/student_demo_store.dart';
import 'package:mobile/features/teacher/teacher_demo_store.dart';

void main() {
  final teacher = TeacherDemoStore.instance;
  final store = StudentDemoStore.instance;

  setUp(() {
    store.resetForTests();
    AppSession.startStudent(user: 101, student: 1);
  });

  test('no diagnostic produces no seeded or adaptive recommendation', () {
    expect(store.recommendedMaterialId, isNull);
    expect(store.masteryHistory, isEmpty);
    expect(store.recommendationHistory, isEmpty);
  });

  test('complete diagnostic creates four append-only mastery records', () {
    final result = _submitDiagnostic(
      store,
      teacher,
      correctAspects: const {'huruf', 'suku_kata', 'kata', 'kalimat'},
    );

    expect(result, isNotNull);
    expect(store.diagnosticHistory, hasLength(1));
    expect(store.practiceHistory, isEmpty);
    expect(store.masteryHistory, hasLength(4));
    expect(store.masteryHistory.map((record) => record.source).toSet(), {
      'diagnostik',
    });
    expect(store.recommendedMaterialId, isNull);
  });

  test('failed diagnostic prioritizes the first unmastered aspect', () {
    _submitDiagnostic(store, teacher);
    final recommendation = store.activeRecommendation!;

    expect(recommendation.aspect, 'huruf');
    expect(recommendation.level, 1);
    expect(recommendation.materialId, 5);
    expect(recommendation.source, 'sistem');
    expect(store.masteryHistory, hasLength(4));
  });

  test(
    'practice adapts, preserves old records, and promotes after two highs',
    () {
      final alternative = _addActiveMaterial(teacher);
      _submitDiagnostic(store, teacher);
      final firstRecommended = store.activeRecommendation!;
      final firstQuestion = teacher
          .practiceQuestionsForMaterial(firstRecommended.materialId)
          .first;
      _completePractice(store, teacher, firstQuestion, correct: true);

      expect(store.recommendationHistory, hasLength(2));
      expect(store.recommendationHistory.first.status, 'selesai');
      expect(store.activeRecommendation?.materialId, alternative);
      expect(store.activeRecommendation?.reason, contains('Nilai sudah baik'));

      final secondQuestion = teacher
          .practiceQuestionsForMaterial(alternative)
          .first;
      final nextLevelMaterial = _addActiveMaterial(teacher, level: 2);
      _completePractice(store, teacher, secondQuestion, correct: true);
      expect(store.practiceHistory, hasLength(2));
      expect(store.masteryHistory, hasLength(6));
      expect(store.masteryHistory.last.source, 'latihan');
      expect(store.masteryHistory.last.level, 1);
      expect(store.masteryHistory.last.recommendedLevel, 2);
      expect(store.masteryHistory.last.recommendedAspect, 'huruf');
      expect(store.activeRecommendation?.aspect, 'huruf');
      expect(store.activeRecommendation?.level, 2);
      expect(store.activeRecommendation?.materialId, nextLevelMaterial);
      expect(store.recommendationHistory, hasLength(3));
    },
  );

  test(
    'three low level-one attempts flag support without repeating forever',
    () {
      final alternative = _addActiveMaterial(teacher);
      _submitDiagnostic(store, teacher);

      final unfinishedQuestion = teacher.practiceQuestionsForMaterial(5).first;
      expect(
        _completePractice(
          store,
          teacher,
          unfinishedQuestion,
          correct: false,
          omitCompletionToken: true,
        ),
        isNull,
      );
      expect(store.practiceHistory, isEmpty);

      for (var index = 0; index < 3; index++) {
        final materialId = store.activeRecommendation!.materialId;
        final question = teacher.practiceQuestionsForMaterial(materialId).first;
        _completePractice(store, teacher, question, correct: false);
        expect(
          store.activeRecommendation?.materialId,
          index < 2 ? 5 : alternative,
        );
      }

      expect(store.practiceHistory, hasLength(3));
      expect(store.needsSupportForStudent(1), isTrue);
      expect(store.activeRecommendation?.materialId, alternative);
      expect(store.activeRecommendation?.materialId, isNot(5));
      expect(store.materialGaps, isEmpty);
    },
  );

  test(
    'three low level-one results flag support and a missing-material gap',
    () {
      _submitDiagnostic(store, teacher);
      for (var index = 0; index < 3; index++) {
        final question = teacher.practiceQuestionsForMaterial(5).first;
        _completePractice(store, teacher, question, correct: false);
      }
      expect(store.needsSupportForStudent(1), isTrue);
      expect(store.activeRecommendation, isNull);
      expect(store.materialGaps, hasLength(1));
      expect(store.materialGaps.single.aspect, 'huruf');
      expect(store.masteryHistory.last.status, 'belum_dikuasai');
    },
  );

  test(
    'level two low streak records completed level and lower target separately',
    () {
      final levelTwoMaterial = _addActiveMaterial(teacher, level: 2);
      _submitDiagnostic(store, teacher);

      for (var index = 0; index < 3; index++) {
        final question = teacher
            .practiceQuestionsForMaterial(levelTwoMaterial)
            .first;
        _completePractice(store, teacher, question, correct: false);
      }

      final latest = store.masteryHistory.last;
      expect(latest.level, 2);
      expect(latest.recommendedLevel, 1);
      expect(latest.status, 'belum_dikuasai');
      expect(store.activeRecommendation?.level, 1);
      expect(store.needsSupportForStudent(1), isFalse);
    },
  );

  test('replayed practice completion token is processed only once', () {
    _submitDiagnostic(store, teacher);
    final question = teacher.practiceQuestionsForMaterial(5).first;
    final first = _completePractice(
      store,
      teacher,
      question,
      correct: true,
      completionToken: 'exercise-unique-1',
    );
    final replay = _completePractice(
      store,
      teacher,
      question,
      correct: true,
      completionToken: 'exercise-unique-1',
      startedAt: first!.startedAt,
      recommendationIdOverride: first.recommendationId,
    );
    expect(replay?.id, first.id);
    expect(store.practiceHistory, hasLength(1));
    expect(store.masteryHistory, hasLength(5));
    expect(store.recommendationHistory, hasLength(1));
  });

  test(
    'same token with changed answer is rejected, new session is recorded',
    () {
      _submitDiagnostic(store, teacher);
      final question = teacher.practiceQuestionsForMaterial(5).first;
      final first = _completePractice(
        store,
        teacher,
        question,
        correct: true,
        completionToken: 'stable-session',
      )!;
      final changedPayload = _completePractice(
        store,
        teacher,
        question,
        correct: false,
        completionToken: 'stable-session',
        startedAt: first.startedAt,
        recommendationIdOverride: first.recommendationId,
      );
      expect(changedPayload, isNull);
      expect(store.practiceHistory, hasLength(1));
      expect(store.masteryHistory, hasLength(5));
      final sameTokenNewSession = _completePractice(
        store,
        teacher,
        question,
        correct: true,
        completionToken: 'stable-session',
        startedAt: first.startedAt.add(const Duration(minutes: 5)),
        recommendationIdOverride: first.recommendationId,
      );
      expect(sameTokenNewSession, isNull);
      expect(store.practiceHistory, hasLength(1));

      final secondSession = _completePractice(
        store,
        teacher,
        question,
        correct: false,
        completionToken: 'another-session',
        startedAt: first.startedAt.add(const Duration(minutes: 5)),
      );
      expect(secondSession, isNotNull);
      expect(store.practiceHistory, hasLength(2));
      expect(store.masteryHistory, hasLength(6));
    },
  );

  test('completion without a token is rejected and has no side effects', () {
    _submitDiagnostic(store, teacher);
    final recommendationId = store.activeRecommendation!.id;
    final question = teacher.practiceQuestionsForMaterial(5).first;
    final result = _completePractice(
      store,
      teacher,
      question,
      correct: true,
      omitCompletionToken: true,
    );
    expect(result, isNull);
    expect(store.practiceHistory, isEmpty);
    expect(store.masteryHistory, hasLength(4));
    expect(store.activeRecommendation?.id, recommendationId);
  });

  test('diagnostic between high practices does not break practice streak', () {
    final alternative = _addActiveMaterial(teacher);
    final nextLevel = _addActiveMaterial(teacher, level: 2);
    _submitDiagnostic(store, teacher);
    final firstQuestion = teacher.practiceQuestionsForMaterial(5).first;
    _completePractice(store, teacher, firstQuestion, correct: true);

    final sourceTest = teacher.diagnostics.firstWhere((item) => item.id == 1);
    final interleavedTest = DemoDiagnostic(
      id: 2001,
      title: 'Diagnostik lanjutan',
      classId: sourceTest.classId,
      questionIds: sourceTest.questionIds,
      status: 'aktif',
    );
    teacher.diagnostics.add(interleavedTest);
    addTearDown(() => teacher.diagnostics.remove(interleavedTest));
    final questions = teacher.diagnosticQuestionsFor(interleavedTest);
    final answers = [
      for (final question in questions)
        _diagnosticAnswer(question, correct: true),
    ];
    expect(
      store.completeDiagnostic(
        diagnosticId: interleavedTest.id,
        classId: interleavedTest.classId,
        title: interleavedTest.title,
        questionSnapshots: questions,
        answers: answers,
        startedAt: DateTime(2026, 1, 1, 0, 3, 10),
        finishedAt: DateTime(2026, 1, 1, 0, 3, 20),
      ),
      isNotNull,
    );

    _completePractice(
      store,
      teacher,
      teacher.practiceQuestionsForMaterial(alternative).first,
      correct: true,
    );
    expect(store.activeRecommendation?.materialId, nextLevel);
    expect(store.activeRecommendation?.level, 2);
  });

  test(
    'teacher override is scoped, reasoned, and held until its exercise ends',
    () {
      final alternative = _addActiveMaterial(teacher);
      final replacement = _addActiveMaterial(teacher);
      final foreignClass = DemoClass(
        id: 99,
        name: '4A',
        grade: 4,
        year: '2026/2027',
        teacherId: 2,
      );
      final foreignStudent = DemoStudent(
        id: 99,
        userId: 999,
        name: 'Siswa luar',
        username: 'siswa.luar',
        classId: 99,
        guardianName: 'Wali',
        parentConsent: false,
        aiConsent: false,
      );
      teacher.classes.add(foreignClass);
      teacher.students.add(foreignStudent);
      addTearDown(() {
        teacher.classes.remove(foreignClass);
        teacher.students.remove(foreignStudent);
      });
      _submitDiagnostic(store, teacher);
      final openedRecommendationId = store.activeRecommendation!.id;
      AppSession.startTeacher(user: 1, teacher: 1);

      expect(
        store.setTeacherRecommendation(
          studentId: 99,
          materialId: alternative,
          reason: 'Materi ini lebih sesuai dengan pembelajaran di kelas.',
        ),
        isFalse,
      );
      expect(
        store.setTeacherRecommendation(
          studentId: 1,
          materialId: alternative,
          reason: 'Mulai dengan contoh yang sudah dibahas bersama.',
        ),
        isTrue,
      );
      expect(
        store.setTeacherRecommendation(
          studentId: 1,
          materialId: replacement,
          reason: 'Gunakan contoh yang baru disiapkan.',
        ),
        isTrue,
      );
      final override = store.activeRecommendationForTeacher(1, 1)!;
      expect(override.source, 'guru');
      expect(override.teacherId, 1);
      expect(override.reason, isNotEmpty);

      AppSession.startStudent(user: 101, student: 1);
      final wrongMaterialQuestion = teacher
          .practiceQuestionsForMaterial(alternative)
          .first;
      _completePractice(
        store,
        teacher,
        wrongMaterialQuestion,
        correct: false,
        recommendationIdOverride: override.id,
      );
      expect(store.activeRecommendation?.id, override.id);

      final originalQuestion = teacher.practiceQuestionsForMaterial(5).first;
      _completePractice(
        store,
        teacher,
        originalQuestion,
        correct: false,
        recommendationIdOverride: openedRecommendationId,
      );
      expect(store.activeRecommendation?.id, override.id);

      final overrideQuestion = teacher
          .practiceQuestionsForMaterial(replacement)
          .first;
      _completePractice(store, teacher, overrideQuestion, correct: false);
      expect(store.activeRecommendation?.id, isNot(override.id));
      expect(
        store.recommendationHistory
            .firstWhere((item) => item.id == override.id)
            .completedByAttemptId,
        store.practiceHistory.first.id,
      );
    },
  );

  test('incomplete diagnostic does not create mastery or recommendations', () {
    final questionIds = [1, 2, 8];
    final diagnostic = DemoDiagnostic(
      id: 1001,
      title: 'Diagnostik tanpa kalimat',
      classId: 1,
      questionIds: questionIds,
      status: 'aktif',
    );
    teacher.diagnostics.add(diagnostic);
    addTearDown(() => teacher.diagnostics.remove(diagnostic));
    final questions = questionIds
        .map((id) => teacher.questionById(id)!)
        .toList();
    final answers = [
      for (final question in questions)
        _diagnosticAnswer(question, correct: true),
    ];

    expect(
      store.completeDiagnostic(
        diagnosticId: diagnostic.id,
        classId: 1,
        title: diagnostic.title,
        questionSnapshots: questions,
        answers: answers,
        startedAt: DateTime(2026, 1, 1),
        finishedAt: DateTime(2026, 1, 1, 0, 1),
      ),
      isNotNull,
    );
    expect(store.diagnosticScores.keys, isNot(contains('kalimat')));
    expect(store.masteryHistory, isEmpty);
    expect(store.recommendedMaterialId, isNull);
  });

  test('student histories and recommendations stay isolated by identity', () {
    _submitDiagnostic(store, teacher);
    final studentOneRecommendation = store.activeRecommendation;
    AppSession.startStudent(user: 102, student: 2);
    expect(store.masteryHistory, isEmpty);
    expect(store.recommendedMaterialId, isNull);
    _submitDiagnostic(
      store,
      teacher,
      correctAspects: const {'huruf', 'suku_kata', 'kata', 'kalimat'},
    );
    expect(store.activeRecommendation, isNull);
    AppSession.startStudent(user: 101, student: 1);
    expect(store.activeRecommendation?.id, studentOneRecommendation?.id);
  });
}

int _addActiveMaterial(TeacherDemoStore teacher, {int level = 1}) {
  teacher.saveMaterial(
    title: 'Huruf awal tambahan',
    aspect: 'huruf',
    level: level,
    content: 'Latihan bunyi awal.',
  );
  final material = teacher.materials.last;
  final questionId = teacher.saveQuestion(
    prompt: 'Pilih huruf awal pada gambar.',
    aspect: 'huruf',
    level: level,
    type: 'Pilihan ganda',
    materialId: material.id,
    picture: 'tas',
    choices: const ['t', 'b', 'm'],
    correctAnswerIndex: 0,
    usage: 'latihan',
  );
  teacher.setQuestionStatus(questionId, 'disetujui');
  addTearDown(() {
    teacher.deleteQuestion(questionId);
    teacher.materials.remove(material);
  });
  return material.id;
}

DiagnosticAttempt? _submitDiagnostic(
  StudentDemoStore store,
  TeacherDemoStore teacher, {
  Set<String> correctAspects = const {},
}) {
  final test = teacher.diagnostics.firstWhere((item) => item.id == 1);
  final questions = teacher.diagnosticQuestionsFor(test);
  final answers = [
    for (final question in questions)
      _diagnosticAnswer(
        question,
        correct: correctAspects.contains(question.aspect),
      ),
  ];
  return store.completeDiagnostic(
    diagnosticId: test.id,
    classId: test.classId,
    title: test.title,
    questionSnapshots: questions,
    answers: answers,
    startedAt: DateTime(2026, 1, 1),
    finishedAt: DateTime(2026, 1, 1, 0, 1),
  );
}

DiagnosticAnswerRecord _diagnosticAnswer(
  DemoQuestion question, {
  required bool correct,
}) {
  final selectedIndex = correct
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
    answer: question.choices[selectedIndex],
    correctAnswer: question.correctAnswer!,
    isCorrect: correct,
    hint: question.hint,
    correctFeedback: question.correctFeedback,
  );
}

PracticeAttempt? _completePractice(
  StudentDemoStore store,
  TeacherDemoStore teacher,
  DemoQuestion question, {
  required bool correct,
  String? completionToken,
  DateTime? startedAt,
  int? recommendationIdOverride,
  bool omitCompletionToken = false,
}) {
  final material = teacher.materialById(question.materialId!)!;
  final recommendation = store.activeRecommendation;
  final answer = correct
      ? question.correctAnswer!
      : question.choices[(question.correctAnswerIndex! + 1) %
            question.choices.length];
  final sessionStart =
      startedAt ??
      DateTime(
        2026,
        1,
        1,
        0,
        2,
      ).add(Duration(minutes: store.practiceHistory.length * 2));
  final sessionToken = omitCompletionToken
      ? null
      : completionToken ??
            'test-session-${sessionStart.microsecondsSinceEpoch}';
  return store.completePractice(
    materialId: material.id,
    title: material.title,
    aspect: material.aspect,
    availableQuestionCount: 1,
    questionSnapshots: [question],
    answers: [
      PracticeAnswerRecord(
        questionId: question.id,
        aspect: question.aspect,
        answer: answer,
        correctAnswer: question.correctAnswer!,
        isCorrect: correct,
      ),
    ],
    startedAt: sessionStart,
    finishedAt: sessionStart.add(const Duration(minutes: 1)),
    completionToken: sessionToken,
    recommendationId:
        recommendationIdOverride ??
        (recommendation?.materialId == material.id ? recommendation?.id : null),
  );
}
