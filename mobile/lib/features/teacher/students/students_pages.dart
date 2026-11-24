import 'package:flutter/material.dart';

import '../../../core/components/baca_button.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../app/app_session.dart';
import '../../student/student_demo_store.dart';
import '../teacher_demo_store.dart';
import '../teacher_widgets.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final _searchController = TextEditingController();
  int? _classFilter;
  bool _showInactive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final query = _searchController.text.trim().toLowerCase();
    final filtered = store.accessibleStudents.where((student) {
      final matchesQuery =
          student.name.toLowerCase().contains(query) ||
          student.username.toLowerCase().contains(query);
      return matchesQuery &&
          (_classFilter == null || student.classId == _classFilter) &&
          (_showInactive || student.active);
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        TeacherPageHeading(
          title: 'Data Siswa',
          subtitle:
              '${store.activeStudents.length} siswa aktif di ${store.accessibleClasses.length} kelas.',
        ),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 540
              ? Column(
                  children: [
                    BacaButton(
                      key: const ValueKey('add-student'),
                      label: 'Tambah siswa',
                      icon: Icons.person_add_alt_1_rounded,
                      onPressed: () =>
                          Navigator.pushNamed(context, '/guru/siswa/form'),
                    ),
                    const SizedBox(height: AppTokens.space12),
                    _studentFilters(context),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _studentFilters(context)),
                    const SizedBox(width: AppTokens.space12),
                    SizedBox(
                      width: 220,
                      child: BacaButton(
                        key: const ValueKey('add-student'),
                        label: 'Tambah siswa',
                        icon: Icons.person_add_alt_1_rounded,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/guru/siswa/form'),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: AppTokens.space16),
        Wrap(
          spacing: AppTokens.space8,
          runSpacing: AppTokens.space8,
          children: [
            FilterChip(
              label: const Text('Aktif'),
              selected: !_showInactive,
              onSelected: (_) => setState(() => _showInactive = false),
            ),
            FilterChip(
              label: const Text('Semua status'),
              selected: _showInactive,
              onSelected: (_) => setState(() => _showInactive = true),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space16),
        if (filtered.isEmpty)
          const TeacherPanel(
            child: EmptyState(
              message: 'Belum ada siswa yang cocok dengan pencarian ini.',
            ),
          )
        else
          for (final student in filtered)
            Card(
              child: ListTile(
                key: ValueKey('student-row-${student.id}'),
                minVerticalPadding: AppTokens.space12,
                leading: CircleAvatar(
                  backgroundColor: AppTokens.primary.withValues(alpha: 0.1),
                  child: Text(student.name.substring(0, 1).toUpperCase()),
                ),
                title: Text(student.name),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: AppTokens.space4),
                  child: Wrap(
                    spacing: AppTokens.space8,
                    runSpacing: AppTokens.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${store.className(student.classId)} • ${student.username}',
                      ),
                      StatusBadge(
                        label: student.parentConsent
                            ? 'Persetujuan wali'
                            : 'Belum disetujui',
                        good: student.parentConsent,
                      ),
                      StatusBadge(
                        label: student.active
                            ? masterySummaryFor(
                                StudentDemoStore.instance
                                    .latestDiagnosticForTeacher(
                                      AppSession.teacherId ?? -1,
                                      student.id,
                                    )
                                    ?.aspectScores,
                              )
                            : 'Nonaktif',
                        good:
                            student.active &&
                            StudentDemoStore.instance
                                    .latestDiagnosticForTeacher(
                                      AppSession.teacherId ?? -1,
                                      student.id,
                                    ) !=
                                null,
                      ),
                    ],
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Aksi siswa',
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.pushNamed(
                        context,
                        '/guru/siswa/form',
                        arguments: student.id,
                      );
                    } else if (value == 'status') {
                      TeacherDemoStore.instance.toggleStudentActive(student.id);
                      setState(() {});
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Ubah data'),
                    ),
                    PopupMenuItem(
                      value: 'status',
                      child: Text(student.active ? 'Nonaktifkan' : 'Aktifkan'),
                    ),
                  ],
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/guru/siswa/detail',
                  arguments: student.id,
                ),
              ),
            ),
      ],
    );
  }

  Widget _studentFilters(BuildContext context) {
    final store = TeacherDemoStore.instance;
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          key: const ValueKey('student-search'),
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Cari nama atau username',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (_) => setState(() {}),
        );
        final classFilter = DropdownButtonFormField<int?>(
          isExpanded: true,
          initialValue: _classFilter,
          decoration: const InputDecoration(labelText: 'Kelas'),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Semua')),
            for (final item in store.accessibleClasses)
              DropdownMenuItem<int?>(value: item.id, child: Text(item.name)),
          ],
          onChanged: (value) => setState(() => _classFilter = value),
        );
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: AppTokens.space12),
              classFilter,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: AppTokens.space12),
            SizedBox(width: 150, child: classFilter),
          ],
        );
      },
    );
  }
}

class StudentFormPage extends StatefulWidget {
  const StudentFormPage({this.studentId, super.key});

  final int? studentId;

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _guardian;
  late int _classId;
  late bool _parentConsent;
  late bool _aiConsent;

  DemoStudent? get _student => widget.studentId == null
      ? null
      : (TeacherDemoStore.instance.canTeacherAccessStudent(
              AppSession.teacherId ?? -1,
              widget.studentId!,
            )
            ? TeacherDemoStore.instance.studentById(widget.studentId!)
            : null);

  @override
  void initState() {
    super.initState();
    final student = _student;
    _name = TextEditingController(text: student?.name ?? '');
    _username = TextEditingController(text: student?.username ?? '');
    _password = TextEditingController();
    _guardian = TextEditingController(text: student?.guardianName ?? '');
    _classId =
        student?.classId ??
        TeacherDemoStore.instance.accessibleClasses.firstOrNull?.id ??
        -1;
    _parentConsent = student?.parentConsent ?? false;
    _aiConsent = student?.aiConsent ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    _guardian.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _student != null;
    final store = TeacherDemoStore.instance;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppTokens.space16),
              children: [
                const TeacherPageHeading(
                  title: 'Data siswa',
                  subtitle: 'Isi informasi dasar dan persetujuan wali.',
                ),
                TextFormField(
                  key: const ValueKey('form-student-name'),
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nama lengkap'),
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'Nama minimal 2 karakter.'
                      : null,
                ),
                const SizedBox(height: AppTokens.space16),
                TextFormField(
                  key: const ValueKey('form-student-username'),
                  controller: _username,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) =>
                      value == null ||
                          !RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value.trim())
                      ? 'Gunakan huruf, angka, titik, atau garis bawah.'
                      : null,
                ),
                if (!isEditing) ...[
                  const SizedBox(height: AppTokens.space16),
                  TextFormField(
                    key: const ValueKey('form-student-password'),
                    controller: _password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Kata sandi awal (simulasi)',
                    ),
                    validator: _validatePassword,
                  ),
                ],
                const SizedBox(height: AppTokens.space16),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _classId,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                  items: [
                    for (final item in store.accessibleClasses)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.name} • kelas ${item.grade}'),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _classId = value ?? _classId),
                ),
                const SizedBox(height: AppTokens.space16),
                TextFormField(
                  controller: _guardian,
                  decoration: const InputDecoration(labelText: 'Nama wali'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama wali perlu diisi.'
                      : null,
                ),
                const SizedBox(height: AppTokens.space16),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        key: const ValueKey('parent-consent'),
                        title: const Text('Persetujuan wali untuk rekaman'),
                        subtitle: const Text(
                          'Rekaman tidak dapat dibuat tanpa persetujuan ini.',
                        ),
                        value: _parentConsent,
                        onChanged: (value) => setState(() {
                          _parentConsent = value;
                          if (!value) _aiConsent = false;
                        }),
                      ),
                      SwitchListTile.adaptive(
                        key: const ValueKey('ai-consent'),
                        title: const Text('Persetujuan analisis AI'),
                        subtitle: const Text(
                          'Hanya indikasi untuk rekaman kata atau kalimat.',
                        ),
                        value: _aiConsent,
                        onChanged: _parentConsent
                            ? (value) => setState(() => _aiConsent = value)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space24),
                BacaButton(
                  key: const ValueKey('save-student'),
                  label: isEditing ? 'Simpan perubahan' : 'Simpan siswa',
                  icon: Icons.save_outlined,
                  onPressed: _save,
                ),
                if (isEditing) ...[
                  const SizedBox(height: AppTokens.space8),
                  TextButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reset kata sandi simulasi berhasil.'),
                      ),
                    ),
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: const Text('Reset kata sandi'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final store = TeacherDemoStore.instance;
    final duplicate = store.students.any(
      (item) =>
          item.username.toLowerCase() == _username.text.trim().toLowerCase() &&
          item.id != widget.studentId,
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username sudah digunakan.')),
      );
      return;
    }
    store.saveStudent(
      id: widget.studentId,
      name: _name.text.trim(),
      username: _username.text.trim(),
      password: widget.studentId == null ? _password.text : null,
      classId: _classId,
      guardianName: _guardian.text.trim(),
      parentConsent: _parentConsent,
      aiConsent: _aiConsent,
    );
    Navigator.pop(context);
  }
}

String? _validatePassword(String? value) => value == null || value.length < 8
    ? 'Kata sandi awal minimal 8 karakter.'
    : null;

class StudentDetailPage extends StatelessWidget {
  const StudentDetailPage({this.studentId, super.key});

  final int? studentId;

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final learningStore = StudentDemoStore.instance;
    final teacherId = AppSession.teacherId;
    final student =
        studentId == null ||
            teacherId == null ||
            !store.canTeacherAccessStudent(teacherId, studentId!)
        ? null
        : store.studentById(studentId!);
    if (student == null) {
      return const Scaffold(
        body: EmptyState(message: 'Data siswa tidak ditemukan.'),
      );
    }
    final authorizedTeacherId = teacherId!;
    return AnimatedBuilder(
      animation: learningStore,
      builder: (context, _) {
        final latestMastery = learningStore.latestMasteryForTeacher(
          authorizedTeacherId,
          student.id,
        );
        final recommendation = learningStore.activeRecommendationForTeacher(
          authorizedTeacherId,
          student.id,
        );
        final materialGaps = learningStore.materialGapsForStudentTeacher(
          authorizedTeacherId,
          student.id,
        );
        return ListView(
          padding: const EdgeInsets.all(AppTokens.space16),
          children: [
            TeacherPageHeading(
              title: student.name,
              subtitle:
                  'Kelas ${store.className(student.classId)} • @${student.username}',
            ),
            TeacherPanel(
              title: 'Informasi siswa',
              child: Wrap(
                spacing: AppTokens.space12,
                runSpacing: AppTokens.space12,
                children: [
                  StatusBadge(
                    label: student.active ? 'Aktif' : 'Nonaktif',
                    good: student.active,
                  ),
                  StatusBadge(
                    label: student.parentConsent
                        ? 'Persetujuan rekaman: ya'
                        : 'Persetujuan rekaman: belum',
                    good: student.parentConsent,
                  ),
                  StatusBadge(
                    label: student.aiConsent
                        ? 'Persetujuan AI: ya'
                        : 'Persetujuan AI: tidak',
                    good: student.aiConsent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),
            TeacherPanel(
              title: 'Penguasaan membaca',
              child: latestMastery.isEmpty
                  ? const EmptyState(
                      message: 'Belum ada catatan penguasaan dari diagnostik lengkap.',
                    )
                  : Column(
                      children: [
                        for (final aspect in const [
                          'huruf',
                          'suku_kata',
                          'kata',
                          'kalimat',
                        ])
                          if (latestMastery[aspect] case final record?)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(aspectLabel(record.aspect)),
                              subtitle: Text(
                                '${record.score}% · Tingkat ${record.level} · ${record.source == 'diagnostik' ? 'Diagnostik' : 'Latihan'}',
                              ),
                              trailing: Text(
                                _masteryStatusLabel(record.status),
                              ),
                            ),
                      ],
                    ),
            ),
            const SizedBox(height: AppTokens.space16),
            TeacherPanel(
              title: 'Hasil diagnostik',
              child:
                  StudentDemoStore.instance.latestDiagnosticForTeacher(
                        authorizedTeacherId,
                        student.id,
                      ) ==
                      null
                  ? const EmptyState(
                      message: 'Belum ada hasil diagnostik untuk siswa ini.',
                    )
                  : Column(
                      children: [
                        for (final entry
                            in StudentDemoStore.instance
                                .latestDiagnosticForTeacher(
                                  teacherId,
                                  student.id,
                                )!
                                .aspectScores
                                .entries)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(aspectLabel(entry.key)),
                            subtitle: LinearProgressIndicator(
                              value: entry.value / 100,
                              minHeight: 7,
                            ),
                            trailing: Text(
                              '${entry.value}%\n${masteryLabel(entry.value)}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppTokens.space16),
            TeacherPanel(
              title: 'Rekomendasi dan pendampingan',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan: ${masterySummaryFor({for (final entry in latestMastery.entries) entry.key: entry.value.score})}',
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Text(
                    recommendation == null
                        ? 'Rekomendasi aktif: Belum ada'
                        : 'Rekomendasi aktif: ${store.materialById(recommendation.materialId)?.title ?? 'Materi tidak tersedia'}',
                  ),
                  if (recommendation != null)
                    Text(
                      '${recommendation.source == 'guru' ? 'Dari Guru' : 'Dari sistem'} · ${recommendation.reason}',
                    ),
                  for (final gap in materialGaps)
                    Text(
                      'Materi perlu disiapkan: ${aspectLabel(gap.aspect)} tingkat ${gap.level}. ${gap.reason}',
                    ),
                  const SizedBox(height: AppTokens.space12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Perlu pendampingan'),
                    value: learningStore.needsSupportForStudent(student.id),
                    onChanged: (value) =>
                        learningStore.setTeacherSupportFlag(student.id, value),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _chooseRecommendation(context, student.id),
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('Ganti rekomendasi latihan'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),
            TeacherPanel(
              title: 'Rekaman dan evaluasi',
              child: Column(
                children: [
                  for (final recording in store.recordings.where(
                    (item) => item.studentId == student.id,
                  ))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.mic_none_rounded),
                      title: Text(
                        '${aspectLabel(recording.aspect)} • ${recording.targetText}',
                      ),
                      subtitle: Text(
                        recording.status == 'dievaluasi'
                            ? 'Ketepatan ${recording.accuracyScore}% • Kelancaran ${recording.fluencyScore}%'
                            : 'Menunggu evaluasi',
                      ),
                    ),
                  if (!store.recordings.any(
                    (item) => item.studentId == student.id,
                  ))
                    const EmptyState(message: 'Belum ada aktivitas rekaman.'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _chooseRecommendation(
    BuildContext context,
    int studentId,
  ) async {
    final store = TeacherDemoStore.instance;
    final pageContext = context;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Pilih materi rekomendasi')),
            for (final item in store.materials.where(
              (item) =>
                  item.status == 'aktif' &&
                  store.practiceQuestionsForMaterial(item.id).isNotEmpty,
            ))
              ListTile(
                title: Text(item.title),
                subtitle: Text(
                  '${aspectLabel(item.aspect)} • tingkat ${item.level}',
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final controller = TextEditingController();
                  try {
                    final reason = await showDialog<String>(
                      context: pageContext,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Alasan perubahan'),
                        content: TextField(
                          controller: controller,
                          autofocus: true,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Alasan rekomendasi',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(
                              dialogContext,
                              controller.text.trim(),
                            ),
                            child: const Text('Simpan'),
                          ),
                        ],
                      ),
                    );
                    if (reason == null || !pageContext.mounted) return;
                    final saved = StudentDemoStore.instance
                        .setTeacherRecommendation(
                          studentId: studentId,
                          materialId: item.id,
                          reason: reason,
                        );
                    ScaffoldMessenger.of(pageContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          saved ? 'Rekomendasi diperbarui: ${item.title}' : 'Isi alasan dan pastikan materi dapat digunakan.',
                        ),
                      ),
                    );
                  } finally {
                    controller.dispose();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

String _masteryStatusLabel(String status) => switch (status) {
  'dikuasai' => 'Dikuasai',
  'sedang_berlatih' => 'Sedang dilatih',
  _ => 'Belum dikuasai',
};
