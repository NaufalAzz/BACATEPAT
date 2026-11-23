import 'navigation_plan.dart';

/// In-memory role state for the frontend preview only.
abstract final class AppSession {
  static AppRole? role;
  static int? userId;
  static int? studentId;
  static int? teacherId;

  static void startStudent({required int user, required int student}) {
    role = AppRole.student;
    userId = user;
    studentId = student;
    teacherId = null;
  }

  static void startTeacher({required int user, required int teacher}) {
    role = AppRole.teacher;
    userId = user;
    teacherId = teacher;
    studentId = null;
  }

  static void end() {
    role = null;
    userId = null;
    studentId = null;
    teacherId = null;
  }
}
