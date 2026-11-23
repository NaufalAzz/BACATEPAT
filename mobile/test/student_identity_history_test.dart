import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app_session.dart';
import 'package:mobile/features/student/student_demo_store.dart';
import 'package:mobile/features/teacher/teacher_demo_store.dart';

void main() {
  final teacher = TeacherDemoStore.instance;
  final students = StudentDemoStore.instance;

  setUp(() {
    AppSession.end();
    students.resetForTests();
  });

  test('practice attempt identity and history stay isolated by student', () {
    final material = teacher.materialById(1)!;
    final question = teacher.practiceQuestionsForMaterial(material.id).single;
    AppSession.startStudent(user: 101, student: 1);
    final answer = PracticeAnswerRecord(
      questionId: question.id,
      aspect: question.aspect,
      answer: question.correctAnswer!,
      correctAnswer: question.correctAnswer!,
      isCorrect: true,
    );
    final first = students.completePractice(
      materialId: material.id,
      title: material.title,
      aspect: material.aspect,
      availableQuestionCount: 1,
      questionSnapshots: [question],
      answers: [answer],
      startedAt: DateTime(2026, 1, 1),
      finishedAt: DateTime(2026, 1, 1, 0, 1),
    );

    expect(first, isNotNull);
    expect(first!.studentId, 1);
    expect(first.classId, 1);
    expect(first.score, 100);
    expect(
      first.questionSnapshots.single.correctAnswer,
      question.correctAnswer,
    );

    AppSession.end();
    AppSession.startStudent(user: 102, student: 2);
    expect(students.practiceHistory, isEmpty);
    expect(students.activities, isEmpty);
    expect(students.practiceScores, isEmpty);

    AppSession.end();
    AppSession.startStudent(user: 101, student: 1);
    expect(students.practiceHistory, hasLength(1));
  });

  test('invalid student session cannot read or write activity', () {
    AppSession.startStudent(user: 102, student: 1);
    expect(students.currentStudentId, isNull);
    expect(
      students.completePractice(
        materialId: 1,
        title: 'Materi',
        aspect: 'suku_kata',
        availableQuestionCount: 0,
        questionSnapshots: const [],
        answers: const [],
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026, 1, 1),
      ),
      isNull,
    );
    AppSession.startTeacher(user: 1, teacher: 1);
    expect(students.currentStudentId, isNull);
  });

  test(
    'demo login resolves distinct student accounts and teacher identity',
    () {
      expect(teacher.authenticateStudent('andi.1a', 'demo'), isTrue);
      expect(teacher.authenticateStudent('siti.1a', 'demo'), isTrue);
      expect(teacher.authenticateStudent('andi.1a', 'wrong'), isFalse);
      expect(teacher.authenticateStudent('missing', 'demo'), isFalse);
      expect(teacher.authenticateTeacher('guru-demo', 'demo'), isTrue);
      expect(teacher.authenticateTeacher('guru-demo', 'wrong'), isFalse);
    },
  );

  test(
    'teacher class scope filters students and blocks cross-class mutations',
    () {
      AppSession.startTeacher(user: 1, teacher: 1);
      final foreignClass = DemoClass(
        id: 99,
        name: '4A',
        grade: 1,
        year: '2026/2027',
        teacherId: 2,
      );
      final foreignStudent = DemoStudent(
        id: 99,
        userId: 999,
        name: 'Siswa Luar',
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

      expect(teacher.accessibleClasses.map((item) => item.id), [1, 2, 3]);
      expect(teacher.accessibleStudents.any((item) => item.id == 99), isFalse);
      expect(teacher.canTeacherAccessStudent(1, 99), isFalse);
      expect(teacher.canTeacherAccessStudent(2, 99), isTrue);
      teacher.saveStudent(
        name: 'Tidak boleh',
        username: 'tidak.boleh',
        classId: 99,
        guardianName: 'Wali',
        parentConsent: false,
        aiConsent: false,
      );
      expect(
        teacher.students.any((item) => item.username == 'tidak.boleh'),
        isFalse,
      );
    },
  );

  test(
    'new practice and diagnostic histories are separate and empty by default',
    () {
      AppSession.startStudent(user: 101, student: 1);
      expect(students.practiceHistory, isEmpty);
      expect(students.diagnosticHistory, isEmpty);
      expect(students.activities, isEmpty);
      expect(students.diagnosticScores, isEmpty);
    },
  );
}
