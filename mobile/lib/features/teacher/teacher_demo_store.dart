import 'package:flutter/foundation.dart';

class DemoClass {
  DemoClass({
    required this.id,
    required this.name,
    required this.grade,
    required this.year,
  });

  final int id;
  String name;
  int grade;
  String year;
}

class DemoStudent {
  DemoStudent({
    required this.id,
    required this.name,
    required this.username,
    required this.classId,
    required this.guardianName,
    required this.parentConsent,
    required this.aiConsent,
    this.active = true,
    this.needsSupport = false,
    this.scores,
  });

  final int id;
  String name;
  String username;
  int classId;
  String guardianName;
  bool parentConsent;
  bool aiConsent;
  bool active;
  bool needsSupport;
  Map<String, int>? scores;

  String get masterySummary {
    if (scores == null) return 'Belum didiagnostik';
    final lowest = scores!.entries.reduce((a, b) => a.value <= b.value ? a : b);
    return '${aspectLabel(lowest.key)} ${masteryLabel(lowest.value)}';
  }
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
    this.status = 'disetujui',
  });

  final int id;
  String prompt;
  String aspect;
  int level;
  String type;
  String status;
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
      name: 'Andi Pratama',
      username: 'andi.1a',
      classId: 1,
      guardianName: 'Bapak Pratama',
      parentConsent: true,
      aiConsent: true,
      needsSupport: true,
      scores: {'huruf': 100, 'suku_kata': 0, 'kata': 70, 'kalimat': 60},
    ),
    DemoStudent(
      id: 2,
      name: 'Siti Aisyah',
      username: 'siti.1a',
      classId: 1,
      guardianName: 'Ibu Aminah',
      parentConsent: true,
      aiConsent: false,
      scores: {'huruf': 80, 'suku_kata': 75, 'kata': 55, 'kalimat': 45},
    ),
    DemoStudent(
      id: 3,
      name: 'Bunga Lestari',
      username: 'bunga.2a',
      classId: 2,
      guardianName: 'Ibu Lestari',
      parentConsent: false,
      aiConsent: false,
    ),
    DemoStudent(
      id: 4,
      name: 'Dimas Saputra',
      username: 'dimas.3a',
      classId: 3,
      guardianName: 'Bapak Saputra',
      parentConsent: true,
      aiConsent: true,
      scores: {'huruf': 95, 'suku_kata': 88, 'kata': 82, 'kalimat': 70},
    ),
  ];

  final materials = <DemoMaterial>[
    DemoMaterial(
      id: 1,
      title: 'Suku kata ba bi bu be bo',
      aspect: 'suku_kata',
      level: 1,
      content: 'ba bi bu be bo',
    ),
    DemoMaterial(
      id: 2,
      title: 'Suku kata ka ki ku ke ko',
      aspect: 'suku_kata',
      level: 1,
      content: 'ka ki ku ke ko',
    ),
    DemoMaterial(
      id: 3,
      title: 'Kata di sekitar kita',
      aspect: 'kata',
      level: 1,
      content: 'buku • bola • meja',
    ),
    DemoMaterial(
      id: 4,
      title: 'Kalimat sederhana',
      aspect: 'kalimat',
      level: 2,
      content: 'Ibu membeli bola.',
    ),
    DemoMaterial(
      id: 5,
      title: 'Mengenal huruf vokal',
      aspect: 'huruf',
      level: 1,
      content: 'a • i • u • e • o',
    ),
  ];

  final questions = <DemoQuestion>[
    DemoQuestion(
      id: 1,
      prompt: 'Pilih huruf yang kamu dengar: “b”',
      aspect: 'huruf',
      level: 1,
      type: 'Pilihan ganda',
    ),
    DemoQuestion(
      id: 2,
      prompt: 'Pilih suku kata: “bu”',
      aspect: 'suku_kata',
      level: 1,
      type: 'Pilihan ganda',
    ),
    DemoQuestion(
      id: 3,
      prompt: 'Bacalah kata ini: bola',
      aspect: 'kata',
      level: 1,
      type: 'Baca lisan',
    ),
    DemoQuestion(
      id: 4,
      prompt: 'Bacalah kalimat: Ibu membeli bola',
      aspect: 'kalimat',
      level: 1,
      type: 'Baca lisan',
    ),
    DemoQuestion(
      id: 5,
      prompt: 'Pilih huruf awal kata mata',
      aspect: 'huruf',
      level: 2,
      type: 'Pilihan ganda',
    ),
    DemoQuestion(
      id: 6,
      prompt: 'Baca kata: meja',
      aspect: 'kata',
      level: 2,
      type: 'Baca lisan',
    ),
  ];

  final diagnostics = <DemoDiagnostic>[
    DemoDiagnostic(
      id: 1,
      title: 'Diagnostik Awal Kelas 1A',
      classId: 1,
      questionIds: [1, 2, 3, 4],
      status: 'aktif',
    ),
    DemoDiagnostic(
      id: 2,
      title: 'Cek Kemajuan Kelas 2A',
      classId: 2,
      questionIds: [1, 2, 3, 4],
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
  int _classId = 4;
  int _materialId = 6;
  int _questionId = 7;
  int _diagnosticId = 3;

  DemoStudent? studentById(int id) =>
      _firstOrNull(students, (item) => item.id == id);
  DemoClass? classById(int id) =>
      _firstOrNull(classes, (item) => item.id == id);
  DemoMaterial? materialById(int id) =>
      _firstOrNull(materials, (item) => item.id == id);

  String className(int id) => classById(id)?.name ?? 'Kelas tidak ditemukan';

  List<DemoStudent> get activeStudents =>
      students.where((item) => item.active).toList();
  List<DemoStudent> get diagnosticStudents =>
      students.where((item) => item.scores != null).toList();
  int get completedDiagnosticCount => diagnosticStudents.length;
  int get pendingRecordingCount =>
      recordings.where((item) => item.status == 'terkirim').length;
  int? recommendationFor(int studentId) => _recommendations[studentId];

  void saveStudent({
    int? id,
    required String name,
    required String username,
    required int classId,
    required String guardianName,
    required bool parentConsent,
    required bool aiConsent,
  }) {
    if (id == null) {
      students.add(
        DemoStudent(
          id: _studentId++,
          name: name,
          username: username,
          classId: classId,
          guardianName: guardianName,
          parentConsent: parentConsent,
          aiConsent: parentConsent && aiConsent,
        ),
      );
    } else {
      final student = studentById(id)!;
      student
        ..name = name
        ..username = username
        ..classId = classId
        ..guardianName = guardianName
        ..parentConsent = parentConsent
        ..aiConsent = parentConsent && aiConsent;
    }
    notifyListeners();
  }

  void toggleStudentActive(int id) {
    studentById(id)?.active = !(studentById(id)?.active ?? false);
    notifyListeners();
  }

  void toggleStudentSupport(int id) {
    final student = studentById(id);
    if (student != null) student.needsSupport = !student.needsSupport;
    notifyListeners();
  }

  void saveClass({int? id, required String name, required int grade}) {
    if (id == null) {
      classes.add(
        DemoClass(id: _classId++, name: name, grade: grade, year: '2026/2027'),
      );
    } else {
      final item = classById(id)!;
      item
        ..name = name
        ..grade = grade;
    }
    notifyListeners();
  }

  void deleteClass(int id) {
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
    bool draft = false,
  }) {
    questions.add(
      DemoQuestion(
        id: _questionId++,
        prompt: prompt,
        aspect: aspect,
        level: level,
        type: type,
        status: draft ? 'draf' : 'disetujui',
      ),
    );
    notifyListeners();
  }

  void setQuestionStatus(int id, String status) {
    for (final question in questions) {
      if (question.id == id) question.status = status;
    }
    notifyListeners();
  }

  bool deleteQuestion(int id) {
    if (diagnostics.any((test) => test.questionIds.contains(id))) return false;
    questions.removeWhere((item) => item.id == id);
    notifyListeners();
    return true;
  }

  void setRecommendation(int studentId, int materialId) {
    _recommendations[studentId] = materialId;
    notifyListeners();
  }

  void addDiagnostic({
    required String title,
    required int classId,
    required List<int> questionIds,
  }) {
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

  bool activateDiagnostic(int id) {
    final test = diagnostics.firstWhere((item) => item.id == id);
    final aspects = questions
        .where((item) => test.questionIds.contains(item.id))
        .map((item) => item.aspect)
        .toSet();
    if (!['huruf', 'suku_kata', 'kata', 'kalimat'].every(aspects.contains)) {
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
    final recording = recordings.firstWhere((item) => item.id == recordingId);
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
