import 'package:flutter/material.dart';

import '../../../app/app_session.dart';
import '../../../core/theme/app_tokens.dart';
import '../../student/student_demo_store.dart';
import '../teacher_demo_store.dart';
import '../teacher_widgets.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  int? _studentId;
  String _aspect = 'suku_kata';

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final attempts =
        StudentDemoStore.instance
            .diagnosticHistoryForTeacher(AppSession.teacherId ?? -1)
            .where(
              (attempt) =>
                  (_studentId == null || attempt.studentId == _studentId) &&
                  attempt.aspectScores.containsKey(_aspect),
            )
            .toList()
          ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    final title = _studentId == null
        ? 'Rata-rata kelas'
        : store.studentById(_studentId!)?.name ?? 'Siswa';

    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        const TeacherPageHeading(
          title: 'Grafik Perkembangan',
          subtitle: 'Pantau hasil diagnostik membaca yang sudah dikerjakan.',
        ),
        Wrap(
          spacing: AppTokens.space12,
          runSpacing: AppTokens.space12,
          children: [
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<int?>(
                isExpanded: true,
                initialValue: _studentId,
                decoration: const InputDecoration(
                  labelText: 'Siswa atau kelas',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Rata-rata kelas'),
                  ),
                  for (final student in store.activeStudents)
                    DropdownMenuItem<int?>(
                      value: student.id,
                      child: Text(student.name),
                    ),
                ],
                onChanged: (value) => setState(() => _studentId = value),
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _aspect,
                decoration: const InputDecoration(labelText: 'Aspek'),
                items: const [
                  DropdownMenuItem(value: 'huruf', child: Text('Huruf')),
                  DropdownMenuItem(
                    value: 'suku_kata',
                    child: Text('Suku kata'),
                  ),
                  DropdownMenuItem(value: 'kata', child: Text('Kata')),
                  DropdownMenuItem(
                    value: 'kalimat',
                    child: Text('Kalimat sederhana'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _aspect = value ?? _aspect),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space16),
        TeacherPanel(
          title: '$title • ${aspectLabel(_aspect)}',
          child: attempts.isEmpty
              ? const EmptyState(
                  message: 'Belum ada hasil diagnostik untuk pilihan ini.',
                )
              : Column(
                  children: [
                    for (final attempt in attempts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(attempt.title),
                        subtitle: Text(
                          '${_formatDate(attempt.finishedAt)} • ${store.studentById(attempt.studentId)?.name ?? 'Siswa'}',
                        ),
                        trailing: Text(
                          '${attempt.aspectScores[_aspect]}%',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppTokens.space16),
        const TeacherPanel(
          child: Text(
            'Riwayat di halaman ini hanya memuat hasil diagnostik yang benar-benar tersimpan.',
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
