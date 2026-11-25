import 'package:flutter/foundation.dart';

import '../../app/app_session.dart';
import '../../app/navigation_plan.dart';
import 'adaptive_learning_service.dart';
import '../teacher/teacher_demo_store.dart';

class MasteryRecord {
  const MasteryRecord({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.aspect,
    required this.level,
    this.recommendedAspect,
    this.recommendedLevel,
    required this.status,
    required this.score,
    required this.source,
    required this.sourceId,
    required this.recordedAt,
    required this.reason,
    this.needsSupport = false,
  });

  final int id;
  final int studentId;
  final int classId;
  final String aspect;

  /// The level of the completed activity (or diagnostic placement).
  final int level;

  /// The next target selected after processing this result, when one exists.
  final String? recommendedAspect;
  final int? recommendedLevel;
  final String status;
  final int score;
  final String source;
  final int sourceId;
  final DateTime recordedAt;
  final String reason;
  final bool needsSupport;
}

class LearningRecommendation {
  const LearningRecommendation({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.aspect,
    required this.level,
    required this.materialId,
    required this.source,
    required this.reason,
    required this.createdAt,
    this.status = 'aktif',
    this.teacherId,
    this.completedByAttemptId,
  });

  final int id;
  final int studentId;
  final int classId;
  final String aspect;
  final int level;
  final int materialId;
  final String source;
  final String reason;
  final DateTime createdAt;
  final String status;
  final int? teacherId;
  final int? completedByAttemptId;

  LearningRecommendation copyWith({
    String? status,
    int? completedByAttemptId,
  }) => LearningRecommendation(
    id: id,
    studentId: studentId,
    classId: classId,
    aspect: aspect,
    level: level,
    materialId: materialId,
    source: source,
    reason: reason,
    createdAt: createdAt,
    status: status ?? this.status,
    teacherId: teacherId,
    completedByAttemptId: completedByAttemptId ?? this.completedByAttemptId,
  );
}

class MaterialGapRecord {
  const MaterialGapRecord({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.aspect,
    required this.level,
    required this.createdAt,
    required this.reason,
    this.resolvedAt,
  });

  final int id;
  final int studentId;
  final int classId;
  final String aspect;
  final int level;
  final DateTime createdAt;
  final String reason;
  final DateTime? resolvedAt;

  MaterialGapRecord copyWith({DateTime? resolvedAt}) => MaterialGapRecord(
    id: id,
    studentId: studentId,
    classId: classId,
    aspect: aspect,
    level: level,
    createdAt: createdAt,
    reason: reason,
    resolvedAt: resolvedAt ?? this.resolvedAt,
  );
}

class StudentActivity {
  StudentActivity({
    required this.title,
    required this.aspect,
    required this.score,
    required this.finishedAt,
  });
  final String title;
  final String aspect;
  final int score;
  final DateTime finishedAt;
}

class PracticeAnswerRecord {
  const PracticeAnswerRecord({
    required this.questionId,
    required this.aspect,
    required this.answer,
    required this.correctAnswer,
    required this.isCorrect,
  });
  final int questionId;
  final String aspect;
  final String answer;
  final String correctAnswer;
  final bool isCorrect;
}

class PracticeAttempt {
  PracticeAttempt({
    required this.id,
    required this.attemptNumber,
    required this.studentId,
    required this.classId,
    required this.materialId,
    required this.level,
    this.recommendationId,
    required this.title,
    required this.aspect,
    required this.availableQuestionCount,
    required List<DemoQuestion> questionSnapshots,
    required List<PracticeAnswerRecord> answers,
    required this.score,
    required this.startedAt,
    required this.finishedAt,
    required this.completionToken,
    this.status = 'selesai',
  }) : questionSnapshots = List.unmodifiable(
         questionSnapshots.map((q) => q.copyWithIdAndStatus(q.id, q.status)),
       ),
       answers = List.unmodifiable(answers);
  final int id;
  final int attemptNumber;
  final int studentId;
  final int classId;
  final int materialId;
  final int level;
  final int? recommendationId;
  final String title;
  final String aspect;
  final int availableQuestionCount;
  final List<DemoQuestion> questionSnapshots;
  final List<PracticeAnswerRecord> answers;
  final int score;
  final DateTime startedAt;
  final DateTime finishedAt;
  final String completionToken;
  final String status;
  int get answeredQuestionCount => answers.length;
  int get correctCount => answers.where((answer) => answer.isCorrect).length;
}

class DiagnosticAnswerRecord {
  DiagnosticAnswerRecord({
    required this.questionId,
    required this.prompt,
    required this.picture,
    required this.aspect,
    required this.level,
    required List<String> choices,
    required this.correctAnswerIndex,
    required this.answer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.hint,
    required this.correctFeedback,
  }) : choices = List.unmodifiable(choices);
  final int questionId;
  final String prompt;
  final String picture;
  final String aspect;
  final int level;
  final List<String> choices;
  final int correctAnswerIndex;
  final String answer;
  final String correctAnswer;
  final bool isCorrect;
  final String hint;
  final String correctFeedback;
}

class DiagnosticAttempt {
  DiagnosticAttempt({
    required this.id,
    required this.attemptNumber,
    required this.studentId,
    required this.diagnosticId,
    required this.classId,
    required this.title,
    required List<DiagnosticAnswerRecord> answers,
    required Map<String, int> aspectScores,
    required this.score,
    required this.startedAt,
    required this.finishedAt,
    this.status = 'selesai',
  }) : answers = List.unmodifiable(answers),
       aspectScores = Map.unmodifiable(aspectScores);
  final int id;
  final int attemptNumber;
  final int studentId;
  final int diagnosticId;
  final int classId;
  final String title;
  final List<DiagnosticAnswerRecord> answers;
  final Map<String, int> aspectScores;
  final int score;
  final DateTime startedAt;
  final DateTime finishedAt;
  final String status;
}

class StudentDemoStore extends ChangeNotifier {
  StudentDemoStore._();
  static final instance = StudentDemoStore._();

  final _practiceHistory = <PracticeAttempt>[];
  final _diagnosticHistory = <DiagnosticAttempt>[];
  final _masteryHistory = <MasteryRecord>[];
  final _recommendationHistory = <LearningRecommendation>[];
  final _materialGapHistory = <MaterialGapRecord>[];
  final _processedDiagnosticIds = <int>{};
  final _processedPracticeIds = <int>{};
  final _dismissedSupportRecordIds = <int>{};
  final _practiceByCompletionToken = <String, PracticeAttempt>{};
  final _largerTextByStudent = <int, bool>{};
  final _recordingPreviewByStudent = <int, bool>{};
  int _practiceAttemptId = 1;
  int _diagnosticAttemptId = 1;
  int _masteryRecordId = 1;
  int _recommendationId = 1;
  int _materialGapId = 1;
  static const _adaptiveService = AdaptiveLearningService();

  int? get currentStudentId {
    if (AppSession.role != AppRole.student || AppSession.studentId == null) {
      return null;
    }
    final profile = TeacherDemoStore.instance.studentById(
      AppSession.studentId!,
    );
    return profile != null &&
            profile.active &&
            profile.userId == AppSession.userId
        ? profile.id
        : null;
  }

  DemoStudent get student {
    final id = currentStudentId;
    final profile = id == null
        ? null
        : TeacherDemoStore.instance.studentById(id);
    if (profile == null || !profile.active) {
      throw StateError('Sesi siswa tidak valid.');
    }
    return profile;
  }

  String get studentName => currentStudentId == null ? '' : student.name;
  String get className => currentStudentId == null
      ? ''
      : TeacherDemoStore.instance.className(student.classId);
  List<PracticeAttempt> get allPracticeHistory =>
      List.unmodifiable(_practiceHistory);
  List<DiagnosticAttempt> get allDiagnosticHistory =>
      List.unmodifiable(_diagnosticHistory);
  List<DiagnosticAttempt> diagnosticHistoryForTeacher(int teacherId) =>
      _diagnosticHistory
          .where(
            (attempt) => TeacherDemoStore.instance.canTeacherAccessClass(
              teacherId,
              attempt.classId,
            ),
          )
          .toList(growable: false);
  List<PracticeAttempt> get practiceHistory => _practiceHistory
      .where((a) => a.studentId == currentStudentId)
      .toList(growable: false);
  List<DiagnosticAttempt> get diagnosticHistory => _diagnosticHistory
      .where((a) => a.studentId == currentStudentId)
      .toList(growable: false);
  List<MasteryRecord> get allMasteryHistory =>
      List.unmodifiable(_masteryHistory);
  List<MasteryRecord> get masteryHistory => _masteryHistory
      .where((record) => record.studentId == currentStudentId)
      .toList(growable: false);
  List<LearningRecommendation> get allRecommendationHistory =>
      List.unmodifiable(_recommendationHistory);
  List<LearningRecommendation> get recommendationHistory =>
      _recommendationHistory
          .where((record) => record.studentId == currentStudentId)
          .toList(growable: false);
  List<MaterialGapRecord> get allMaterialGapHistory =>
      List.unmodifiable(_materialGapHistory);
  List<MaterialGapRecord> get materialGaps => _materialGapHistory
      .where((record) => record.studentId == currentStudentId)
      .toList(growable: false);
  List<MasteryRecord> masteryHistoryForTeacher(int teacherId) => _masteryHistory
      .where(
        (record) => TeacherDemoStore.instance.canTeacherAccessClass(
          teacherId,
          record.classId,
        ),
      )
      .toList(growable: false);
  List<LearningRecommendation> recommendationHistoryForTeacher(int teacherId) =>
      _recommendationHistory
          .where(
            (record) => TeacherDemoStore.instance.canTeacherAccessClass(
              teacherId,
              record.classId,
            ),
          )
          .toList(growable: false);
  List<MaterialGapRecord> materialGapsForTeacher(int teacherId) =>
      _materialGapHistory
          .where(
            (record) => TeacherDemoStore.instance.canTeacherAccessClass(
              teacherId,
              record.classId,
            ),
          )
          .where((record) => record.resolvedAt == null)
          .toList(growable: false);
  Map<String, MasteryRecord> get latestMasteryByAspect {
    final records = masteryHistory.toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return Map.unmodifiable({
      for (final record in records) record.aspect: record,
    });
  }

  Map<String, int> get masteryScores => Map.unmodifiable({
    for (final entry in latestMasteryByAspect.entries)
      entry.key: entry.value.score,
  });
  LearningRecommendation? get activeRecommendation {
    final records = recommendationHistory.where(
      (item) => item.status == 'aktif',
    );
    return records.isEmpty ? null : records.last;
  }

  List<MasteryRecord> masteryHistoryForStudent(int studentId) => _masteryHistory
      .where((record) => record.studentId == studentId)
      .toList(growable: false);
  List<LearningRecommendation> recommendationHistoryForStudent(int studentId) =>
      _recommendationHistory
          .where((record) => record.studentId == studentId)
          .toList(growable: false);
  List<MaterialGapRecord> materialGapsForStudent(int studentId) =>
      _materialGapHistory
          .where(
            (record) =>
                record.studentId == studentId && record.resolvedAt == null,
          )
          .toList(growable: false);
  List<StudentActivity> get activities => practiceHistory
      .map(
        (attempt) => StudentActivity(
          title: attempt.title,
          aspect: attempt.aspect,
          score: attempt.score,
          finishedAt: attempt.finishedAt,
        ),
      )
      .toList(growable: false);
  Map<String, int> get practiceScores =>
      _latestScores(practiceHistory.map((a) => (a.aspect, a.score)));
  Map<String, int> get diagnosticScores {
    final attempts = diagnosticHistory.toList()
      ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    return attempts.isEmpty ? const {} : attempts.first.aspectScores;
  }

  Map<String, int> get scores => diagnosticScores;
  bool get diagnosticCompleted {
    if (currentStudentId == null) return false;
    final diagnostic = TeacherDemoStore.instance.activeDiagnosticForClass(
      student.classId,
    );
    return diagnostic != null &&
        _diagnosticHistory.any(
          (a) =>
              a.studentId == currentStudentId &&
              a.diagnosticId == diagnostic.id &&
              a.status == 'selesai',
        );
  }

  bool get submittedPracticeRecording =>
      _recordingPreviewByStudent[currentStudentId] ?? false;
  int? get lastPracticeScore =>
      practiceHistory.isEmpty ? null : practiceHistory.first.score;
  String? get lastPracticeAspect =>
      practiceHistory.isEmpty ? null : practiceHistory.first.aspect;
  bool get largerText => _largerTextByStudent[currentStudentId] ?? false;
  int? get recommendedMaterialId => activeRecommendation?.materialId;

  bool get hasCompleteDiagnosticBaseline =>
      currentStudentId != null &&
      _diagnosticHistory.any(
        (attempt) =>
            attempt.studentId == currentStudentId &&
            attempt.status == 'selesai' &&
            AdaptiveLearningService.aspects.every(
              attempt.aspectScores.containsKey,
            ),
      );

  bool get hasAnyDiagnostic => diagnosticHistory.isNotEmpty;

  DiagnosticAttempt? attemptForDiagnostic(int studentId, int diagnosticId) {
    for (final attempt in _diagnosticHistory) {
      if (attempt.studentId == studentId &&
          attempt.diagnosticId == diagnosticId &&
          attempt.status == 'selesai') {
        return attempt;
      }
    }
    return null;
  }

  DiagnosticAttempt? latestDiagnosticForStudent(int studentId) {
    final items =
        _diagnosticHistory.where((a) => a.studentId == studentId).toList()
          ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    return items.isEmpty ? null : items.first;
  }

  DiagnosticAttempt? latestDiagnosticForTeacher(int teacherId, int studentId) {
    if (!TeacherDemoStore.instance.canTeacherAccessStudent(
      teacherId,
      studentId,
    )) {
      return null;
    }
    final attempts =
        diagnosticHistoryForTeacher(teacherId)
            .where((attempt) => attempt.studentId == studentId)
            .toList()
          ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    return attempts.isEmpty ? null : attempts.first;
  }

  DiagnosticAttempt? completeDiagnostic({
    required int diagnosticId,
    required int classId,
    required String title,
    required List<DemoQuestion> questionSnapshots,
    required List<DiagnosticAnswerRecord> answers,
    required DateTime startedAt,
    required DateTime finishedAt,
  }) {
    final studentId = currentStudentId;
    final profile = studentId == null
        ? null
        : TeacherDemoStore.instance.studentById(studentId);
    final tests = TeacherDemoStore.instance.diagnostics.where(
      (d) => d.id == diagnosticId,
    );
    final test = tests.isEmpty ? null : tests.first;
    if (profile == null ||
        !profile.active ||
        profile.classId != classId ||
        test == null ||
        test.status != 'aktif' ||
        test.classId != classId ||
        attemptForDiagnostic(studentId!, diagnosticId) != null) {
      return null;
    }
    if (answers.isEmpty || answers.length != questionSnapshots.length) {
      return null;
    }
    final snapshotIds = questionSnapshots.map((item) => item.id).toSet();
    if (snapshotIds.length != questionSnapshots.length ||
        answers.any((a) => !snapshotIds.contains(a.questionId)) ||
        answers.map((a) => a.questionId).toSet().length != answers.length ||
        answers.length != test.questionIds.length ||
        !snapshotIds.containsAll(test.questionIds)) {
      return null;
    }
    final submittedById = {
      for (final answer in answers) answer.questionId: answer,
    };
    final recordedAnswers = <DiagnosticAnswerRecord>[];
    for (final question in questionSnapshots) {
      final submitted = submittedById[question.id];
      final key = question.correctAnswer;
      if (submitted == null ||
          key == null ||
          !question.choices.contains(submitted.answer)) {
        return null;
      }
      recordedAnswers.add(
        DiagnosticAnswerRecord(
          questionId: question.id,
          prompt: question.prompt,
          picture: question.picture,
          aspect: question.aspect,
          level: question.level,
          choices: question.choices,
          correctAnswerIndex: question.correctAnswerIndex!,
          answer: submitted.answer,
          correctAnswer: key,
          isCorrect: submitted.answer == key,
          hint: question.hint,
          correctFeedback: question.correctFeedback,
        ),
      );
    }
    final totals = <String, int>{};
    final correct = <String, int>{};
    for (final answer in recordedAnswers) {
      totals.update(answer.aspect, (value) => value + 1, ifAbsent: () => 1);
      if (answer.isCorrect) {
        correct.update(answer.aspect, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final aspectScores = {
      for (final aspect in totals.keys)
        aspect: ((correct[aspect] ?? 0) * 100 / totals[aspect]!).round(),
    };
    final score =
        (recordedAnswers.where((a) => a.isCorrect).length *
                100 /
                recordedAnswers.length)
            .round();
    final attempt = DiagnosticAttempt(
      id: _diagnosticAttemptId++,
      attemptNumber: 1,
      studentId: studentId,
      diagnosticId: diagnosticId,
      classId: classId,
      title: title,
      answers: recordedAnswers,
      aspectScores: aspectScores,
      score: score,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );
    _diagnosticHistory.insert(0, attempt);
    _processDiagnostic(attempt);
    notifyListeners();
    return attempt;
  }

  PracticeAttempt? completePractice({
    required int materialId,
    required String title,
    required String aspect,
    required int availableQuestionCount,
    required List<DemoQuestion> questionSnapshots,
    required List<PracticeAnswerRecord> answers,
    required DateTime startedAt,
    required DateTime finishedAt,
    String? completionToken,
    int? recommendationId,
  }) {
    final studentId = currentStudentId;
    final profile = studentId == null
        ? null
        : TeacherDemoStore.instance.studentById(studentId);
    final material = TeacherDemoStore.instance.materialById(materialId);
    final normalizedToken = completionToken?.trim();
    if (profile == null ||
        !profile.active ||
        material == null ||
        material.status != 'aktif' ||
        material.aspect != aspect ||
        answers.isEmpty ||
        answers.length != questionSnapshots.length ||
        availableQuestionCount != questionSnapshots.length ||
        normalizedToken == null ||
        normalizedToken.isEmpty) {
      return null;
    }
    final tokenKey = '$studentId:$normalizedToken';
    final existing = _practiceByCompletionToken[tokenKey];
    if (existing != null) {
      return _samePracticeSubmission(
            existing,
            materialId: materialId,
            aspect: aspect,
            questionSnapshots: questionSnapshots,
            answers: answers,
            startedAt: startedAt,
            recommendationId: recommendationId,
          )
          ? existing
          : null;
    }
    final snapshotsById = {for (final q in questionSnapshots) q.id: q};
    if (snapshotsById.length != questionSnapshots.length ||
        answers.map((a) => a.questionId).toSet().length != answers.length) {
      return null;
    }
    for (final answer in answers) {
      final question = snapshotsById[answer.questionId];
      if (question == null ||
          question.materialId != materialId ||
          !question.canBeUsedFor('latihan', materials: [material]) ||
          question.aspect != aspect ||
          question.correctAnswer == null ||
          !question.choices.contains(answer.answer) ||
          answer.correctAnswer != question.correctAnswer ||
          answer.isCorrect != (answer.answer == question.correctAnswer)) {
        return null;
      }
    }
    final score =
        (answers.where((a) => a.isCorrect).length * 100 / answers.length)
            .round();
    final attempts = _practiceHistory
        .where((a) => a.studentId == studentId && a.materialId == materialId)
        .length;
    final attempt = PracticeAttempt(
      id: _practiceAttemptId++,
      attemptNumber: attempts + 1,
      studentId: studentId!,
      classId: profile.classId,
      materialId: materialId,
      level: material.level,
      recommendationId: recommendationId,
      title: title,
      aspect: aspect,
      availableQuestionCount: availableQuestionCount,
      questionSnapshots: questionSnapshots,
      answers: answers,
      score: score,
      startedAt: startedAt,
      finishedAt: finishedAt,
      completionToken: normalizedToken,
    );
    _practiceHistory.insert(0, attempt);
    _practiceByCompletionToken[tokenKey] = attempt;
    _processPractice(attempt);
    notifyListeners();
    return attempt;
  }

  bool _samePracticeSubmission(
    PracticeAttempt existing, {
    required int materialId,
    required String aspect,
    required List<DemoQuestion> questionSnapshots,
    required List<PracticeAnswerRecord> answers,
    required DateTime startedAt,
    required int? recommendationId,
  }) {
    if (existing.status != 'selesai' ||
        existing.materialId != materialId ||
        existing.aspect != aspect ||
        existing.startedAt != startedAt ||
        existing.recommendationId != recommendationId ||
        existing.questionSnapshots.length != questionSnapshots.length ||
        existing.answers.length != answers.length) {
      return false;
    }
    for (var index = 0; index < questionSnapshots.length; index++) {
      if (existing.questionSnapshots[index].id != questionSnapshots[index].id ||
          existing.answers[index].questionId != answers[index].questionId ||
          existing.answers[index].answer != answers[index].answer ||
          existing.answers[index].correctAnswer !=
              answers[index].correctAnswer ||
          existing.answers[index].isCorrect != answers[index].isCorrect) {
        return false;
      }
    }
    return true;
  }

  void _processDiagnostic(DiagnosticAttempt attempt) {
    if (!_processedDiagnosticIds.add(attempt.id) ||
        attempt.status != 'selesai' ||
        !AdaptiveLearningService.aspects.every(
          attempt.aspectScores.containsKey,
        )) {
      return;
    }
    for (final aspect in AdaptiveLearningService.aspects) {
      final score = attempt.aspectScores[aspect]!;
      final level = score < AdaptiveLearningService.practiceThreshold
          ? 1
          : score < AdaptiveLearningService.masteryThreshold
          ? 2
          : 3;
      final status = score < AdaptiveLearningService.practiceThreshold
          ? 'belum_dikuasai'
          : score < AdaptiveLearningService.masteryThreshold
          ? 'sedang_berlatih'
          : 'dikuasai';
      _masteryHistory.add(
        MasteryRecord(
          id: _masteryRecordId++,
          studentId: attempt.studentId,
          classId: attempt.classId,
          aspect: aspect,
          level: level,
          status: status,
          score: score,
          source: 'diagnostik',
          sourceId: attempt.id,
          recordedAt: attempt.finishedAt,
          reason: 'Penguasaan awal dari hasil diagnostik.',
        ),
      );
    }
    if (_activeRecommendationFor(attempt.studentId)?.source == 'guru') return;
    final decision = _adaptiveService.fromDiagnostic(
      scores: attempt.aspectScores,
      materials: _adaptiveMaterials,
      attemptedMaterialIds: _attemptedMaterialIds(attempt.studentId),
    );
    if (decision == null) {
      _closeActiveRecommendation(attempt.studentId);
      _resolveMaterialGaps(attempt.studentId, force: true);
      return;
    }
    _applySystemDecision(
      studentId: attempt.studentId,
      classId: attempt.classId,
      decision: decision,
      createdAt: attempt.finishedAt,
    );
  }

  void _processPractice(PracticeAttempt attempt) {
    if (!_processedPracticeIds.add(attempt.id) ||
        attempt.status != 'selesai' ||
        !_hasCompleteDiagnosticFor(attempt.studentId)) {
      return;
    }
    final active = _activeRecommendationFor(attempt.studentId);
    final completesActiveRecommendation =
        active != null &&
        active.id == attempt.recommendationId &&
        active.materialId == attempt.materialId;
    final teacherOverridePending =
        active?.source == 'guru' && !completesActiveRecommendation;
    if (completesActiveRecommendation) {
      _closeActiveRecommendation(
        attempt.studentId,
        completedByAttemptId: attempt.id,
      );
    }

    final previous = _practiceHistory
        .where(
          (item) =>
              item.studentId == attempt.studentId &&
              item.id != attempt.id &&
              item.status == 'selesai',
        )
        .map(
          (item) => AdaptivePracticeResult(
            studentId: item.studentId,
            aspect: item.aspect,
            level: item.level,
            materialId: item.materialId,
            score: item.score,
            finishedAt: item.finishedAt,
          ),
        )
        .toList();
    final latestMastery = _latestMasteryForStudent(attempt.studentId);
    final statusByAspect = {
      for (final entry in latestMastery.entries) entry.key: entry.value.status,
    };
    final levelByAspect = {
      for (final entry in latestMastery.entries) entry.key: entry.value.level,
    };
    final previousScores = {
      for (final entry in latestMastery.entries) entry.key: entry.value.score,
    };
    // The completed current attempt is already in the history at this point.
    final sameMaterialCount = _practiceHistory
        .where(
          (item) =>
              item.studentId == attempt.studentId &&
              item.materialId == attempt.materialId &&
              item.status == 'selesai',
        )
        .length;
    final decision = _adaptiveService.fromPractice(
      current: AdaptivePracticeResult(
        studentId: attempt.studentId,
        aspect: attempt.aspect,
        level: attempt.level,
        materialId: attempt.materialId,
        score: attempt.score,
        finishedAt: attempt.finishedAt,
      ),
      previous: previous,
      masteryStatuses: statusByAspect,
      masteryLevels: levelByAspect,
      previousAspectScores: previousScores,
      materials: _adaptiveMaterials,
      attemptedMaterialIds: _attemptedMaterialIds(attempt.studentId),
      sameMaterialAttemptCount: sameMaterialCount,
    );
    _masteryHistory.add(
      MasteryRecord(
        id: _masteryRecordId++,
        studentId: attempt.studentId,
        classId: attempt.classId,
        aspect: attempt.aspect,
        level: attempt.level,
        recommendedAspect: decision.materialId == null ? null : decision.aspect,
        recommendedLevel: decision.materialId == null ? null : decision.level,
        status: decision.masteryStatus,
        score: attempt.score,
        source: 'latihan',
        sourceId: attempt.id,
        recordedAt: attempt.finishedAt,
        reason: decision.reason,
        needsSupport: decision.needsSupport,
      ),
    );

    if (teacherOverridePending) return;
    if (decision.materialMissing) {
      _closeActiveRecommendation(attempt.studentId);
      _recordMaterialGap(
        studentId: attempt.studentId,
        classId: attempt.classId,
        aspect: decision.aspect,
        level: decision.level,
        reason: decision.reason.contains('tiga kali')
            ? 'Belum ada materi alternatif aktif pada aspek dan tingkat ini setelah tiga percobaan.'
            : 'Belum ada materi dan soal latihan aktif yang sesuai.',
        createdAt: attempt.finishedAt,
      );
    } else if (decision.materialId != null) {
      _applySystemDecision(
        studentId: attempt.studentId,
        classId: attempt.classId,
        decision: decision,
        createdAt: attempt.finishedAt,
      );
    } else {
      _closeActiveRecommendation(attempt.studentId);
      _resolveMaterialGaps(attempt.studentId, force: true);
    }
  }

  List<AdaptiveMaterial> get _adaptiveMaterials => TeacherDemoStore
      .instance
      .materials
      .where(
        (material) =>
            material.status == 'aktif' &&
            TeacherDemoStore.instance
                .practiceQuestionsForMaterial(material.id)
                .isNotEmpty,
      )
      .map(
        (material) => AdaptiveMaterial(
          id: material.id,
          aspect: material.aspect,
          level: material.level,
          title: material.title,
        ),
      )
      .toList(growable: false);

  Set<int> _attemptedMaterialIds(int studentId) => _practiceHistory
      .where((attempt) => attempt.studentId == studentId)
      .map((attempt) => attempt.materialId)
      .toSet();

  bool _hasCompleteDiagnosticFor(int studentId) => _diagnosticHistory.any(
    (attempt) =>
        attempt.studentId == studentId &&
        attempt.status == 'selesai' &&
        AdaptiveLearningService.aspects.every(attempt.aspectScores.containsKey),
  );

  Map<String, MasteryRecord> _latestMasteryForStudent(int studentId) {
    final records =
        _masteryHistory
            .where((record) => record.studentId == studentId)
            .toList()
          ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return {for (final record in records) record.aspect: record};
  }

  LearningRecommendation? _activeRecommendationFor(int studentId) {
    for (final recommendation in _recommendationHistory.reversed) {
      if (recommendation.studentId == studentId &&
          recommendation.status == 'aktif') {
        return recommendation;
      }
    }
    return null;
  }

  void _closeActiveRecommendation(int studentId, {int? completedByAttemptId}) {
    final index = _recommendationHistory.lastIndexWhere(
      (item) => item.studentId == studentId && item.status == 'aktif',
    );
    if (index >= 0) {
      _recommendationHistory[index] = _recommendationHistory[index].copyWith(
        status: 'selesai',
        completedByAttemptId: completedByAttemptId,
      );
    }
  }

  void _applySystemDecision({
    required int studentId,
    required int classId,
    required AdaptiveDecision decision,
    required DateTime createdAt,
  }) {
    _closeActiveRecommendation(studentId);
    if (decision.materialMissing || decision.materialId == null) {
      _recordMaterialGap(
        studentId: studentId,
        classId: classId,
        aspect: decision.aspect,
        level: decision.level,
        reason: 'Belum ada materi dan soal latihan aktif yang sesuai.',
        createdAt: createdAt,
      );
      return;
    }
    _resolveMaterialGaps(studentId, aspect: decision.aspect);
    _recommendationHistory.add(
      LearningRecommendation(
        id: _recommendationId++,
        studentId: studentId,
        classId: classId,
        aspect: decision.aspect,
        level: decision.level,
        materialId: decision.materialId!,
        source: 'sistem',
        reason: decision.reason,
        createdAt: createdAt,
      ),
    );
  }

  void _recordMaterialGap({
    required int studentId,
    required int classId,
    required String aspect,
    required int level,
    required String reason,
    required DateTime createdAt,
  }) {
    final alreadyOpen = _materialGapHistory.any(
      (item) =>
          item.studentId == studentId &&
          item.aspect == aspect &&
          item.level == level &&
          item.resolvedAt == null,
    );
    if (alreadyOpen) return;
    _materialGapHistory.add(
      MaterialGapRecord(
        id: _materialGapId++,
        studentId: studentId,
        classId: classId,
        aspect: aspect,
        level: level,
        createdAt: createdAt,
        reason: reason,
      ),
    );
  }

  void _resolveMaterialGaps(
    int studentId, {
    String? aspect,
    bool force = false,
  }) {
    final now = DateTime.now();
    for (var index = 0; index < _materialGapHistory.length; index++) {
      final item = _materialGapHistory[index];
      if (item.studentId == studentId &&
          item.resolvedAt == null &&
          (aspect == null || item.aspect == aspect) &&
          (force ||
              _adaptiveMaterials.any(
                (material) =>
                    material.aspect == item.aspect &&
                    material.level == item.level,
              ))) {
        _materialGapHistory[index] = item.copyWith(resolvedAt: now);
      }
    }
  }

  bool setTeacherRecommendation({
    required int studentId,
    required int materialId,
    required String reason,
  }) {
    final teacherId = AppSession.teacherId;
    if (AppSession.role != AppRole.teacher ||
        teacherId == null ||
        !TeacherDemoStore.instance.canTeacherAccessStudent(
          teacherId,
          studentId,
        )) {
      return false;
    }
    final student = TeacherDemoStore.instance.studentById(studentId);
    final material = TeacherDemoStore.instance.materialById(materialId);
    if (student == null ||
        !student.active ||
        material == null ||
        material.status != 'aktif' ||
        TeacherDemoStore.instance
            .practiceQuestionsForMaterial(materialId)
            .isEmpty ||
        reason.trim().isEmpty) {
      return false;
    }
    _closeActiveRecommendation(studentId);
    _resolveMaterialGaps(studentId, aspect: material.aspect);
    _recommendationHistory.add(
      LearningRecommendation(
        id: _recommendationId++,
        studentId: studentId,
        classId: student.classId,
        aspect: material.aspect,
        level: material.level,
        materialId: material.id,
        source: 'guru',
        reason: reason.trim(),
        createdAt: DateTime.now(),
        teacherId: teacherId,
      ),
    );
    notifyListeners();
    return true;
  }

  bool needsSupportForStudent(int studentId) =>
      masteryHistoryForStudent(studentId).any(
        (record) =>
            record.needsSupport &&
            !_dismissedSupportRecordIds.contains(record.id),
      ) ||
      (TeacherDemoStore.instance.studentById(studentId)?.needsSupport ?? false);

  bool setTeacherSupportFlag(int studentId, bool value) {
    final teacherId = AppSession.teacherId;
    if (AppSession.role != AppRole.teacher ||
        teacherId == null ||
        !TeacherDemoStore.instance.canTeacherAccessStudent(
          teacherId,
          studentId,
        )) {
      return false;
    }
    final student = TeacherDemoStore.instance.studentById(studentId);
    if (student == null) return false;
    student.needsSupport = value;
    if (!value) {
      _dismissedSupportRecordIds.addAll(
        masteryHistoryForStudent(studentId)
            .where((record) => record.needsSupport)
            .map((record) => record.id),
      );
    }
    notifyListeners();
    TeacherDemoStore.instance.notifyListeners();
    return true;
  }

  Map<String, MasteryRecord> latestMasteryForStudent(int studentId) =>
      Map.unmodifiable(_latestMasteryForStudent(studentId));

  Map<String, MasteryRecord> latestMasteryForTeacher(
    int teacherId,
    int studentId,
  ) => TeacherDemoStore.instance.canTeacherAccessStudent(teacherId, studentId)
      ? Map.unmodifiable(_latestMasteryForStudent(studentId))
      : const {};

  LearningRecommendation? activeRecommendationForStudent(int studentId) =>
      _activeRecommendationFor(studentId);

  LearningRecommendation? activeRecommendationForTeacher(
    int teacherId,
    int studentId,
  ) => TeacherDemoStore.instance.canTeacherAccessStudent(teacherId, studentId)
      ? _activeRecommendationFor(studentId)
      : null;

  List<MaterialGapRecord> materialGapsForStudentTeacher(
    int teacherId,
    int studentId,
  ) => TeacherDemoStore.instance.canTeacherAccessStudent(teacherId, studentId)
      ? materialGapsForStudent(studentId)
      : const [];

  List<LearningRecommendation> activeRecommendationsForTeacher(int teacherId) =>
      recommendationHistoryForTeacher(teacherId)
          .where((item) => item.status == 'aktif')
          .toList(growable: false);

  void submitRecordingPreview() {
    final id = currentStudentId;
    if (id == null) return;
    _recordingPreviewByStudent[id] = true;
    notifyListeners();
  }

  void toggleLargerText() {
    final id = currentStudentId;
    if (id == null) return;
    _largerTextByStudent[id] = !largerText;
    notifyListeners();
  }

  void loadAccount(Map<String, dynamic> data) {
    _clearHistory();
    int score(dynamic value) => num.parse(value.toString()).round();
    for (final r in data['practice']) {
      _practiceHistory.add(
        PracticeAttempt(
          id: r['id'],
          attemptNumber: r['attempt_number'],
          studentId: r['student_id'],
          classId: r['class_id'],
          materialId: r['material_id'] ?? 0,
          level: r['level_snapshot'],
          recommendationId: r['recommendation_id'],
          title: r['material_title_snapshot'],
          aspect: r['aspect_code'],
          availableQuestionCount: r['question_count'],
          questionSnapshots: [],
          answers: [],
          score: score(r['score']),
          startedAt: DateTime.parse(r['started_at']),
          finishedAt: DateTime.parse(r['finished_at']),
          completionToken: r['completion_token'] ?? '',
        ),
      );
    }
    for (final r in data['mastery']) {
      _masteryHistory.add(
        MasteryRecord(
          id: r['id'],
          studentId: r['student_id'],
          classId: r['class_id'],
          aspect: r['aspect_code'],
          level: r['observed_level'],
          recommendedAspect: r['target_aspect_code'],
          recommendedLevel: r['target_level'],
          status: const {
            'not_mastered': 'belum_dikuasai',
            'practicing': 'sedang_berlatih',
            'mastered': 'dikuasai',
          }[r['mastery_status']]!,
          score: score(r['score']),
          source:
              const {
                'diagnostic': 'diagnostik',
                'practice': 'latihan',
              }[r['source_type']] ??
              r['source_type'],
          sourceId:
              r['diagnostic_attempt_id'] ??
              r['practice_attempt_id'] ??
              r['audio_evaluation_revision_id'],
          recordedAt: DateTime.parse(r['recorded_at']),
          reason: r['reason'],
          needsSupport: r['needs_teacher_support'] == 1,
        ),
      );
    }
    for (final r in data['diagnostics']) {
      _diagnosticHistory.add(
        DiagnosticAttempt(
          id: r['id'],
          attemptNumber: 1,
          studentId: r['student_id'],
          diagnosticId: r['diagnostic_test_id'],
          classId: r['class_id'],
          title: r['title'],
          answers: [],
          aspectScores: {
            for (final m in _masteryHistory.where(
              (m) => m.source == 'diagnostik' && m.sourceId == r['id'],
            ))
              m.aspect: m.score,
          },
          score: score(r['overall_score']),
          startedAt: DateTime.parse(r['started_at']),
          finishedAt: DateTime.parse(r['finished_at']),
        ),
      );
    }
    for (final r in data['recommendations']) {
      _recommendationHistory.add(
        LearningRecommendation(
          id: r['id'],
          studentId: r['student_id'],
          classId: r['class_id'],
          aspect: r['aspect_code'],
          level: r['target_level'],
          materialId: r['material_id'],
          source: r['source'] == 'teacher' ? 'guru' : 'sistem',
          reason: r['reason'],
          createdAt: DateTime.parse(r['created_at']),
        ),
      );
    }
    for (final r in data['gaps']) {
      _materialGapHistory.add(
        MaterialGapRecord(
          id: r['id'],
          studentId: r['student_id'],
          classId: r['class_id'],
          aspect: r['aspect_code'],
          level: r['target_level'],
          createdAt: DateTime.parse(r['created_at']),
          reason: r['reason'],
        ),
      );
    }
    notifyListeners();
  }

  @visibleForTesting
  void resetForTests() {
    _clearHistory();
    notifyListeners();
  }

  void _clearHistory() {
    _practiceHistory.clear();
    _diagnosticHistory.clear();
    _masteryHistory.clear();
    _recommendationHistory.clear();
    _materialGapHistory.clear();
    _processedDiagnosticIds.clear();
    _processedPracticeIds.clear();
    _practiceByCompletionToken.clear();
    _dismissedSupportRecordIds.clear();
    _largerTextByStudent.clear();
    _recordingPreviewByStudent.clear();
    _practiceAttemptId = 1;
    _diagnosticAttemptId = 1;
    _masteryRecordId = 1;
    _recommendationId = 1;
    _materialGapId = 1;
  }

  Map<String, int> _latestScores(Iterable<(String, int)> values) {
    final result = <String, int>{};
    for (final (aspect, score) in values) {
      result.putIfAbsent(aspect, () => score);
    }
    return Map.unmodifiable(result);
  }
}
