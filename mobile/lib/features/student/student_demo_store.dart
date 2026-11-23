import 'package:flutter/foundation.dart';

import '../../app/app_session.dart';
import '../../app/navigation_plan.dart';
import '../teacher/teacher_demo_store.dart';

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
    required this.title,
    required this.aspect,
    required this.availableQuestionCount,
    required List<DemoQuestion> questionSnapshots,
    required List<PracticeAnswerRecord> answers,
    required this.score,
    required this.startedAt,
    required this.finishedAt,
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
  final String title;
  final String aspect;
  final int availableQuestionCount;
  final List<DemoQuestion> questionSnapshots;
  final List<PracticeAnswerRecord> answers;
  final int score;
  final DateTime startedAt;
  final DateTime finishedAt;
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
  final _largerTextByStudent = <int, bool>{};
  final _recordingPreviewByStudent = <int, bool>{};
  int _practiceAttemptId = 1;
  int _diagnosticAttemptId = 1;

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
  int? get recommendedMaterialId => currentStudentId == null
      ? null
      : TeacherDemoStore.instance.recommendationFor(currentStudentId!);

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
        aspect: (correct[aspect]! * 100 / totals[aspect]!).round(),
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
  }) {
    final studentId = currentStudentId;
    final profile = studentId == null
        ? null
        : TeacherDemoStore.instance.studentById(studentId);
    final material = TeacherDemoStore.instance.materialById(materialId);
    if (profile == null ||
        !profile.active ||
        material == null ||
        material.status != 'aktif' ||
        material.aspect != aspect ||
        answers.isEmpty ||
        answers.length != questionSnapshots.length ||
        availableQuestionCount != questionSnapshots.length) {
      return null;
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
      title: title,
      aspect: aspect,
      availableQuestionCount: availableQuestionCount,
      questionSnapshots: questionSnapshots,
      answers: answers,
      score: score,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );
    _practiceHistory.insert(0, attempt);
    notifyListeners();
    return attempt;
  }

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

  @visibleForTesting
  void resetForTests() {
    _practiceHistory.clear();
    _diagnosticHistory.clear();
    _largerTextByStudent.clear();
    _recordingPreviewByStudent.clear();
    _practiceAttemptId = 1;
    _diagnosticAttemptId = 1;
    notifyListeners();
  }

  Map<String, int> _latestScores(Iterable<(String, int)> values) {
    final result = <String, int>{};
    for (final (aspect, score) in values) {
      result.putIfAbsent(aspect, () => score);
    }
    return Map.unmodifiable(result);
  }
}
