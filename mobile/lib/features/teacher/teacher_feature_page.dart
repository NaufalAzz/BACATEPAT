import 'package:flutter/material.dart';

import '../../app/navigation_plan.dart';
import 'audio_review/audio_review_page.dart';
import 'classes/classes_page.dart';
import 'dashboard/dashboard_page.dart';
import 'diagnostics/diagnostics_pages.dart';
import 'materials/materials_pages.dart';
import 'profile/profile_page.dart';
import 'progress/progress_page.dart';
import 'questions/questions_pages.dart';
import 'reports/reports_page.dart';
import 'students/students_pages.dart';
import 'teacher_demo_store.dart';

class TeacherFeaturePage extends StatelessWidget {
  const TeacherFeaturePage({required this.screen, this.arguments, super.key});

  final PlannedScreen screen;
  final Object? arguments;

  @override
  Widget build(BuildContext context) =>
      TeacherPageBody(screen: screen, arguments: arguments);
}

class TeacherPageBody extends StatelessWidget {
  const TeacherPageBody({required this.screen, this.arguments, super.key});

  final PlannedScreen screen;
  final Object? arguments;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: TeacherDemoStore.instance,
    builder: (context, _) => switch (screen.id) {
      'G2' => const DashboardPage(),
      'G3' => const StudentsPage(),
      'G4' => StudentFormPage(
        studentId: arguments is int ? arguments as int : null,
      ),
      'G5' => const ClassesPage(),
      'G6' => const MaterialsPage(),
      'G7' => MaterialFormPage(
        materialId: arguments is int ? arguments as int : null,
      ),
      'G8' => const MaterialGeneratorPage(),
      'G9' => const QuestionsPage(),
      'G10' => const QuestionGeneratorPage(),
      'G11' => const DiagnosticsPage(),
      'G12' => DiagnosticResultsPage(
        diagnosticId: arguments is int ? arguments as int : null,
      ),
      'G13' => const AudioReviewPage(),
      'G14' => StudentDetailPage(
        studentId: arguments is int ? arguments as int : null,
      ),
      'G15' => const ProgressPage(),
      'G16' => const ReportsPage(),
      'G17' => const ProfilePage(),
      _ => const Center(child: Text('Halaman Guru tidak ditemukan.')),
    },
  );
}
