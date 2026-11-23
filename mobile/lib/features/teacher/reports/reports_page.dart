import 'package:flutter/material.dart';

import '../../../app/app_session.dart';
import '../../../core/theme/app_tokens.dart';
import '../../student/student_demo_store.dart';
import '../teacher_demo_store.dart';
import '../teacher_widgets.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _type = 'Siswa';
  int? _studentId = 1;
  int? _classId = 1;
  DateTimeRange _period = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final selectedStudents = store.accessibleStudents
        .where((item) => item.id == _studentId)
        .toList();
    final selectedClasses = store.accessibleClasses
        .where((item) => item.id == _classId)
        .toList();
    final selectedLabel = _type == 'Siswa'
        ? (selectedStudents.isEmpty
              ? 'Pilih siswa'
              : selectedStudents.first.name)
        : (selectedClasses.isEmpty
              ? 'Pilih kelas'
              : selectedClasses.first.name);
    final studentRows = _type == 'Siswa'
        ? store.accessibleStudents
              .where((item) => item.id == _studentId)
              .toList()
        : store.accessibleStudents
              .where((item) => item.classId == _classId && item.active)
              .toList();
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        const TeacherPageHeading(
          title: 'Laporan',
          subtitle: 'Tinjau ringkasan belajar dalam periode yang dipilih.',
        ),
        TeacherPanel(
          title: 'Pengaturan laporan',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Jenis laporan'),
                items: const [
                  DropdownMenuItem(
                    value: 'Siswa',
                    child: Text('Laporan siswa'),
                  ),
                  DropdownMenuItem(
                    value: 'Kelas',
                    child: Text('Laporan kelas'),
                  ),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: AppTokens.space16),
              if (_type == 'Siswa')
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _studentId,
                  decoration: const InputDecoration(labelText: 'Siswa'),
                  items: [
                    for (final student in store.activeStudents)
                      DropdownMenuItem(
                        value: student.id,
                        child: Text(student.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _studentId = value),
                )
              else
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _classId,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                  items: [
                    for (final item in store.accessibleClasses)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: (value) => setState(() => _classId = value),
                ),
              const SizedBox(height: AppTokens.space16),
              OutlinedButton.icon(
                key: const ValueKey('report-period'),
                onPressed: _choosePeriod,
                icon: const Icon(Icons.date_range_outlined),
                label: Text(
                  '${_formatDate(_period.start)} – ${_formatDate(_period.end)}',
                ),
              ),
              const SizedBox(height: AppTokens.space16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('preview-report'),
                  onPressed: studentRows.isEmpty
                      ? null
                      : () => _showPreview(
                          context,
                          selectedLabel,
                          studentRows,
                          store,
                        ),
                  icon: const Icon(Icons.preview_outlined),
                  label: const Text('Pratinjau laporan'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        TeacherPanel(
          title: 'Isi laporan',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReportLine(
                icon: Icons.person_outline_rounded,
                label: _type == 'Siswa' ? 'Identitas siswa' : 'Kelas',
                value: selectedLabel,
              ),
              _ReportLine(
                icon: Icons.date_range_outlined,
                label: 'Periode',
                value:
                    '${_formatDate(_period.start)} – ${_formatDate(_period.end)}',
              ),
              _ReportLine(
                icon: Icons.fact_check_outlined,
                label: 'Diagnostik',
                value: 'Skor dan status empat aspek',
              ),
              _ReportLine(
                icon: Icons.menu_book_outlined,
                label: 'Latihan',
                value: 'Riwayat dan rekomendasi aktif',
              ),
              _ReportLine(
                icon: Icons.show_chart_rounded,
                label: 'Perkembangan',
                value: 'Ringkasan skor membaca',
              ),
              const SizedBox(height: AppTokens.space8),
              Text(
                'Pratinjau mengikuti susunan laporan pada BRD. Berkas PDF belum dibuat pada tahap frontend ini.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _choosePeriod() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _period,
      helpText: 'Pilih periode laporan',
    );
    if (picked != null) setState(() => _period = picked);
  }

  void _showPreview(
    BuildContext context,
    String label,
    List<DemoStudent> students,
    TeacherDemoStore store,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pratinjau Laporan'),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BacaTepat • ${_type == 'Siswa' ? 'Laporan siswa' : 'Laporan kelas'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(height: AppTokens.space24),
                Text(
                  '$label • ${_formatDate(_period.start)} – ${_formatDate(_period.end)}',
                ),
                const SizedBox(height: AppTokens.space16),
                for (final student in students) ...[
                  Text(
                    student.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('Kelas ${store.className(student.classId)}'),
                  if (StudentDemoStore.instance.latestDiagnosticForTeacher(
                        AppSession.teacherId ?? -1,
                        student.id,
                      ) ==
                      null)
                    const Text('Belum menyelesaikan diagnostik.')
                  else
                    for (final score
                        in StudentDemoStore.instance
                            .latestDiagnosticForTeacher(
                              AppSession.teacherId ?? -1,
                              student.id,
                            )!
                            .aspectScores
                            .entries)
                      _ReportLine(
                        icon: Icons.circle,
                        label: aspectLabel(score.key),
                        value: '${score.value}% • ${masteryLabel(score.value)}',
                      ),
                  const SizedBox(height: AppTokens.space12),
                ],
                const Text(
                  'Status kemampuan adalah ringkasan pembelajaran, bukan diagnosis medis.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Pratinjau siap. Ekspor PDF tersedia setelah integrasi backend.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.download_outlined),
            label: const Text('Simulasikan ekspor'),
          ),
        ],
      ),
    );
  }
}

class _ReportLine extends StatelessWidget {
  const _ReportLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 280) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppTokens.primary),
                  const SizedBox(width: AppTokens.space8),
                  Expanded(child: Text(label)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 28, top: AppTokens.space4),
                child: Text(value),
              ),
            ],
          );
        }
        return Row(
          children: [
            Icon(icon, size: 20, color: AppTokens.primary),
            const SizedBox(width: AppTokens.space8),
            SizedBox(width: 120, child: Text(label)),
            Expanded(child: Text(value)),
          ],
        );
      },
    ),
  );
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
