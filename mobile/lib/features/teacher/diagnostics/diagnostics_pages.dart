import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../student/student_demo_store.dart';
import '../../../app/app_session.dart';
import '../teacher_demo_store.dart';
import '../teacher_widgets.dart';

class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        TeacherPageHeading(
          section: 'Tes Diagnostik',
          title: 'Daftar tes',
          subtitle:
              'Susun tes dari soal yang telah ditinjau, lalu aktifkan untuk kelas.',
        ),
        FilledButton.icon(
          key: const ValueKey('create-diagnostic'),
          onPressed: () =>
              Navigator.pushNamed(context, '/guru/diagnostik/tambah'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Buat tes diagnostik'),
        ),
        const SizedBox(height: AppTokens.space16),
        if (store.accessibleDiagnostics.isEmpty)
          const TeacherPanel(
            child: EmptyState(message: 'Belum ada tes diagnostik.'),
          ),
        for (final test in store.accessibleDiagnostics)
          TeacherPanel(
            key: ValueKey('diagnostic-${test.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        test.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    StatusBadge(
                      label: _statusLabel(test.status),
                      variant: test.status == 'aktif'
                          ? StatusVariant.active
                          : StatusVariant.pending,
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  '${store.className(test.classId)} • ${test.questionIds.length} soal',
                ),
                const SizedBox(height: AppTokens.space12),
                Wrap(
                  spacing: AppTokens.space8,
                  children: [
                    if (test.status == 'draf')
                      FilledButton.icon(
                        key: ValueKey('activate-test-${test.id}'),
                        onPressed: () {
                          final activated = store.activateDiagnostic(test.id);
                          final issues = activated
                              ? const <String>[]
                              : store.diagnosticValidationIssues(test.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                activated
                                    ? 'Tes diaktifkan.'
                                    : issues.join(' '),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Aktifkan'),
                      ),
                    TextButton.icon(
                      key: ValueKey('view-results-${test.id}'),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/guru/diagnostik/hasil',
                        arguments: test.id,
                      ),
                      icon: const Icon(Icons.assessment_outlined),
                      label: const Text('Lihat hasil'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class DiagnosticBuilderPage extends StatefulWidget {
  const DiagnosticBuilderPage({super.key});

  @override
  State<DiagnosticBuilderPage> createState() => _DiagnosticBuilderPageState();
}

class _DiagnosticBuilderPageState extends State<DiagnosticBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final Set<int> _selectedQuestions = {};
  late int? _classId;

  @override
  void initState() {
    super.initState();
    final classes = TeacherDemoStore.instance.accessibleClasses;
    _classId = classes.isEmpty ? null : classes.first.id;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final grade = _classId == null ? null : store.classById(_classId!)?.grade;
    final questions = store.questions.where(
      (item) =>
          item.type == 'Pilihan ganda' &&
          item.canBeUsedFor('diagnostik', materials: store.materials) &&
          (grade == null || item.level <= grade),
    );
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        const TeacherPageHeading(
          title: 'Buat Tes Diagnostik',
          subtitle: 'Pilih kelas dan soal untuk tes membaca.',
        ),
        TeacherPanel(
          title: 'Informasi tes',
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Nama tes'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama tes wajib diisi.'
                      : null,
                ),
                const SizedBox(height: AppTokens.space16),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _classId,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                  items: [
                    for (final item in store.accessibleClasses)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: (value) => setState(() {
                    _classId = value;
                    _selectedQuestions.clear();
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        TeacherPanel(
          title: 'Pilih soal',
          child: Column(
            children: [
              for (final question in questions)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selectedQuestions.contains(question.id),
                  title: Text(question.prompt),
                  subtitle: Text(aspectLabel(question.aspect)),
                  onChanged: (selected) => setState(() {
                    if (selected == true) {
                      _selectedQuestions.add(question.id);
                    } else {
                      _selectedQuestions.remove(question.id);
                    }
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space20),
        FilledButton(onPressed: _save, child: const Text('Simpan draf')),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_classId == null || _selectedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kelas dan minimal satu soal.')),
      );
      return;
    }
    TeacherDemoStore.instance.addDiagnostic(
      title: _title.text.trim(),
      classId: _classId!,
      questionIds: _selectedQuestions.toList(),
    );
    Navigator.maybePop(context);
  }
}

class DiagnosticResultsPage extends StatefulWidget {
  const DiagnosticResultsPage({this.diagnosticId, super.key});

  final int? diagnosticId;

  @override
  State<DiagnosticResultsPage> createState() => _DiagnosticResultsPageState();
}

class _DiagnosticResultsPageState extends State<DiagnosticResultsPage> {
  String _query = '';
  String _status = 'Semua status';

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final diagnostic = widget.diagnosticId == null
        ? null
        : store.diagnostics
              .where((item) => item.id == widget.diagnosticId)
              .isEmpty
        ? null
        : store.diagnostics.firstWhere(
            (item) => item.id == widget.diagnosticId,
          );
    final teacherId = AppSession.teacherId;
    final permittedDiagnostic =
        diagnostic != null &&
        teacherId != null &&
        store.canTeacherAccessClass(teacherId, diagnostic.classId);
    if (!permittedDiagnostic) {
      return ListView(
        padding: const EdgeInsets.all(AppTokens.space16),
        children: const [
          TeacherPageHeading(
            title: 'Hasil Diagnostik',
            subtitle: 'Hasil tes tidak tersedia untuk akun Guru ini.',
          ),
          TeacherPanel(
            child: EmptyState(
              message: 'Akses ke kelas tes ini tidak tersedia.',
            ),
          ),
        ],
      );
    }
    final latestByStudent = <int, DiagnosticAttempt>{};
    for (final attempt
        in StudentDemoStore.instance
            .diagnosticHistoryForTeacher(teacherId)
            .where((item) => item.diagnosticId == diagnostic.id)) {
      final previous = latestByStudent[attempt.studentId];
      if (previous == null || attempt.finishedAt.isAfter(previous.finishedAt)) {
        latestByStudent[attempt.studentId] = attempt;
      }
    }
    final rows = <_DiagnosticStudentResult>[];
    for (final attempt in latestByStudent.values) {
      final student = store.studentById(attempt.studentId);
      if (student == null) continue;
      final status = _diagnosticStatus(attempt.score);
      if (student.name.toLowerCase().contains(_query) &&
          (_status == 'Semua status' || status == _status)) {
        rows.add(_DiagnosticStudentResult(student: student, attempt: attempt));
      }
    }
    rows.sort((a, b) => a.student.name.compareTo(b.student.name));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TeacherPageHeading(
          title: 'Hasil Diagnostik',
          subtitle: diagnostic.title,
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('diagnostic-result-search'),
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, size: 19),
                  hintText: 'Cari siswa...',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: DropdownButtonFormField<String>(
                key: const ValueKey('diagnostic-result-status'),
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 12,
                  ),
                ),
                items:
                    const [
                          'Semua status',
                          'Belum dikuasai',
                          'Sedang berlatih',
                          'Dikuasai',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
            ),
            const SizedBox(width: 7),
            IconButton.filledTonal(
              tooltip: 'Ekspor hasil',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pratinjau ekspor tersedia sesuai laporan.'),
                ),
              ),
              icon: const Icon(Icons.description_outlined, size: 18),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space16),
        if (rows.isEmpty)
          const TeacherPanel(
            child: EmptyState(
              message: 'Tidak ada hasil yang cocok dengan pilihan ini.',
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTokens.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFF2F6F5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'SISWA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _resultHeaderStyle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'HURUF',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: _resultHeaderStyle,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'SUKU KATA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: _resultHeaderStyle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'KATA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: _resultHeaderStyle,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'KALIMAT',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: _resultHeaderStyle,
                        ),
                      ),
                    ],
                  ),
                ),
                for (var index = 0; index < rows.length; index++) ...[
                  InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/guru/siswa/detail',
                      arguments: rows[index].student.id,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rows[index].student.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTokens.text,
                                  ),
                                ),
                                Text(
                                  store.className(rows[index].student.classId),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppTokens.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final aspect in const [
                            'huruf',
                            'suku_kata',
                            'kata',
                            'kalimat',
                          ])
                            Expanded(
                              flex: aspect == 'suku_kata' || aspect == 'kalimat'
                                  ? 2
                                  : 1,
                              child: Text(
                                '${rows[index].attempt.aspectScores[aspect] ?? 0}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      (rows[index]
                                                  .attempt
                                                  .aspectScores[aspect] ??
                                              0) <
                                          60
                                      ? AppTokens.coral
                                      : AppTokens.text,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (index < rows.length - 1)
                    const Divider(height: 1, color: AppTokens.outline),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _DiagnosticStudentResult {
  const _DiagnosticStudentResult({
    required this.student,
    required this.attempt,
  });

  final DemoStudent student;
  final DiagnosticAttempt attempt;
}

String _statusLabel(String status) => switch (status) {
  'aktif' => 'Aktif',
  'draf' => 'Draf',
  'arsip' => 'Arsip',
  _ => status,
};

String _diagnosticStatus(int score) => score < 60
    ? 'Belum dikuasai'
    : score < 80
    ? 'Sedang berlatih'
    : 'Dikuasai';

const _resultHeaderStyle = TextStyle(
  fontSize: 8,
  fontWeight: FontWeight.w800,
  color: AppTokens.mutedText,
);
