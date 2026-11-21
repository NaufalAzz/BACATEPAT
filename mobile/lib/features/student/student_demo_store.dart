import 'package:flutter/foundation.dart';

import '../teacher/teacher_demo_store.dart';

class StudentActivity {
  StudentActivity({
    required this.title,
    required this.aspect,
    required this.score,
  });

  final String title;
  final String aspect;
  final int score;
}

class StudentDemoStore extends ChangeNotifier {
  StudentDemoStore._();

  static final instance = StudentDemoStore._();

  static const studentId = 1;

  final activities = <StudentActivity>[
    StudentActivity(title: 'Ayo baca ba bi bu', aspect: 'suku_kata', score: 60),
    StudentActivity(title: 'Kata di sekitar kita', aspect: 'kata', score: 70),
    StudentActivity(title: 'Membaca bersama Ibu', aspect: 'kalimat', score: 80),
  ];

  final _scores = <String, int>{
    'huruf': 100,
    'suku_kata': 0,
    'kata': 70,
    'kalimat': 60,
  };

  String studentName = 'Andi Pratama';
  bool diagnosticCompleted = false;
  bool submittedPracticeRecording = false;
  int? lastPracticeScore;
  String? lastPracticeAspect;
  bool largerText = false;

  DemoStudent get student => TeacherDemoStore.instance.studentById(studentId)!;
  String get className => TeacherDemoStore.instance.className(student.classId);
  Map<String, int> get scores => Map.unmodifiable(_scores);
  int? get recommendedMaterialId =>
      TeacherDemoStore.instance.recommendationFor(studentId);

  void finishDiagnostic(Map<String, int> scores) {
    _scores
      ..clear()
      ..addAll(scores);
    student.scores = Map.of(scores);
    diagnosticCompleted = true;
    final weakest = scores.entries.reduce((a, b) => a.value <= b.value ? a : b);
    final material = TeacherDemoStore.instance.materials.where(
      (item) =>
          item.aspect == weakest.key &&
          item.status == 'aktif' &&
          item.level == 1,
    );
    if (material.isNotEmpty) {
      TeacherDemoStore.instance.setRecommendation(studentId, material.first.id);
    }
    notifyListeners();
  }

  void finishPractice({
    required String title,
    required String aspect,
    required int score,
  }) {
    _scores[aspect] = score;
    student.scores = Map.of(_scores);
    lastPracticeScore = score;
    lastPracticeAspect = aspect;
    activities.insert(
      0,
      StudentActivity(title: title, aspect: aspect, score: score),
    );
    final candidate = TeacherDemoStore.instance.materials.where(
      (item) => item.aspect == aspect && item.status == 'aktif',
    );
    if (candidate.isNotEmpty) {
      TeacherDemoStore.instance.setRecommendation(
        studentId,
        candidate.first.id,
      );
    }
    notifyListeners();
  }

  void submitRecordingPreview() {
    submittedPracticeRecording = true;
    notifyListeners();
  }

  void toggleLargerText() {
    largerText = !largerText;
    notifyListeners();
  }
}
