import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../teacher_demo_store.dart';
import '../teacher_widgets.dart';

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        TeacherPageHeading(
          section: 'Data Kelas',
          title: 'Kelas Anda',
          subtitle:
              '${store.accessibleClasses.length} kelas · Tahun Ajaran 2026/2027',
          action: FilledButton.icon(
            key: const ValueKey('add-class'),
            onPressed: () => Navigator.pushNamed(context, '/guru/kelas/form'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah kelas'),
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
        for (final item in store.accessibleClasses)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space12),
            child: _ClassCard(
              id: item.id,
              name: item.name,
              grade: item.grade,
              count: store.accessibleStudents
                  .where(
                    (student) =>
                        student.classId == item.id && student.active,
                  )
                  .length,
              year: item.year,
              onEdit: () => Navigator.pushNamed(
                context,
                '/guru/kelas/form',
                arguments: item.id,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(top: AppTokens.space4),
          padding: const EdgeInsets.all(AppTokens.space12),
          decoration: BoxDecoration(
            color: AppTokens.sunshine,
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            border: Border.all(color: const Color(0xFFEBD78D)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: AppTokens.warning,
              ),
              SizedBox(width: AppTokens.space10),
              Expanded(
                child: Text(
                  'Kelas hanya dapat dihapus jika tidak memiliki siswa. Pindahkan siswa terlebih dahulu.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppTokens.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ClassFormPage extends StatefulWidget {
  const ClassFormPage({this.classId, super.key});

  final int? classId;

  @override
  State<ClassFormPage> createState() => _ClassFormPageState();
}

class _ClassFormPageState extends State<ClassFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late int _grade;

  @override
  void initState() {
    super.initState();
    final current = widget.classId == null
        ? null
        : TeacherDemoStore.instance.classById(widget.classId!);
    _name = TextEditingController(text: current?.name ?? '');
    _grade = current?.grade ?? 1;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.classId != null;
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        TeacherPageHeading(
          title: editing ? 'Ubah kelas' : 'Tambah kelas',
          subtitle: 'Lengkapi informasi kelas.',
        ),
        TeacherPanel(
          title: 'Informasi kelas',
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nama kelas'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama kelas wajib diisi.'
                      : null,
                ),
                const SizedBox(height: AppTokens.space16),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _grade,
                  decoration: const InputDecoration(labelText: 'Tingkat'),
                  items: [
                    for (var grade = 1; grade <= 3; grade++)
                      DropdownMenuItem(
                        value: grade,
                        child: Text('Kelas $grade'),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _grade = value ?? _grade),
                ),
                const SizedBox(height: AppTokens.space20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.maybePop(context),
                        child: const Text('Batal'),
                      ),
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: Text(
                          editing ? 'Simpan perubahan' : 'Simpan kelas',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final store = TeacherDemoStore.instance;
    final name = _name.text.trim();
    final duplicate = store.accessibleClasses.any(
      (item) =>
          item.name.toLowerCase() == name.toLowerCase() &&
          item.id != widget.classId,
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kelas sudah digunakan.')),
      );
      return;
    }
    store.saveClass(id: widget.classId, name: name, grade: _grade);
    Navigator.maybePop(context);
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.id,
    required this.name,
    required this.grade,
    required this.count,
    required this.year,
    required this.onEdit,
  });

  final int id;
  final String name;
  final int grade;
  final int count;
  final String year;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final tileColor = id.isEven ? AppTokens.sky : AppTokens.mint;
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: AppTokens.outline),
        boxShadow: AppTokens.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.space14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                  ),
                  child: Text(
                    name.replaceAll('Kelas ', '').split(' ').map((w) => w[0]).take(2).join(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.text,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTokens.sky,
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusRound,
                          ),
                        ),
                        child: Text(
                          'TINGKAT $grade',
                          style: const TextStyle(
                            fontSize: 9,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTokens.text,
                        ),
                      ),
                      Text(
                        '$year · ${store.teacherName}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTokens.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Aksi kelas',
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onSelected: (value) {
                    if (value == 'delete') {
                      if (store.accessibleStudents.any(
                        (item) => item.classId == id,
                      )) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Kelas berisi siswa dan belum dapat dihapus.',
                            ),
                          ),
                        );
                      } else {
                        store.deleteClass(id);
                      }
                    } else {
                      onEdit();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Ubah kelas')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus kelas')),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTokens.outline),
          InkWell(
            onTap: onEdit,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppTokens.radiusLarge),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space14,
                vertical: AppTokens.space10,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    size: 17,
                    color: AppTokens.text,
                  ),
                  const SizedBox(width: AppTokens.space8),
                  Expanded(
                    child: Text(
                      '$count siswa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTokens.text,
                      ),
                    ),
                  ),
                  const Text(
                    'Kelola kelas',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.text,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppTokens.text,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
