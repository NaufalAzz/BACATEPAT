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
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        AppTokens.space16,
        AppTokens.space16,
        AppTokens.space24,
      ),
      children: [
        TeacherPageHeading(
          section: 'Data Siswa',
          title: 'Semua siswa',
          subtitle:
              '${store.activeStudents.length} siswa dari ${store.accessibleClasses.length} kelas',
          action: FilledButton.icon(
            key: const ValueKey('add-student'),
            onPressed: () => Navigator.pushNamed(context, '/guru/siswa/form'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah siswa'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  key: const ValueKey('student-search'),
                  controller: _searchController,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: const InputDecoration(
                    hintText: 'Cari nama atau username',
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.space8),
            SizedBox(
              height: 40,
              width: 136,
              child: DropdownButtonFormField<int?>(
                isExpanded: true,
                initialValue: _classFilter,
                style: const TextStyle(fontSize: 12.5, color: AppTokens.text),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Semua kelas'),
                  ),
                  for (final item in store.accessibleClasses)
                    DropdownMenuItem<int?>(
                      value: item.id,
                      child: Text(item.name),
                    ),
                ],
                onChanged: (value) => setState(() => _classFilter = value),
              ),
            ),
            const SizedBox(width: AppTokens.space8),
            _StatusChip(
              label: _showInactive ? 'Semua' : 'Aktif',
              selected: !_showInactive,
              onTap: () => setState(() => _showInactive = !_showInactive),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space12),
        if (filtered.isEmpty)
          const TeacherPanel(
            padding: EdgeInsets.all(AppTokens.space32),
            child: EmptyState(
              message: 'Belum ada siswa yang cocok dengan pencarian ini.',
              icon: Icons.search_off_rounded,
            ),
          )
        else
          TeacherPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const _TableHeader(),
                for (var i = 0; i < filtered.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppTokens.outline),
                  _StudentRow(
                    key: ValueKey('student-row-${filtered[i].id}'),
                    student: filtered[i],
                    store: store,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/guru/siswa/detail',
                      arguments: filtered[i].id,
                    ),
                    onEdit: () => Navigator.pushNamed(
                      context,
                      '/guru/siswa/form',
                      arguments: filtered[i].id,
                    ),
                    onStatusToggle: () {
                      TeacherDemoStore.instance.toggleStudentActive(
                        filtered[i].id,
                      );
                      setState(() {});
                    },
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
    child: Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: AppTokens.outline),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: AppTokens.text,
        ),
      ),
    ),
  );
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
    decoration: const BoxDecoration(
      color: Color(0xFFF7F9F8),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTokens.radiusXLarge),
      ),
    ),
    child: Row(
      children: [
        const Expanded(flex: 4, child: _HeaderLabel('Siswa')),
        const Expanded(flex: 2, child: _HeaderLabel('Kelas')),
        Expanded(
          flex: 4,
          child: Align(
            alignment: Alignment.centerRight,
            child: _HeaderLabel('Status'),
          ),
        ),
      ],
    ),
  );
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      fontSize: 9.5,
      letterSpacing: 0.7,
      fontWeight: FontWeight.w800,
      color: AppTokens.mutedText,
    ),
  );
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    super.key,
    required this.student,
    required this.store,
    required this.onTap,
    required this.onEdit,
    required this.onStatusToggle,
  });

  final DemoStudent student;
  final TeacherDemoStore store;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onStatusToggle;

  @override
  Widget build(BuildContext context) {
    final needsSupport = StudentDemoStore.instance.needsSupportForStudent(
      student.id,
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  TeacherAvatar(
                    name: student.name,
                    radius: 16,
                    backgroundColor: const Color(0xFFDCEBE4),
                  ),
                  const SizedBox(width: AppTokens.space10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.text,
                          ),
                        ),
                        Text(
                          student.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppTokens.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                store.className(student.classId),
                style: const TextStyle(fontSize: 11.5, color: AppTokens.text),
              ),
            ),
            Expanded(
              flex: 4,
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 2,
                children: [
                  if (!student.active)
                    const _StatusPill(label: 'Nonaktif', muted: true)
                  else if (needsSupport)
                    const Text(
                      'Perlu dampingan',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.coralDark,
                      ),
                    )
                  else
                    const _StatusPill(label: 'Aktif'),
                  PopupMenuButton<String>(
                    tooltip: 'Aksi siswa',
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    onSelected: (value) => value == 'edit'
                        ? onEdit()
                        : onStatusToggle(),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Ubah data'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(
                              student.active
                                  ? Icons.person_off_outlined
                                  : Icons.person_add_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              student.active ? 'Nonaktifkan' : 'Aktifkan',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: muted ? const Color(0xFFF0F2F1) : AppTokens.mint,
      borderRadius: BorderRadius.circular(AppTokens.radiusRound),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        color: muted ? AppTokens.mutedText : AppTokens.primary,
      ),
    ),
  );
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
                TeacherPageHeading(
                  title: isEditing ? 'Ubah Data Siswa' : 'Tambah Siswa Baru',
                  subtitle: 'Isi informasi dasar dan persetujuan wali.',
                ),
                TeacherPanel(
                  padding: const EdgeInsets.all(AppTokens.space20),
                  child: Column(
                    children: [
                      TextFormField(
                        key: const ValueKey('form-student-name'),
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Nama lengkap',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) => value == null || value.trim().length < 2
                            ? 'Nama minimal 2 karakter.'
                            : null,
                      ),
                      const SizedBox(height: AppTokens.space16),
                      TextFormField(
                        key: const ValueKey('form-student-username'),
                        controller: _username,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
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
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          validator: _validatePassword,
                        ),
                      ],
                      const SizedBox(height: AppTokens.space16),
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: _classId,
                        decoration: const InputDecoration(
                          labelText: 'Kelas',
                          prefixIcon: Icon(Icons.class_outlined),
                        ),
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
                        decoration: const InputDecoration(
                          labelText: 'Nama wali',
                          prefixIcon: Icon(Icons.family_restroom_rounded),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Nama wali perlu diisi.'
                            : null,
                      ),
                      const SizedBox(height: AppTokens.space20),
                      Card(
                        color: AppTokens.sky,
                        child: Column(
                          children: [
                            SwitchListTile.adaptive(
                              key: const ValueKey('parent-consent'),
                              title: const Text('Persetujuan wali untuk rekaman'),
                              subtitle: const Text(
                                'Rekaman tidak dapat dibuat tanpa persetujuan ini.',
                              ),
                              value: _parentConsent,
                              activeThumbColor: AppTokens.primary,
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
                              activeThumbColor: AppTokens.primary,
                              onChanged: _parentConsent
                                  ? (value) => setState(() => _aiConsent = value)
                                  : null,
                            ),
                          ],
                        ),
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
                  const SizedBox(height: AppTokens.space12),
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
      return Scaffold(
        body: Center(
          child: EmptyState(message: 'Data siswa tidak ditemukan.'),
        ),
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
              subtitle: 'Kelas ${store.className(student.classId)} • @${student.username}',
            ),
            _StudentInfoCard(student: student),
            const SizedBox(height: AppTokens.space16),
            _MasteryCard(
              latestMastery: latestMastery,
              store: store,
            ),
            const SizedBox(height: AppTokens.space16),
            _DiagnosticResultsCard(
              teacherId: teacherId,
              student: student,
              store: store,
              learningStore: learningStore,
            ),
            const SizedBox(height: AppTokens.space16),
            _RecommendationCard(
              student: student,
              recommendation: recommendation,
              materialGaps: materialGaps,
              latestMastery: latestMastery,
              store: store,
              learningStore: learningStore,
              onChangeRecommendation: () => _chooseRecommendation(context, student.id),
            ),
            const SizedBox(height: AppTokens.space16),
            _RecordingsCard(student: student, store: store),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusXLarge),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.space16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pilih Materi Rekomendasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(AppTokens.space16),
                  children: [
                    for (final item in store.materials.where(
                      (item) =>
                          item.status == 'aktif' &&
                          store.practiceQuestionsForMaterial(item.id).isNotEmpty,
                    ))
                      _RecommendationMaterialTile(
                        item: item,
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
                                  saved
                                      ? 'Rekomendasi diperbarui: ${item.title}'
                                      : 'Isi alasan dan pastikan materi dapat digunakan.',
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
            ],
          ),
        ),
      ),
    ).whenComplete(() {});
  }
}

class _RecommendationMaterialTile extends StatelessWidget {
  const _RecommendationMaterialTile({
    required this.item,
    required this.onTap,
  });

  final DemoMaterial item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppTokens.space8),
    child: ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _aspectColor(item.aspect).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        child: Icon(
          _aspectIcon(item.aspect),
          color: _aspectColor(item.aspect),
          size: 22,
        ),
      ),
      title: Text(
        item.title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        '${aspectLabel(item.aspect)} • tingkat ${item.level}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTokens.mutedText,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

Color _aspectColor(String aspect) => switch (aspect) {
  'huruf' => const Color(0xFFFFB74D),
  'suku_kata' => const Color(0xFF81C784),
  'kata' => const Color(0xFF64B5F6),
  'kalimat' => const Color(0xFFE57373),
  _ => AppTokens.primary,
};

IconData _aspectIcon(String aspect) => switch (aspect) {
  'huruf' => Icons.text_fields_rounded,
  'suku_kata' => Icons.format_list_bulleted_rounded,
  'kata' => Icons.auto_stories_rounded,
  'kalimat' => Icons.menu_book_rounded,
  _ => Icons.auto_stories_rounded,
};

class _StudentInfoCard extends StatelessWidget {
  const _StudentInfoCard({required this.student});

  final DemoStudent student;

  @override
  Widget build(BuildContext context) => TeacherPanel(
    title: 'Informasi siswa',
    padding: const EdgeInsets.all(AppTokens.space20),
    child: Wrap(
      spacing: AppTokens.space12,
      runSpacing: AppTokens.space12,
      children: [
        StatusBadge(
          label: student.active ? 'Aktif' : 'Nonaktif',
          variant: student.active ? StatusVariant.active : StatusVariant.neutral,
        ),
        StatusBadge(
          label: student.parentConsent
              ? 'Persetujuan rekaman: ya'
              : 'Persetujuan rekaman: belum',
          variant: student.parentConsent ? StatusVariant.success : StatusVariant.warning,
        ),
        StatusBadge(
          label: student.aiConsent
              ? 'Persetujuan AI: ya'
              : 'Persetujuan AI: tidak',
          variant: student.aiConsent ? StatusVariant.info : StatusVariant.neutral,
        ),
      ],
    ),
  );
}

class _MasteryCard extends StatelessWidget {
  const _MasteryCard({
    required this.latestMastery,
    required this.store,
  });

  final Map<String, MasteryRecord?> latestMastery;
  final TeacherDemoStore store;

  @override
  Widget build(BuildContext context) => TeacherPanel(
    title: 'Penguasaan membaca',
    padding: const EdgeInsets.all(AppTokens.space20),
    child: latestMastery.isEmpty
        ? EmptyState(
            message: 'Belum ada catatan penguasaan dari diagnostik lengkap.',
            icon: Icons.assignment_outlined,
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
                  _MasteryRow(
                    record: record,
                    aspectColor: _aspectColor(record.aspect),
                  ),
            ],
          ),
  );
}

class _MasteryRow extends StatelessWidget {
  const _MasteryRow({
    required this.record,
    required this.aspectColor,
  });

  final MasteryRecord record;
  final Color aspectColor;

  @override
  Widget build(BuildContext context) {
    final isMastered = record.score >= 60;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: aspectColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
            ),
            child: Icon(
              _aspectIcon(record.aspect),
              color: aspectColor,
              size: 22,
            ),
          ),
          const SizedBox(width: AppTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aspectLabel(record.aspect),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isMastered ? AppTokens.text : AppTokens.mutedText,
                  ),
                ),
                const SizedBox(height: AppTokens.space4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusRound),
                  child: LinearProgressIndicator(
                    value: record.score / 100,
                    minHeight: 8,
                    backgroundColor: AppTokens.outline,
                    color: record.score < 60
                        ? AppTokens.warning
                        : record.score < 80
                            ? AppTokens.accent
                            : AppTokens.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.space12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.score}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isMastered ? AppTokens.success : AppTokens.warning,
                ),
              ),
              Text(
                _masteryStatusLabel(record.status),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: aspectColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _masteryStatusLabel(String status) => switch (status) {
    'dikuasai' => 'Dikuasai',
    'sedang_berlatih' => 'Sedang dilatih',
    _ => 'Belum dikuasai',
  };
}

class _DiagnosticResultsCard extends StatelessWidget {
  const _DiagnosticResultsCard({
    required this.teacherId,
    required this.student,
    required this.store,
    required this.learningStore,
  });

  final int teacherId;
  final DemoStudent student;
  final TeacherDemoStore store;
  final StudentDemoStore learningStore;

  @override
  Widget build(BuildContext context) {
    final diagnostic = learningStore.latestDiagnosticForTeacher(
      teacherId,
      student.id,
    );
    return TeacherPanel(
      title: 'Hasil diagnostik',
      padding: const EdgeInsets.all(AppTokens.space20),
      child: diagnostic == null
          ? EmptyState(
              message: 'Belum ada hasil diagnostik untuk siswa ini.',
              icon: Icons.assignment_outlined,
            )
          : Column(
              children: [
                for (final entry in diagnostic.aspectScores.entries)
                  _DiagnosticScoreRow(
                    aspect: entry.key,
                    score: entry.value,
                  ),
              ],
            ),
    );
  }
}

class _DiagnosticScoreRow extends StatelessWidget {
  const _DiagnosticScoreRow({
    required this.aspect,
    required this.score,
  });

  final String aspect;
  final int score;

  Color get _progressColor {
    if (score < 60) return AppTokens.warning;
    if (score < 80) return AppTokens.accent;
    return AppTokens.success;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _aspectColor(aspect).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          ),
          child: Icon(
            _aspectIcon(aspect),
            color: _aspectColor(aspect),
            size: 22,
          ),
        ),
        const SizedBox(width: AppTokens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                aspectLabel(aspect),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTokens.space4),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusRound),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 8,
                  backgroundColor: AppTokens.outline,
                  color: _progressColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTokens.space12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$score%',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: _progressColor,
              ),
            ),
            Text(
              _masteryLabel(score),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _progressColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  String _masteryLabel(int score) => score < 60
      ? 'Belum dikuasai'
      : score < 80
      ? 'Sedang berlatih'
      : 'Dikuasai';
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.student,
    required this.recommendation,
    required this.materialGaps,
    required this.latestMastery,
    required this.store,
    required this.learningStore,
    required this.onChangeRecommendation,
  });

  final DemoStudent student;
  final LearningRecommendation? recommendation;
  final List<MaterialGapRecord> materialGaps;
  final Map<String, MasteryRecord> latestMastery;
  final TeacherDemoStore store;
  final StudentDemoStore learningStore;
  final VoidCallback onChangeRecommendation;

  @override
  Widget build(BuildContext context) => TeacherPanel(
    title: 'Rekomendasi dan pendampingan',
    padding: const EdgeInsets.all(AppTokens.space20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan: ${masterySummaryFor({for (final entry in latestMastery.entries) entry.key: entry.value.score})}',
        ),
        const SizedBox(height: AppTokens.space12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rekomendasi aktif',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTokens.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    recommendation == null
                        ? 'Belum ada'
                        : store.materialById(recommendation!.materialId)?.title ?? 'Materi tidak tersedia',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (recommendation != null) ...[
                    const SizedBox(height: AppTokens.space4),
                    Text(
                      '${recommendation!.source == 'guru' ? 'Dari Guru' : 'Dari sistem'} · ${recommendation!.reason}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTokens.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: onChangeRecommendation,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Ganti rekomendasi'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space12),
        if (materialGaps.isNotEmpty) ...[
          for (final gap in materialGaps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space6),
              child: Row(
                children: [
                  Icon(
                    Icons.library_add_rounded,
                    size: 18,
                    color: AppTokens.warning,
                  ),
                  const SizedBox(width: AppTokens.space8),
                  Expanded(
                    child: Text(
                      'Materi perlu disiapkan: ${aspectLabel(gap.aspect)} tingkat ${gap.level}. ${gap.reason}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTokens.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: AppTokens.space16),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Perlu pendampingan'),
          subtitle: const Text('Tandai jika siswa ini memerlukan perhatian khusus'),
          value: learningStore.needsSupportForStudent(student.id),
          activeThumbColor: AppTokens.primary,
          onChanged: (value) =>
              learningStore.setTeacherSupportFlag(student.id, value),
        ),
      ],
    ),
  )

  // Need to get latestMastery from parent - passing via getter would be cleaner
  // For now, using a workaround
  ;
}

class _RecordingsCard extends StatelessWidget {
  const _RecordingsCard({
    required this.student,
    required this.store,
  });

  final DemoStudent student;
  final TeacherDemoStore store;

  @override
  Widget build(BuildContext context) => TeacherPanel(
    title: 'Rekaman dan evaluasi',
    padding: const EdgeInsets.all(AppTokens.space20),
    child: Column(
      children: [
        for (final recording in store.recordings.where(
          (item) => item.studentId == student.id,
        ))
          _RecordingTile(recording: recording),
        if (!store.recordings.any(
          (item) => item.studentId == student.id,
        ))
          EmptyState(
            message: 'Belum ada aktivitas rekaman.',
            icon: Icons.mic_none_rounded,
          ),
      ],
    ),
  );
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({required this.recording});

  final DemoRecording recording;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppTokens.secondary.withValues(alpha: 0.12),
          child: Icon(
            Icons.graphic_eq_rounded,
            color: AppTokens.secondary,
            size: 20,
          ),
        ),
        const SizedBox(width: AppTokens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${aspectLabel(recording.aspect)} • ${recording.targetText}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                recording.status == 'dievaluasi'
                    ? 'Ketepatan ${recording.accuracyScore}% • Kelancaran ${recording.fluencyScore}%'
                    : 'Menunggu evaluasi',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.mutedText,
                ),
              ),
            ],
          ),
        ),
        StatusBadge(
          label: recording.status == 'dievaluasi' ? 'Selesai' : 'Menunggu',
          variant: recording.status == 'dievaluasi' ? StatusVariant.success : StatusVariant.pending,
        ),
      ],
    ),
  );
}