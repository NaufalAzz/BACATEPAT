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
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final questions = store.questions
        .where(
          (item) =>
              item.prompt.toLowerCase().contains(_query) &&
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
          section: 'Bank Soal',
          title: 'Semua soal',
          subtitle:
              '${store.questions.length} soal · Pilihan ganda dan baca lisan',
          action: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('open-question-generator'),
                onPressed: () =>
                    Navigator.pushNamed(context, '/guru/soal/generator'),
                icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                label: const Text('Buat dengan AI'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FilledButton.icon(
                key: const ValueKey('add-question'),
                onPressed: () => _addQuestion(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Buat soal'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space8),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Cari soal...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (value) => setState(() => _query = value.toLowerCase()),
        ),
        const SizedBox(height: AppTokens.space12),
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
        const SizedBox(height: AppTokens.space12),
        if (questions.isEmpty)
          const TeacherPanel(
            child: EmptyState(
              message: 'Belum ada soal yang cocok dengan filter ini.',
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppTokens.surface,
              border: Border.all(color: AppTokens.outline),
              borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const _QuestionTableHeader(),
                for (final item in questions) ...[
                  _QuestionRow(
                    item: item,
                    onEdit: () => _editQuestion(context, item),
                    onAction: (action) =>
                        _handleQuestionAction(context, store, item, action),
                  ),
                  if (item.id != questions.last.id)
                    const Divider(height: 1, color: AppTokens.outline),
                ],
              ],
            ),
          ),
      ],
    );
  }

  void _handleQuestionAction(
    BuildContext context,
    TeacherDemoStore store,
    DemoQuestion item,
    String action,
  ) {
    if (action == 'edit') {
      _editQuestion(context, item);
      return;
    }
    if (action == 'delete') {
      if (!store.deleteQuestion(item.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Soal sudah digunakan tes dan tidak dapat dihapus.'),
          ),
        );
      }
      return;
    }
    final changed = store.setQuestionStatus(item.id, action);
    if (!changed && action == 'disetujui') {
      final issues = item
          .validationIssues(materials: store.materials)
          .join(' ');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(issues)));
    } else if (changed &&
        store.questionIsReferenced(item.id) &&
        action != item.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Versi yang dipakai tes tetap utuh; status perubahan dibuat sebagai versi baru.',
          ),
        ),
      );
    }
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

  void _addQuestion(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => const _QuestionEditorDialog(),
  );

  void _editQuestion(BuildContext context, DemoQuestion question) =>
      showDialog<void>(
        context: context,
        builder: (_) => _QuestionEditorDialog(question: question),
      );
}

class _QuestionEditorDialog extends StatefulWidget {
  const _QuestionEditorDialog({this.question});

  final DemoQuestion? question;

  @override
  State<_QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<_QuestionEditorDialog> {
  late final TextEditingController _prompt;
  late final TextEditingController _hint;
  late final TextEditingController _feedback;
  late final TextEditingController _target;
  late final TextEditingController _picture;
  late final List<TextEditingController> _choices;
  late String _aspect;
  late String _type;
  late String _usage;
  late int _level;
  int? _materialId;
  int? _answer;

  @override
  void initState() {
    super.initState();
    final item = widget.question;
    _prompt = TextEditingController(text: item?.prompt);
    _hint = TextEditingController(text: item?.hint);
    _feedback = TextEditingController(text: item?.correctFeedback);
    _target = TextEditingController(text: item?.targetText);
    _picture = TextEditingController(text: item?.picture);
    _choices = (item?.choices ?? const <String>[])
        .map((choice) => TextEditingController(text: choice))
        .toList();
    if (_choices.length < 2) {
      while (_choices.length < 3) {
        _choices.add(TextEditingController());
      }
    }
    _aspect = item?.aspect ?? 'huruf';
    _type = item?.type ?? 'Pilihan ganda';
    _usage = item?.usage ?? 'keduanya';
    _level = item?.level ?? 1;
    _materialId = item?.materialId;
    _answer = item?.correctAnswerIndex;
  }

  @override
  void dispose() {
    _prompt.dispose();
    _hint.dispose();
    _feedback.dispose();
    _target.dispose();
    _picture.dispose();
    for (final controller in _choices) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    return AlertDialog(
      title: Text(widget.question == null ? 'Tambah soal' : 'Edit soal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _prompt,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Pertanyaan/instruksi',
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            TextField(
              controller: _picture,
              decoration: const InputDecoration(
                labelText: 'Ilustrasi (emoji opsional)',
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            DropdownButtonFormField<int?>(
              isExpanded: true,
              initialValue: _materialId,
              decoration: const InputDecoration(labelText: 'Materi terkait'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Tanpa materi terkait'),
                ),
                for (final material in store.materials)
                  DropdownMenuItem<int?>(
                    value: material.id,
                    child: Text(
                      material.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _materialId = value),
            ),
            const SizedBox(height: AppTokens.space12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _aspect,
              decoration: const InputDecoration(labelText: 'Aspek'),
              items: const [
                DropdownMenuItem(value: 'huruf', child: Text('Huruf')),
                DropdownMenuItem(value: 'suku_kata', child: Text('Suku kata')),
                DropdownMenuItem(value: 'kata', child: Text('Kata')),
                DropdownMenuItem(
                  value: 'kalimat',
                  child: Text('Kalimat sederhana'),
                ),
              ],
              onChanged: (value) => setState(() => _aspect = value ?? _aspect),
            ),
            const SizedBox(height: AppTokens.space12),
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Tingkat kesulitan'),
              items: [
                for (var i = 1; i <= 3; i++)
                  DropdownMenuItem(value: i, child: Text('Tingkat $i')),
              ],
              onChanged: (value) => setState(() => _level = value ?? _level),
            ),
            const SizedBox(height: AppTokens.space12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Jenis soal'),
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
            const SizedBox(height: AppTokens.space12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _usage,
              decoration: const InputDecoration(labelText: 'Digunakan untuk'),
              items: const [
                DropdownMenuItem(
                  value: 'keduanya',
                  child: Text('Latihan dan diagnostik'),
                ),
                DropdownMenuItem(value: 'latihan', child: Text('Latihan')),
                DropdownMenuItem(
                  value: 'diagnostik',
                  child: Text('Diagnostik'),
                ),
              ],
              onChanged: (value) => setState(() => _usage = value ?? _usage),
            ),
            if (_type == 'Pilihan ganda') ...[
              const SizedBox(height: AppTokens.space16),
              RadioGroup<int>(
                groupValue: _answer,
                onChanged: (value) => setState(() => _answer = value),
                child: Column(
                  children: [
                    for (var i = 0; i < _choices.length; i++)
                      Row(
                        children: [
                          Radio<int>(value: i),
                          Expanded(
                            child: TextField(
                              controller: _choices[i],
                              decoration: InputDecoration(
                                labelText: 'Pilihan ${i + 1}',
                              ),
                            ),
                          ),
                          if (_choices.length > 2)
                            IconButton(
                              tooltip: 'Hapus pilihan',
                              onPressed: () => setState(() {
                                _choices.removeAt(i).dispose();
                                if (_answer == i) _answer = null;
                                if (_answer != null && _answer! > i) {
                                  _answer = _answer! - 1;
                                }
                              }),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _choices.length >= 5
                      ? null
                      : () => setState(
                          () => _choices.add(TextEditingController()),
                        ),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah pilihan'),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Pilih lingkaran untuk menetapkan kunci jawaban.'),
              ),
            ],
            if (_type == 'Baca lisan') ...[
              const SizedBox(height: AppTokens.space12),
              TextField(
                controller: _target,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Teks target'),
              ),
            ],
            const SizedBox(height: AppTokens.space12),
            TextField(
              controller: _hint,
              decoration: const InputDecoration(
                labelText: 'Petunjuk (opsional)',
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            TextField(
              controller: _feedback,
              decoration: const InputDecoration(
                labelText: 'Umpan balik benar (opsional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Simpan sebagai draf'),
        ),
      ],
    );
  }

  void _save() {
    if (_prompt.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pertanyaan atau instruksi harus diisi.')),
      );
      return;
    }
    final item = widget.question;
    final savedId = TeacherDemoStore.instance.saveQuestion(
      id: item?.id,
      prompt: _prompt.text,
      aspect: _aspect,
      level: _level,
      type: _type,
      materialId: _materialId,
      picture: _picture.text,
      choices: _choices.map((controller) => controller.text).toList(),
      correctAnswerIndex: _answer,
      hint: _hint.text,
      correctFeedback: _feedback.text,
      targetText: _target.text,
      usage: _usage,
    );
    final forked = item != null && savedId != item.id;
    Navigator.pop(context);
    if (forked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tes yang sudah memakai soal lama tetap memakai versi semula; perubahan disimpan sebagai draf baru.',
          ),
        ),
      );
    }
  }
}

class _QuestionTableHeader extends StatelessWidget {
  const _QuestionTableHeader();

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFF2F6F5),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: const Row(
      children: [
        Expanded(flex: 5, child: Text('SOAL', style: _questionHeaderStyle)),
        Expanded(flex: 2, child: Text('ASPEK', style: _questionHeaderStyle)),
        Expanded(flex: 2, child: Text('TINGKAT', style: _questionHeaderStyle)),
        SizedBox(width: 48),
      ],
    ),
  );
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.item,
    required this.onEdit,
    required this.onAction,
  });

  final DemoQuestion item;
  final VoidCallback onEdit;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onEdit,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.prompt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTokens.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${item.type} · ${item.status}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              aspectLabel(item.aspect),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Tingkat ${item.level}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Aksi soal',
            onSelected: onAction,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit soal')),
              if (item.status != 'disetujui')
                const PopupMenuItem(
                  value: 'disetujui',
                  child: Text('Setujui draf'),
                ),
              if (item.status == 'disetujui')
                const PopupMenuItem(
                  value: 'nonaktif',
                  child: Text('Nonaktifkan'),
                ),
              if (item.status == 'nonaktif')
                const PopupMenuItem(
                  value: 'draf',
                  child: Text('Kembalikan ke draf'),
                ),
              const PopupMenuItem(value: 'ditolak', child: Text('Tolak soal')),
              const PopupMenuItem(value: 'delete', child: Text('Hapus soal')),
            ],
          ),
        ],
      ),
    ),
  );
}

const _questionHeaderStyle = TextStyle(
  color: AppTokens.mutedText,
  fontSize: 9,
  fontWeight: FontWeight.w800,
);

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
              key: ValueKey('draft-question-${item.id}'),
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
                  if (item
                      .validationIssues(
                        materials: TeacherDemoStore.instance.materials,
                      )
                      .isNotEmpty) ...[
                    const SizedBox(height: AppTokens.space8),
                    Text(
                      'Belum siap: ${item.validationIssues(materials: TeacherDemoStore.instance.materials).join(' ')}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTokens.space12),
                  Wrap(
                    spacing: AppTokens.space8,
                    children: [
                      OutlinedButton(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => _QuestionEditorDialog(question: item),
                        ),
                        child: const Text('Lengkapi / edit'),
                      ),
                      FilledButton(
                        onPressed: () {
                          final approved = TeacherDemoStore.instance
                              .setQuestionStatus(item.id, 'disetujui');
                          if (!approved) {
                            final issues = item.validationIssues(
                              materials: TeacherDemoStore.instance.materials,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(issues.join(' '))),
                            );
                          }
                        },
                        child: const Text('Setujui soal'),
                      ),
                    ],
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
