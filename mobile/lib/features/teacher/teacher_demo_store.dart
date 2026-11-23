import 'package:flutter/foundation.dart';

import '../../app/app_session.dart';

class DemoClass {
  DemoClass({
    required this.id,
    required this.name,
    required this.grade,
    required this.year,
    this.teacherId = 1,
  });

  final int id;
  String name;
  int grade;
  String year;
  final int teacherId;
}

class DemoStudent {
  DemoStudent({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    this.password = 'demo',
    required this.classId,
    required this.guardianName,
    required this.parentConsent,
    required this.aiConsent,
    this.active = true,
    this.needsSupport = false,
  });

  final int id;
  final int userId;
  String name;
  String username;
  String password;
  int classId;
  String guardianName;
  bool parentConsent;
  bool aiConsent;
  bool active;
  bool needsSupport;
}

class DemoMaterial {
  DemoMaterial({
    required this.id,
    required this.title,
    required this.aspect,
    required this.level,
    required this.content,
    this.status = 'aktif',
    this.fromAi = false,
  });

  final int id;
  String title;
  String aspect;
  int level;
  String content;
  String status;
  bool fromAi;
}

class DemoQuestion {
  DemoQuestion({
    required this.id,
    required this.prompt,
    required this.aspect,
    required this.level,
    required this.type,
    this.materialId,
    this.picture = '',
    List<String> choices = const [],
    this.correctAnswerIndex,
    this.hint = '',
    this.correctFeedback = '',
    this.targetText,
    this.usage = 'keduanya',
    this.status = 'draf',
  }) : choices = List.unmodifiable(choices);

  final int id;
  final int? materialId;
  final String picture;
  final String prompt;
  final String aspect;
  final int level;
  final String type;
  final List<String> choices;
  final int? correctAnswerIndex;
  final String hint;
  final String correctFeedback;
  final String? targetText;
  final String usage;
  String status;

  static const validAspects = {'huruf', 'suku_kata', 'kata', 'kalimat'};
  static const validTypes = {'Pilihan ganda', 'Baca lisan'};
  static const validUsages = {'latihan', 'diagnostik', 'keduanya'};
  static const validStatuses = {'draf', 'disetujui', 'ditolak', 'nonaktif'};

  String? get correctAnswer =>
      correctAnswerIndex != null &&
          correctAnswerIndex! >= 0 &&
          correctAnswerIndex! < choices.length
      ? choices[correctAnswerIndex!]
      : null;

  bool get hasValidAnswer =>
      validationIssues(materials: TeacherDemoStore.instance.materials).isEmpty;

  List<String> validationIssues({Iterable<DemoMaterial> materials = const []}) {
    final issues = <String>[];
    if (prompt.trim().isEmpty) issues.add('Pertanyaan harus diisi.');
    if (!validAspects.contains(aspect)) issues.add('Aspek soal tidak valid.');
    if (level < 1 || level > 3) {
      issues.add('Tingkat kesulitan harus 1 sampai 3.');
    }
    if (!validUsages.contains(usage)) {
      issues.add('Penggunaan soal tidak valid.');
    }
    if (!validTypes.contains(type)) {
      issues.add('Jenis soal tidak valid.');
      return issues;
    }

    if (materialId != null) {
      DemoMaterial? material;
      for (final item in materials) {
        if (item.id == materialId) {
          material = item;
          break;
        }
      }
      if (material == null) {
        issues.add('Materi yang dipilih tidak ditemukan.');
      } else if (material.aspect != aspect) {
        issues.add('Aspek soal harus sama dengan aspek materi.');
      } else if (material.status != 'aktif') {
        issues.add('Materi terkait belum aktif.');
      }
    }

    if (type == 'Pilihan ganda') {
      if (choices.length < 2) {
        issues.add('Pilihan ganda memerlukan sedikitnya dua pilihan.');
      }
      if (choices.any((choice) => choice.trim().isEmpty)) {
        issues.add('Semua pilihan jawaban harus diisi.');
      }
      final normalizedChoices = choices
          .map(
            (choice) =>
                choice.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
          )
          .where((choice) => choice.isNotEmpty)
          .toList();
      if (normalizedChoices.toSet().length != normalizedChoices.length) {
        issues.add('Pilihan jawaban tidak boleh duplikat.');
      }
      if (correctAnswer == null) {
        issues.add('Pilih kunci jawaban dari pilihan yang tersedia.');
      } else if (_promptContainsAnswer(prompt, correctAnswer!)) {
        issues.add('Pertanyaan tidak boleh menampilkan kunci jawaban.');
      }
    } else if (targetText?.trim().isEmpty ?? true) {
      issues.add('Soal baca lisan memerlukan teks target.');
    }
    return issues;
  }

  bool canBeUsedFor(
    String intendedUse, {
    Iterable<DemoMaterial> materials = const [],
  }) =>
      status == 'disetujui' &&
      (usage == intendedUse || usage == 'keduanya') &&
      validationIssues(materials: materials).isEmpty;

  DemoQuestion withStatus(String value) => DemoQuestion(
    id: id,
    materialId: materialId,
    picture: picture,
    prompt: prompt,
    aspect: aspect,
    level: level,
    type: type,
    choices: List.unmodifiable(choices),
    correctAnswerIndex: correctAnswerIndex,
    hint: hint,
    correctFeedback: correctFeedback,
    targetText: targetText,
    usage: usage,
    status: value,
  );

  DemoQuestion copyWithIdAndStatus(int value, String nextStatus) =>
      DemoQuestion(
        id: value,
        materialId: materialId,
        picture: picture,
        prompt: prompt,
        aspect: aspect,
        level: level,
        type: type,
        choices: choices,
        correctAnswerIndex: correctAnswerIndex,
        hint: hint,
        correctFeedback: correctFeedback,
        targetText: targetText,
        usage: usage,
        status: nextStatus,
      );

  static bool _promptContainsAnswer(String text, String answer) {
    final promptWords = text.toLowerCase().split(RegExp(r'[^a-z0-9]+'));
    final answerWords = answer
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (answerWords.isEmpty || answerWords.length > promptWords.length) {
      return false;
    }
    for (
      var start = 0;
      start <= promptWords.length - answerWords.length;
      start++
    ) {
      var matches = true;
      for (var offset = 0; offset < answerWords.length; offset++) {
        if (promptWords[start + offset] != answerWords[offset]) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }
}

class DemoDiagnostic {
  DemoDiagnostic({
    required this.id,
    required this.title,
    required this.classId,
    required this.questionIds,
    this.status = 'draf',
  });

  final int id;
  String title;
  int classId;
  List<int> questionIds;
  String status;
}

class DemoRecording {
  DemoRecording({
    required this.id,
    required this.studentId,
    required this.targetText,
    required this.aspect,
    required this.durationSeconds,
    required this.parentConsent,
    required this.aiConsent,
    this.status = 'terkirim',
    this.accuracyScore,
    this.fluencyScore,
    this.comment = '',
    this.advice = '',
  });

  final int id;
  final int studentId;
  final String targetText;
  final String aspect;
  final int durationSeconds;
  final bool parentConsent;
  final bool aiConsent;
  String status;
  int? accuracyScore;
  int? fluencyScore;
  String comment;
  String advice;

  bool get aiAllowed => aiConsent && (aspect == 'kata' || aspect == 'kalimat');
  int? get simulatedAiSimilarity => aiAllowed ? (id.isEven ? 84 : 90) : null;
}

String aspectLabel(String aspect) => switch (aspect) {
  'huruf' => 'Huruf',
  'suku_kata' => 'Suku kata',
  'kata' => 'Kata',
  'kalimat' => 'Kalimat sederhana',
  _ => aspect,
};

String masteryLabel(int score) => score < 60
    ? 'Belum dikuasai'
    : score < 80
    ? 'Sedang berlatih'
    : 'Dikuasai';

String masterySummaryFor(Map<String, int>? scores) {
  if (scores == null || scores.isEmpty) return 'Belum didiagnostik';
  final lowest = scores.entries.reduce((a, b) => a.value <= b.value ? a : b);
  return '${aspectLabel(lowest.key)} ${masteryLabel(lowest.value)}';
}

final class TeacherDemoStore extends ChangeNotifier {
  static final instance = TeacherDemoStore._();

  TeacherDemoStore._();

  final classes = <DemoClass>[
    DemoClass(id: 1, name: '1A', grade: 1, year: '2026/2027'),
    DemoClass(id: 2, name: '2A', grade: 2, year: '2026/2027'),
    DemoClass(id: 3, name: '3A', grade: 3, year: '2026/2027'),
  ];

  final students = <DemoStudent>[
    DemoStudent(
      id: 1,
      userId: 101,
      name: 'Andi Pratama',
      username: 'andi.1a',
      classId: 1,
      guardianName: 'Bapak Pratama',
      parentConsent: true,
      aiConsent: true,
      needsSupport: true,
    ),
    DemoStudent(
      id: 2,
      userId: 102,
      name: 'Siti Aisyah',
      username: 'siti.1a',
      classId: 1,
      guardianName: 'Ibu Aminah',
      parentConsent: true,
      aiConsent: false,
    ),
    DemoStudent(
      id: 3,
      userId: 103,
      name: 'Bunga Lestari',
      username: 'bunga.2a',
      classId: 2,
      guardianName: 'Ibu Lestari',
      parentConsent: false,
      aiConsent: false,
    ),
    DemoStudent(
      id: 4,
      userId: 104,
      name: 'Dimas Saputra',
      username: 'dimas.3a',
      classId: 3,
      guardianName: 'Bapak Saputra',
      parentConsent: true,
      aiConsent: true,
    ),
  ];

  final materials = <DemoMaterial>[
    DemoMaterial(
      id: 1,
      title: 'Suku kata ba bi bu be bo',
      aspect: 'suku_kata',
      level: 1,
      content: 'ba • bi • bu • be • bo\nContoh: ba-ju • bo-la • bu-ku',
    ),
    DemoMaterial(
      id: 2,
      title: 'Suku kata ka ki ku ke ko',
      aspect: 'suku_kata',
      level: 1,
      content: 'ka • ki • ku • ke • ko\nContoh: ka-ki • ku-da • ko-pi',
    ),
    DemoMaterial(
      id: 3,
      title: 'Kata di sekitar kita',
      aspect: 'kata',
      level: 1,
      content: 'Baca kata sampai selesai: buku • bola • meja',
    ),
    DemoMaterial(
      id: 4,
      title: 'Kalimat sederhana',
      aspect: 'kalimat',
      level: 2,
      content: 'Ibu membeli bola.\nBaca kata satu per satu.',
    ),
    DemoMaterial(
      id: 5,
      title: 'Mengenal huruf vokal',
      aspect: 'huruf',
      level: 1,
      content: 'a • i • u • e • o\nContoh: ayam • ikan • ular • ember • obat',
    ),
  ];

  final questions = <DemoQuestion>[
    DemoQuestion(
      id: 1,
      prompt: 'Pilih huruf awal nama gambar.',
      aspect: 'huruf',
      level: 1,
      type: 'Pilihan ganda',
      picture: '👕',
      choices: ['b', 'd', 'm'],
      correctAnswerIndex: 0,
      hint: 'Sebutkan nama bendanya, lalu dengarkan bunyi paling awal.',
      correctFeedback: 'Tepat! Kamu menemukan bunyi huruf awalnya.',
      status: 'disetujui',
    ),
    DemoQuestion(
      id: 2,
      prompt: 'Pilih suku kata awal nama gambar.',
      aspect: 'suku_kata',
      level: 1,
      type: 'Pilihan ganda',
      materialId: 1,
      picture: '⚽',
      choices: ['bo', 'bu', 'ba'],
      correctAnswerIndex: 0,
      status: 'disetujui',
    ),
    DemoQuestion(
      id: 3,
      prompt: 'Bacalah kata ini: bola',
      aspect: 'kata',
      level: 1,
      type: 'Baca lisan',
      materialId: 3,
      targetText: 'bola',
      status: 'disetujui',
    ),
    DemoQuestion(
      id: 4,
      prompt: 'Bacalah kalimat: Ibu membeli bola',
      aspect: 'kalimat',
      level: 1,
      type: 'Baca lisan',
      materialId: 4,
      targetText: 'Ibu membeli bola',
      status: 'disetujui',
    ),
    DemoQuestion(
      id: 5,
      prompt: 'Pilih huruf awal nama gambar.',
      aspect: 'huruf',
      level: 2,
      type: 'Pilihan ganda',
      materialId: 5,
      picture: '🪑',
      choices: ['k', 'm', 's'],
      correctAnswerIndex: 0,
      status: 'disetujui',
    ),
    DemoQuestion(
      id: 6,
      prompt: 'Baca kata: meja',
      aspect: 'kata',
      level: 2,
      type: 'Baca lisan',
      materialId: 3,
      targetText: 'meja',
      status: 'disetujui',
    ),
    DemoQuestion(
      id: 7,
      prompt: 'Pilih huruf vokal awal nama gambar.',
      aspect: 'huruf',
      level: 1,
      type: 'Pilihan ganda',
      materialId: 5,
      picture: '🐟',
      choices: ['i', 'a', 'e'],
      correctAnswerIndex: 0,
      hint: 'Ucapkan nama gambar perlahan dan dengarkan vokal awalnya.',
      correctFeedback: 'Tepat! Kamu menemukan huruf vokal awalnya.',
      status: 'disetujui',
    ),
    DemoQuestion(
      id: 8,
      prompt: 'Pilih kata yang cocok dengan gambar.',
      aspect: 'kata',
      level: 1,
      type: 'Pilihan ganda',
      materialId: 3,
      picture: '📖',
      choices: ['buku', 'baju', 'bola'],
      correctAnswerIndex: 0,
      hint: 'Baca setiap pilihan sampai selesai.',
      correctFeedback: 'Tepat! Kamu mencocokkan kata dan gambar.',
      status: 'disetujui',
    ),
    DemoQuestion(
      id: 9,
      prompt: 'Kalimat mana yang sesuai dengan gambar?',
      aspect: 'kalimat',
      level: 1,
      type: 'Pilihan ganda',
      materialId: 4,
      picture: '👩‍🍳',
      choices: ['Ibu makan nasi.', 'Ibu memasak nasi.', 'Ibu membaca buku.'],
      correctAnswerIndex: 1,
      hint: 'Amati kegiatan pada gambar, lalu baca kalimatnya.',
      correctFeedback: 'Benar! Kalimatmu sesuai dengan gambar.',
      status: 'disetujui',
    ),
  ];

  final diagnostics = <DemoDiagnostic>[
    DemoDiagnostic(
      id: 1,
      title: 'Diagnostik Awal Kelas 1A',
      classId: 1,
      questionIds: [1, 2, 8, 9],
      status: 'aktif',
    ),
    DemoDiagnostic(
      id: 2,
      title: 'Cek Kemajuan Kelas 2A',
      classId: 2,
      questionIds: [1, 2, 8, 9],
      status: 'draf',
    ),
  ];

  final recordings = <DemoRecording>[
    DemoRecording(
      id: 1,
      studentId: 1,
      targetText: 'bola',
      aspect: 'kata',
      durationSeconds: 6,
      parentConsent: true,
      aiConsent: true,
    ),
    DemoRecording(
      id: 2,
      studentId: 2,
      targetText: 'Ibu membeli bola.',
      aspect: 'kalimat',
      durationSeconds: 9,
      parentConsent: true,
      aiConsent: false,
    ),
  ];

  final Map<int, int> _recommendations = {1: 1, 2: 3};

  String teacherName = 'Rina Marlina';
  String teacherEmail = 'rina@example.sch.id';
  int audioRetentionDays = 90;
  int _studentId = 5;
  int _userId = 105;
  int _classId = 4;
  int _materialId = 6;
  int _questionId = 10;
  int _diagnosticId = 3;

  DemoStudent? studentById(int id) =>
      _firstOrNull(students, (item) => item.id == id);
  DemoStudent? studentByUsername(String username) => _firstOrNull(
    students,
    (item) => item.username.toLowerCase() == username.trim().toLowerCase(),
  );
  bool authenticateTeacher(String username, String password) =>
      username.trim() == 'guru-demo' && password == 'demo';
  bool authenticateStudent(String username, String password) {
    final student = studentByUsername(username);
    return student != null && student.active && student.password == password;
  }

  DemoClass? classById(int id) =>
      _firstOrNull(classes, (item) => item.id == id);
  DemoMaterial? materialById(int id) =>
      _firstOrNull(materials, (item) => item.id == id);
  DemoQuestion? questionById(int id) =>
      _firstOrNull(questions, (item) => item.id == id);
  bool questionIsReferenced(int id) =>
      diagnostics.any((test) => test.questionIds.contains(id));

  String className(int id) => classById(id)?.name ?? 'Kelas tidak ditemukan';

  List<DemoClass> classesForTeacher(int teacherId) =>
      classes.where((item) => item.teacherId == teacherId).toList();
  List<DemoClass> get accessibleClasses => AppSession.teacherId == null
      ? const []
      : classesForTeacher(AppSession.teacherId!);
  List<DemoStudent> studentsForTeacher(int teacherId) => students
      .where((item) => canTeacherAccessStudent(teacherId, item.id))
      .toList();
  List<DemoStudent> get accessibleStudents => AppSession.teacherId == null
      ? const []
      : studentsForTeacher(AppSession.teacherId!);
  List<DemoDiagnostic> get accessibleDiagnostics => AppSession.teacherId == null
      ? const []
      : diagnostics
            .where(
              (item) =>
                  canTeacherAccessClass(AppSession.teacherId!, item.classId),
            )
            .toList();
  List<DemoRecording> get accessibleRecordings => AppSession.teacherId == null
      ? const []
      : recordings
            .where(
              (item) => canTeacherAccessStudent(
                AppSession.teacherId!,
                item.studentId,
              ),
            )
            .toList();
  bool canTeacherAccessClass(int teacherId, int classId) =>
      classById(classId)?.teacherId == teacherId;
  bool canTeacherAccessStudent(int teacherId, int studentId) {
    final student = studentById(studentId);
    return student != null && canTeacherAccessClass(teacherId, student.classId);
  }

  List<DemoQuestion> practiceQuestionsForMaterial(int materialId) {
    final material = materialById(materialId);
    if (material == null || material.status != 'aktif') return const [];
    return questions
        .where(
          (question) =>
              question.materialId == material.id &&
              question.aspect == material.aspect &&
              question.level == material.level &&
              question.type == 'Pilihan ganda' &&
              question.canBeUsedFor('latihan', materials: materials),
        )
        .toList(growable: false);
  }

  List<DemoStudent> get activeStudents {
    final teacherId = AppSession.teacherId;
    if (teacherId == null) return const [];
    return studentsForTeacher(teacherId).where((item) => item.active).toList();
  }

  int get pendingRecordingCount =>
      accessibleRecordings.where((item) => item.status == 'terkirim').length;
  int? recommendationFor(int studentId) => _recommendations[studentId];

  int? get demoTeacherId => 1;

  void saveStudent({
    int? id,
    required String name,
    required String username,
    String? password,
    required int classId,
    required String guardianName,
    required bool parentConsent,
    required bool aiConsent,
  }) {
    final teacherId = AppSession.teacherId;
    if (teacherId == null || !canTeacherAccessClass(teacherId, classId)) return;
    if (id == null) {
      students.add(
        DemoStudent(
          id: _studentId++,
          userId: _userId++,
          name: name,
          username: username,
          password: password ?? 'demo',
          classId: classId,
          guardianName: guardianName,
          parentConsent: parentConsent,
          aiConsent: parentConsent && aiConsent,
        ),
      );
    } else {
      if (!canTeacherAccessStudent(teacherId, id)) return;
      final student = studentById(id)!;
      student
        ..name = name
        ..username = username
        ..password = password ?? student.password
        ..classId = classId
        ..guardianName = guardianName
        ..parentConsent = parentConsent
        ..aiConsent = parentConsent && aiConsent;
    }
    notifyListeners();
  }

  void toggleStudentActive(int id) {
    final teacherId = AppSession.teacherId;
    if (teacherId == null || !canTeacherAccessStudent(teacherId, id)) return;
    studentById(id)?.active = !(studentById(id)?.active ?? false);
    notifyListeners();
  }

  void toggleStudentSupport(int id) {
    final teacherId = AppSession.teacherId;
    if (teacherId == null || !canTeacherAccessStudent(teacherId, id)) return;
    final student = studentById(id);
    if (student != null) student.needsSupport = !student.needsSupport;
    notifyListeners();
  }

  void saveClass({int? id, required String name, required int grade}) {
    final teacherId = AppSession.teacherId;
    if (teacherId == null) return;
    if (id == null) {
      classes.add(
        DemoClass(
          id: _classId++,
          name: name,
          grade: grade,
          year: '2026/2027',
          teacherId: teacherId,
        ),
      );
    } else {
      if (!canTeacherAccessClass(teacherId, id)) return;
      final item = classById(id)!;
      item
        ..name = name
        ..grade = grade;
    }
    notifyListeners();
  }

  void deleteClass(int id) {
    final teacherId = AppSession.teacherId;
    if (teacherId == null || !canTeacherAccessClass(teacherId, id)) return;
    if (students.any((item) => item.classId == id)) return;
    classes.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void saveMaterial({
    int? id,
    required String title,
    required String aspect,
    required int level,
    required String content,
    bool fromAi = false,
  }) {
    if (id == null) {
      materials.add(
        DemoMaterial(
          id: _materialId++,
          title: title,
          aspect: aspect,
          level: level,
          content: content,
          status: fromAi ? 'draf' : 'aktif',
          fromAi: fromAi,
        ),
      );
    } else {
      final item = materialById(id)!;
      item
        ..title = title
        ..aspect = aspect
        ..level = level
        ..content = content;
    }
    notifyListeners();
  }

  void setMaterialStatus(int id, String status) {
    materialById(id)?.status = status;
    notifyListeners();
  }

  void addQuestion({
    required String prompt,
    required String aspect,
    required int level,
    required String type,
    int? materialId,
    String picture = '',
    List<String> choices = const [],
    int? correctAnswerIndex,
    String hint = '',
    String correctFeedback = '',
    String? targetText,
    String usage = 'keduanya',
    bool draft = true,
  }) => saveQuestion(
    prompt: prompt,
    aspect: aspect,
    level: level,
    type: type,
    materialId: materialId,
    picture: picture,
    choices: choices,
    correctAnswerIndex: correctAnswerIndex,
    hint: hint,
    correctFeedback: correctFeedback,
    targetText: targetText,
    usage: usage,
    status: draft ? 'draf' : 'disetujui',
  );

  int saveQuestion({
    int? id,
    required String prompt,
    required String aspect,
    required int level,
    required String type,
    int? materialId,
    String picture = '',
    List<String> choices = const [],
    int? correctAnswerIndex,
    String hint = '',
    String correctFeedback = '',
    String? targetText,
    String usage = 'keduanya',
    String status = 'draf',
  }) {
    final current = id == null ? null : questionById(id);
    final isReferenced = id != null && questionIsReferenced(id);
    final savedId = current == null || isReferenced ? _questionId++ : id!;
    final safeStatus =
        DemoQuestion.validStatuses.contains(status) && status != 'disetujui'
        ? status
        : 'draf';
    final updated = DemoQuestion(
      id: savedId,
      prompt: prompt.trim(),
      aspect: aspect,
      level: level,
      type: type,
      materialId: materialId,
      picture: picture,
      choices: choices.map((choice) => choice.trim()).toList(),
      correctAnswerIndex: correctAnswerIndex,
      hint: hint.trim(),
      correctFeedback: correctFeedback.trim(),
      targetText: targetText?.trim(),
      usage: usage,
      status: safeStatus,
    );
    if (savedId == id && current != null) {
      questions[questions.indexOf(current)] = updated;
    } else {
      questions.add(updated);
    }
    notifyListeners();
    return savedId;
  }

  bool setQuestionStatus(int id, String status) {
    final question = questionById(id);
    if (question == null || !DemoQuestion.validStatuses.contains(status)) {
      return false;
    }
    if (status == 'disetujui' &&
        question.validationIssues(materials: materials).isNotEmpty) {
      return false;
    }
    if (questionIsReferenced(id)) {
      if (question.status == status) return true;
      questions.add(question.copyWithIdAndStatus(_questionId++, status));
      notifyListeners();
      return true;
    }
    questions[questions.indexOf(question)] = question.withStatus(status);
    notifyListeners();
    return true;
  }

  bool deleteQuestion(int id) {
    if (diagnostics.any((test) => test.questionIds.contains(id))) return false;
    questions.removeWhere((item) => item.id == id);
    notifyListeners();
    return true;
  }

  void setRecommendation(int studentId, int materialId) {
    final teacherId = AppSession.teacherId;
    if (teacherId == null || !canTeacherAccessStudent(teacherId, studentId)) {
      return;
    }
    _recommendations[studentId] = materialId;
    notifyListeners();
  }

  void addDiagnostic({
    required String title,
    required int classId,
    required List<int> questionIds,
  }) {
    final teacherId = AppSession.teacherId;
    if (teacherId == null || !canTeacherAccessClass(teacherId, classId)) return;
    diagnostics.add(
      DemoDiagnostic(
        id: _diagnosticId++,
        title: title,
        classId: classId,
        questionIds: questionIds,
      ),
    );
    notifyListeners();
  }

  DemoDiagnostic? activeDiagnosticForClass(int classId) {
    final active =
        diagnostics
            .where((item) => item.classId == classId && item.status == 'aktif')
            .toList()
          ..sort((a, b) => b.id.compareTo(a.id));
    return active.isEmpty ? null : active.first;
  }

  List<DemoQuestion> diagnosticQuestionsFor(DemoDiagnostic diagnostic) {
    if (diagnostic.status != 'aktif' ||
        diagnosticValidationIssues(diagnostic.id).isNotEmpty) {
      return const [];
    }
    final snapshots = <DemoQuestion>[];
    for (final id in diagnostic.questionIds) {
      final question = questionById(id);
      if (question == null) return const [];
      snapshots.add(question.copyWithIdAndStatus(id, question.status));
    }
    return List.unmodifiable(snapshots);
  }

  List<String> diagnosticValidationIssues(int id) {
    final test = _firstOrNull(diagnostics, (item) => item.id == id);
    if (test == null) return ['Tes diagnostik tidak ditemukan.'];
    final issues = <String>[];
    if (test.title.trim().isEmpty) issues.add('Nama tes harus diisi.');
    if (test.questionIds.isEmpty) issues.add('Pilih soal untuk tes ini.');
    if (test.questionIds.toSet().length != test.questionIds.length) {
      issues.add('Daftar soal tidak boleh berisi ID duplikat.');
    }
    final classItem = classById(test.classId);
    if (classItem == null) {
      issues.add('Kelas tes tidak ditemukan.');
    }
    final selected = <DemoQuestion>[];
    for (final questionId in test.questionIds) {
      final question = questionById(questionId);
      if (question == null) {
        issues.add('Soal ID $questionId tidak ditemukan.');
        continue;
      }
      selected.add(question);
      final validation = question.validationIssues(materials: materials);
      if (question.status != 'disetujui') {
        issues.add(
          'Soal "${question.prompt}" belum disetujui atau tidak aktif.',
        );
      }
      if (validation.isNotEmpty) {
        issues.add(
          'Soal "${question.prompt}" tidak valid: ${validation.join(' ')}',
        );
      }
      if (question.usage != 'diagnostik' && question.usage != 'keduanya') {
        issues.add(
          'Soal "${question.prompt}" tidak ditujukan untuk diagnostik.',
        );
      }
      if (question.type != 'Pilihan ganda') {
        issues.add('Soal lisan belum dapat dinilai pada tahap ini.');
      }
      if (classItem != null && question.level > classItem.grade) {
        issues.add(
          'Tingkat soal "${question.prompt}" melebihi tingkat kelas ${classItem.name}.',
        );
      }
    }
    const aspects = {'huruf', 'suku_kata', 'kata', 'kalimat'};
    final selectedAspects = selected.map((item) => item.aspect).toSet();
    final missing = aspects.difference(selectedAspects);
    if (missing.isNotEmpty) {
      issues.add(
        'Tes harus mencakup empat aspek. Aspek belum ada: ${missing.map(aspectLabel).join(', ')}.',
      );
    }
    return issues;
  }

  bool activateDiagnostic(int id) {
    final test = _firstOrNull(diagnostics, (item) => item.id == id);
    final teacherId = AppSession.teacherId;
    if (test == null ||
        teacherId == null ||
        !canTeacherAccessClass(teacherId, test.classId)) {
      return false;
    }
    if (diagnosticValidationIssues(id).isNotEmpty) {
      return false;
    }
    test.status = 'aktif';
    notifyListeners();
    return true;
  }

  void saveEvaluation({
    required int recordingId,
    required int accuracy,
    required int fluency,
    required String comment,
    required String advice,
  }) {
    final teacherId = AppSession.teacherId;
    if (teacherId == null) return;
    final recording = _firstOrNull(
      recordings,
      (item) => item.id == recordingId,
    );
    if (recording == null ||
        !canTeacherAccessStudent(teacherId, recording.studentId)) {
      return;
    }
    recording
      ..accuracyScore = accuracy
      ..fluencyScore = fluency
      ..comment = comment
      ..advice = advice
      ..status = 'dievaluasi';
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String email,
    required int retentionDays,
  }) {
    teacherName = name;
    teacherEmail = email;
    audioRetentionDays = retentionDays;
    notifyListeners();
  }
}

T? _firstOrNull<T>(Iterable<T> values, bool Function(T) test) {
  for (final value in values) {
    if (test(value)) return value;
  }
  return null;
}
