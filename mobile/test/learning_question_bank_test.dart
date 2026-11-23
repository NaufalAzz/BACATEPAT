import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/student/learning_question_bank.dart';
import 'package:mobile/features/student/student_demo_store.dart';
import 'package:mobile/features/teacher/teacher_demo_store.dart';
import 'package:mobile/app/app_session.dart';

void main() {
  test('diagnostic items have valid keys and do not state their answers', () {
    expect(diagnosticQuestions, hasLength(8));
    for (final question in diagnosticQuestions) {
      expect(question.hasValidAnswer, isTrue, reason: question.prompt);
      expect(question.promptLeaksAnswer, isFalse, reason: question.prompt);
      expect(question.choices.toSet(), hasLength(question.choices.length));
      expect(question.hint, isNotEmpty);
      expect(question.correctFeedback, isNotEmpty);
    }
    expect(diagnosticQuestions.map((question) => question.aspect).toSet(), {
      'huruf',
      'suku_kata',
      'kata',
      'kalimat',
    });
  });

  test(
    'activity history starts empty and belongs to the signed-in student',
    () {
      AppSession.startStudent(user: 101, student: 1);
      StudentDemoStore.instance.resetForTests();
      expect(StudentDemoStore.instance.activities, isEmpty);
      expect(StudentDemoStore.instance.practiceScores, isEmpty);
      expect(StudentDemoStore.instance.diagnosticScores, isEmpty);
      expect(
        StudentDemoStore.instance.student,
        TeacherDemoStore.instance.studentById(1),
      );
    },
  );
}
