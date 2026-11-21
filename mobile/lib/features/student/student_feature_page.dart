import 'package:flutter/material.dart';

import '../../app/navigation_plan.dart';
import '../teacher/teacher_demo_store.dart';
import 'audio/student_audio_page.dart';
import 'dashboard/student_dashboard_page.dart';
import 'diagnostic/student_diagnostic_page.dart';
import 'practice/student_practice_pages.dart';
import 'progress/student_progress_page.dart';
import 'student_demo_store.dart';

class StudentFeatureBody extends StatelessWidget {
  const StudentFeatureBody({required this.screen, this.arguments, super.key});

  final PlannedScreen screen;
  final Object? arguments;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      StudentDemoStore.instance,
      // Consent and Teacher evaluations are shared with the Teacher preview data.
      TeacherDemoStore.instance,
    ]),
    builder: (context, _) => switch (screen.id) {
      'S2' => const StudentDashboardPage(),
      'S3' => const StudentDiagnosticPage(),
      'S4' => const StudentPracticeListPage(),
      'S5' => StudentMaterialDetailPage(
        materialId: arguments is int ? arguments as int : null,
      ),
      'S6' => StudentExercisePage(
        materialId: arguments is int ? arguments as int : null,
      ),
      'S7' => StudentRecordingPage(
        targetText: arguments is String ? arguments as String : null,
      ),
      'S8' => const StudentEvaluationPage(),
      'S9' => const StudentProgressPage(),
      'S10' => const StudentProfilePage(),
      _ => const Center(child: Text('Halaman Siswa tidak ditemukan.')),
    },
  );
}
