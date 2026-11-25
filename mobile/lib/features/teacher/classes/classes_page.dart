import 'package:flutter/material.dart';

import '../../../core/components/baca_button.dart';
import '../../../core/theme/app_tokens.dart';
import '../teacher_demo_store.dart';
import '../teacher_widgets.dart';

class ClassesPage extends StatelessWidget {
  const ClassesPage({
    super.key,
    this.rows,
    this.onAdd,
    this.onEdit,
    this.onDelete,
    this.onOpen,
  });
  final List<dynamic>? rows;
  final VoidCallback? onAdd;
  final ValueChanged<Map<String, dynamic>>? onEdit, onDelete, onOpen;

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        TeacherPageHeading(
          title: 'Data Kelas',
          subtitle:
              '${rows?.length ?? store.accessibleClasses.length} kelas${rows == null ? ' • Tahun ajaran 2026/2027' : ''}',
        ),
        BacaButton(
          key: const ValueKey('add-class'),
          label: 'Tambah kelas',
          icon: Icons.add_rounded,
          onPressed: onAdd ?? () => _editClass(context),
        ),
        const SizedBox(height: AppTokens.space16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 920
                ? (constraints.maxWidth - AppTokens.space24) / 3
                : constraints.maxWidth >= 600
                ? (constraints.maxWidth - AppTokens.space12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: AppTokens.space12,
              runSpacing: AppTokens.space12,
              children: [
                if (rows != null)
                  for (final row in rows!)
                    SizedBox(
                      width: width,
                      child: InkWell(
                        onTap: () => onOpen!(row),
                        child: _ClassCard(
                          id: row['id'],
                          name: row['nama_kelas'],
                          grade: row['tingkat'],
                          count: row['jumlah_siswa'],
                          year: row['tahun_ajaran'],
                          onEdit: () => onEdit!(row),
                          onDelete: () => onDelete!(row),
                        ),
                      ),
                    )
                else
                  for (final item in store.accessibleClasses)
                    SizedBox(
                      width: width,
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
                        onEdit: () => _editClass(context, id: item.id),
                      ),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _editClass(BuildContext context, {int? id}) {
    final store = TeacherDemoStore.instance;
    final current = id == null ? null : store.classById(id);
    final nameController = TextEditingController(text: current?.name ?? '');
    int grade = current?.grade ?? 1;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(current == null ? 'Tambah kelas' : 'Ubah kelas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama kelas'),
              ),
              const SizedBox(height: AppTokens.space16),
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: grade,
                decoration: const InputDecoration(labelText: 'Tingkat'),
                items: [
                  for (var i = 1; i <= 3; i++)
                    DropdownMenuItem(value: i, child: Text('Kelas $i')),
                ],
                onChanged: (value) =>
                    setDialogState(() => grade = value ?? grade),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final duplicate = store.accessibleClasses.any(
                  (item) =>
                      item.name.toLowerCase() == name.toLowerCase() &&
                      item.id != id,
                );
                if (duplicate) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama kelas sudah digunakan.'),
                    ),
                  );
                  return;
                }
                store.saveClass(id: id, name: name, grade: grade);
                Navigator.pop(dialogContext);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    ).whenComplete(nameController.dispose);
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
    this.onDelete,
  });

  final int id;
  final String name;
  final int grade;
  final int count;
  final String year;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    return TeacherPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Aksi kelas',
                onSelected: (value) {
                  if (value == 'delete') {
                    if (onDelete != null) {
                      onDelete!();
                      return;
                    }
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
          Text(
            'Kelas $grade • $year',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.space16),
          Row(
            children: [
              const Icon(
                Icons.people_outline_rounded,
                color: AppTokens.primary,
              ),
              const SizedBox(width: AppTokens.space8),
              Text('$count siswa'),
            ],
          ),
        ],
      ),
    );
  }
}
