import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../teacher_demo_store.dart';
import '../teacher_widgets.dart';

class QuestionsPage extends StatefulWidget {
  const QuestionsPage({super.key});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  int? _level;
  String _aspect = 'Semua aspek';
  String _type = 'Semua tipe';

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final questions = store.questions
        .where(
          (item) =>
              (_level == null || item.level == _level) &&
              (_aspect == 'Semua aspek' ||
                  aspectLabel(item.aspect) == _aspect) &&
              (_type == 'Semua tipe' || item.type == _type),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        TeacherPageHeading(
          title: 'Bank Soal',
          subtitle:
              '${store.questions.length} soal • Pilihan ganda dan baca lisan.',
        ),
        Wrap(
          spacing: AppTokens.space12,
          runSpacing: AppTokens.space12,
          children: [
            FilledButton.icon(
              key: const ValueKey('add-question'),
              onPressed: () => _addQuestion(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah soal'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('open-question-generator'),
              onPressed: () =>
                  Navigator.pushNamed(context, '/guru/soal/generator'),
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Generator soal AI'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space16),
        Wrap(
          spacing: AppTokens.space12,
          runSpacing: AppTokens.space12,
          children: [
            _filter<String>('Aspek', _aspect, [
              'Semua aspek',
              'Huruf',
              'Suku kata',
              'Kata',
              'Kalimat sederhana',
            ], (value) => setState(() => _aspect = value)),
            _filter<int?>(
              'Tingkat',
              _level,
              [null, 1, 2, 3],
              (value) => setState(() => _level = value),
              labels: ['Semua tingkat', 'Tingkat 1', 'Tingkat 2', 'Tingkat 3'],
            ),
            _filter<String>('Tipe soal', _type, [
              'Semua tipe',
              'Pilihan ganda',
              'Baca lisan',
            ], (value) => setState(() => _type = value)),
          ],
        ),
        const SizedBox(height: AppTokens.space16),
        if (questions.isEmpty)
          const TeacherPanel(
            child: EmptyState(
              message: 'Belum ada soal yang cocok dengan filter ini.',
            ),
          ),
        for (final item in questions)
          TeacherPanel(
            key: ValueKey('question-${item.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.prompt,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    StatusBadge(
                      label: item.status,
                      good: item.status == 'disetujui',
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  '${aspectLabel(item.aspect)} • tingkat ${item.level} • ${item.type}',
                ),
                const SizedBox(height: AppTokens.space8),
                Row(
                  children: [
                    const Icon(
                      Icons.play_circle_outline_rounded,
                      color: AppTokens.primary,
                    ),
                    const SizedBox(width: AppTokens.space8),
                    Expanded(
                      child: Text(
                        item.type == 'Baca lisan'
                            ? 'Teks target ditampilkan saat soal dibuka.'
                            : 'Pilihan jawaban tersedia untuk ditinjau.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Aksi soal',
                      onSelected: (value) {
                        if (value == 'delete') {
                          final deleted = store.deleteQuestion(item.id);
                          if (!deleted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Soal sudah digunakan tes dan tidak dapat dihapus.',
                                ),
                              ),
                            );
                          }
                        } else {
                          store.setQuestionStatus(item.id, value);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'disetujui',
                          child: Text('Setujui draf'),
                        ),
                        PopupMenuItem(
                          value: 'ditolak',
                          child: Text('Tolak draf'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Hapus soal'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _filter<T>(
    String label,
    T value,
    List<T> values,
    ValueChanged<T> onChanged, {
    List<String>? labels,
  }) => SizedBox(
    width: 190,
    child: DropdownButtonFormField<T>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (var i = 0; i < values.length; i++)
          DropdownMenuItem(
            value: values[i],
            child: Text(labels?[i] ?? values[i].toString()),
          ),
      ],
      onChanged: (value) {
        if (value != null || values.contains(null)) onChanged(value as T);
      },
    ),
  );

  void _addQuestion(BuildContext context) {
    final prompt = TextEditingController();
    String aspect = 'huruf';
    String type = 'Pilihan ganda';
    int level = 1;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah soal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: prompt,
                  decoration: const InputDecoration(labelText: 'Pertanyaan'),
                ),
                const SizedBox(height: AppTokens.space12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: aspect,
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
                      setDialogState(() => aspect = value ?? aspect),
                ),
                const SizedBox(height: AppTokens.space12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipe'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Pilihan ganda',
                      child: Text('Pilihan ganda'),
                    ),
                    DropdownMenuItem(
                      value: 'Baca lisan',
                      child: Text('Baca lisan'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => type = value ?? type),
                ),
                const SizedBox(height: AppTokens.space12),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: level,
                  decoration: const InputDecoration(labelText: 'Tingkat'),
                  items: [
                    for (var i = 1; i <= 3; i++)
                      DropdownMenuItem(value: i, child: Text('Tingkat $i')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => level = value ?? level),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (prompt.text.trim().isEmpty) return;
                TeacherDemoStore.instance.addQuestion(
                  prompt: prompt.text.trim(),
                  aspect: aspect,
                  level: level,
                  type: type,
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    ).whenComplete(prompt.dispose);
  }
}

class QuestionGeneratorPage extends StatefulWidget {
  const QuestionGeneratorPage({super.key});

  @override
  State<QuestionGeneratorPage> createState() => _QuestionGeneratorPageState();
}

class _QuestionGeneratorPageState extends State<QuestionGeneratorPage> {
  String _aspect = 'suku_kata';
  String _type = 'Pilihan ganda';
  int _level = 1;
  final _topic = TextEditingController();

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drafts = TeacherDemoStore.instance.questions
        .where((item) => item.status == 'draf')
        .toList();
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space16),
        children: [
          const TeacherPageHeading(
            title: 'Buat draf soal',
            subtitle: 'Simulasi generator untuk membantu menyiapkan soal; hasil perlu ditinjau Guru.',
          ),
          TeacherPanel(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
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
                const SizedBox(height: AppTokens.space16),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _level,
                  decoration: const InputDecoration(labelText: 'Tingkat'),
                  items: [
                    for (var i = 1; i <= 3; i++)
                      DropdownMenuItem(value: i, child: Text('Tingkat $i')),
                  ],
                  onChanged: (value) =>
                      setState(() => _level = value ?? _level),
                ),
                const SizedBox(height: AppTokens.space16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Tipe soal'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Pilihan ganda',
                      child: Text('Pilihan ganda'),
                    ),
                    DropdownMenuItem(
                      value: 'Baca lisan',
                      child: Text('Baca lisan'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? _type),
                ),
                const SizedBox(height: AppTokens.space16),
                TextField(
                  controller: _topic,
                  decoration: const InputDecoration(
                    labelText: 'Tema (opsional)',
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('generate-question'),
                    onPressed: _generate,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Buat draf simulasi'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space16),
          const TeacherPanel(
            child: Text(
              'Periksa kesesuaian, kejelasan bahasa, pilihan jawaban, dan kunci sebelum menyetujui soal.',
            ),
          ),
          const SizedBox(height: AppTokens.space24),
          Text(
            'Draf (${drafts.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final item in drafts)
            TeacherPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.prompt,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Text(
                    '${aspectLabel(item.aspect)} • tingkat ${item.level} • ${item.type}',
                  ),
                  const SizedBox(height: AppTokens.space12),
                  FilledButton(
                    onPressed: () => TeacherDemoStore.instance
                        .setQuestionStatus(item.id, 'disetujui'),
                    child: const Text('Setujui soal'),
                  ),
                ],
              ),
            ),
          if (drafts.isEmpty) const EmptyState(message: 'Belum ada draf soal.'),
        ],
      ),
    );
  }

  void _generate() {
    final theme = _topic.text.trim().isEmpty
        ? 'benda di sekitar'
        : _topic.text.trim();
    final prompt = _type == 'Baca lisan'
        ? 'Bacalah ${_aspect == 'kalimat' ? 'kalimat' : 'kata'} bertema $theme.'
        : 'Pilih jawaban yang tepat tentang $theme.';
    TeacherDemoStore.instance.addQuestion(
      prompt: prompt,
      aspect: _aspect,
      level: _level,
      type: _type,
      draft: true,
    );
  }
}
