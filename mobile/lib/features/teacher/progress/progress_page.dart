import 'package:flutter/material.dart';

import '../../../app/app_session.dart';
import '../../../core/theme/app_tokens.dart';
import '../../student/mastery_history_chart.dart';
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
    final studentStore = StudentDemoStore.instance;
    final teacherId = AppSession.teacherId ?? -1;
    final records =
        studentStore
            .masteryHistoryForTeacher(teacherId)
            .where(
              (record) =>
                  (_studentId == null || record.studentId == _studentId) &&
                  record.aspect == _aspect,
            )
            .toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final chartPoints = _chartPoints(records, classAverage: _studentId == null);
    final latestByStudent = <int, MasteryRecord>{};
    for (final record in records.reversed) {
      latestByStudent[record.studentId] = record;
    }
    final title = _studentId == null
        ? 'Rata-rata kelas'
        : store.studentById(_studentId!)?.name ?? 'Siswa';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TeacherPageHeading(
            section: 'Grafik Perkembangan',
            title: 'Perkembangan siswa',
            subtitle:
                'Pantau perubahan penguasaan dari diagnostik dan latihan.',
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
            title: 'Tren ${aspectLabel(_aspect)}',
            child: chartPoints.isEmpty
                ? const EmptyState(
                    message: 'Belum ada riwayat untuk ditampilkan pada grafik.',
                  )
                : MasteryHistoryChart(
                    chartKey: const ValueKey('teacher-mastery-history-chart'),
                    points: chartPoints,
                  ),
          ),
          const SizedBox(height: AppTokens.space16),
          TeacherPanel(
            title: '$title · ${aspectLabel(_aspect)}',
            child: latestByStudent.isEmpty
                ? const EmptyState(
                    message: 'Belum ada catatan penguasaan untuk pilihan ini.',
                  )
                : Column(
                    children: [
                      for (final record in latestByStudent.values)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _studentId == null
                                ? store.studentById(record.studentId)?.name ??
                                      'Siswa'
                                : _masteryStatus(record.status),
                          ),
                          subtitle: LinearProgressIndicator(
                            value: record.score / 100,
                            minHeight: 7,
                          ),
                          trailing: Text('${record.score}%'),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: AppTokens.space16),
          TeacherPanel(
            title: 'Riwayat penguasaan',
            child: records.isEmpty
                ? const EmptyState(
                    message: 'Belum ada riwayat penguasaan untuk pilihan ini.',
                  )
                : Column(
                    children: [
                      for (final record in records)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${store.studentById(record.studentId)?.name ?? 'Siswa'} · ${_masteryStatus(record.status)}',
                          ),
                          subtitle: Text(
                            '${record.source == 'diagnostik' ? 'Diagnostik' : 'Latihan'} · Tingkat ${record.level} · ${_formatDate(record.recordedAt)}\n${record.reason}',
                          ),
                          trailing: Text('${record.score}%'),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: AppTokens.space16),
          const TeacherPanel(
            child: Text(
              'Grafik dan riwayat memakai catatan penguasaan aktual. Catatan lama tetap tersimpan saat hasil baru masuk.',
            ),
          ),
        ],
      ),
    );
  }
}

List<MasteryPoint> _chartPoints(
  List<MasteryRecord> records, {
  required bool classAverage,
}) {
  final ordered = records.toList()
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  if (!classAverage) {
    return [
      for (final record in ordered)
        MasteryPoint(recordedAt: record.recordedAt, score: record.score),
    ];
  }
  final scoresByDate = <DateTime, List<int>>{};
  for (final record in ordered) {
    final date = DateTime(
      record.recordedAt.year,
      record.recordedAt.month,
      record.recordedAt.day,
    );
    scoresByDate.putIfAbsent(date, () => []).add(record.score);
  }
  return [
    for (final entry in scoresByDate.entries)
      MasteryPoint(
        recordedAt: entry.key,
        score: (entry.value.reduce((a, b) => a + b) / entry.value.length)
            .round(),
      ),
  ];
}

String _masteryStatus(String status) => switch (status) {
  'dikuasai' => 'Dikuasai',
  'sedang_berlatih' => 'Sedang berlatih',
  _ => 'Belum dikuasai',
};

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
