import 'package:flutter/material.dart';

import '../../../core/components/baca_button.dart';
import '../../../core/theme/app_tokens.dart';
import '../teacher_demo_store.dart';
import '../teacher_widgets.dart';

class MaterialsPage extends StatefulWidget {
  const MaterialsPage({super.key});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  String _aspect = 'Semua aspek';
  int? _level;
  String _status = 'Semua status';

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final materials = store.materials
        .where(
          (item) =>
              (_aspect == 'Semua aspek' ||
                  aspectLabel(item.aspect) == _aspect) &&
              (_level == null || item.level == _level) &&
              (_status == 'Semua status' || item.status == _status),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        TeacherPageHeading(
          title: 'Bank Materi',
          subtitle: '${store.materials.length} materi membaca tersimpan.',
        ),
        Wrap(
          spacing: AppTokens.space12,
          runSpacing: AppTokens.space12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              key: const ValueKey('add-material'),
              onPressed: () =>
                  Navigator.pushNamed(context, '/guru/materi/tambah'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah materi'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('open-material-generator'),
              onPressed: () =>
                  Navigator.pushNamed(context, '/guru/materi/generator'),
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Buat draf dengan AI'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space16),
        Wrap(
          spacing: AppTokens.space12,
          runSpacing: AppTokens.space12,
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _aspect,
                decoration: const InputDecoration(labelText: 'Aspek membaca'),
                items:
                    [
                          'Semua aspek',
                          'Huruf',
                          'Suku kata',
                          'Kata',
                          'Kalimat sederhana',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) =>
                    setState(() => _aspect = value ?? 'Semua aspek'),
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<int?>(
                isExpanded: true,
                initialValue: _level,
                decoration: const InputDecoration(labelText: 'Tingkat'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Semua tingkat'),
                  ),
                  for (var i = 1; i <= 3; i++)
                    DropdownMenuItem<int?>(value: i, child: Text('Tingkat $i')),
                ],
                onChanged: (value) => setState(() => _level = value),
              ),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Semua status', 'aktif', 'draf', 'arsip']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value == 'aktif'
                              ? 'Aktif'
                              : value == 'draf'
                              ? 'Draf'
                              : value == 'arsip'
                              ? 'Arsip'
                              : value,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _status = value ?? 'Semua status'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space16),
        if (materials.isEmpty)
          const TeacherPanel(
            child: EmptyState(message: 'Belum ada materi untuk filter ini.'),
          )
        else
          for (final item in materials)
            TeacherPanel(
              key: ValueKey('material-${item.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (item.fromAi) const StatusBadge(label: 'Dari AI'),
                      const SizedBox(width: AppTokens.space8),
                      StatusBadge(
                        label: item.status,
                        good: item.status == 'aktif',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Text(
                    '${aspectLabel(item.aspect)} • tingkat ${item.level}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Text(
                    item.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppTokens.space12),
                  Wrap(
                    spacing: AppTokens.space8,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/guru/materi/tambah',
                          arguments: item.id,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Ubah'),
                      ),
                      TextButton(
                        onPressed: () => store.setMaterialStatus(
                          item.id,
                          item.status == 'arsip' ? 'aktif' : 'arsip',
                        ),
                        child: Text(
                          item.status == 'arsip' ? 'Aktifkan' : 'Arsipkan',
                        ),
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

class MaterialFormPage extends StatefulWidget {
  const MaterialFormPage({this.materialId, super.key});

  final int? materialId;

  @override
  State<MaterialFormPage> createState() => _MaterialFormPageState();
}

class _MaterialFormPageState extends State<MaterialFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _content;
  late String _aspect;
  late int _level;

  DemoMaterial? get _material => widget.materialId == null
      ? null
      : TeacherDemoStore.instance.materialById(widget.materialId!);

  @override
  void initState() {
    super.initState();
    final item = _material;
    _title = TextEditingController(text: item?.title ?? '');
    _content = TextEditingController(text: item?.content ?? '');
    _aspect = item?.aspect ?? 'huruf';
    _level = item?.level ?? 1;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppTokens.space16),
            children: [
              const TeacherPageHeading(
                title: 'Materi membaca',
                subtitle: 'Susun materi yang sesuai dengan aspek dan tingkat belajar.',
              ),
              TextFormField(
                key: const ValueKey('material-title'),
                controller: _title,
                decoration: const InputDecoration(labelText: 'Judul materi'),
                validator: (value) => value == null || value.trim().length < 3
                    ? 'Judul minimal 3 karakter.'
                    : null,
              ),
              const SizedBox(height: AppTokens.space16),
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
                decoration: const InputDecoration(
                  labelText: 'Tingkat kesulitan',
                ),
                items: [
                  for (var i = 1; i <= 3; i++)
                    DropdownMenuItem(value: i, child: Text('Tingkat $i')),
                ],
                onChanged: (value) => setState(() => _level = value ?? _level),
              ),
              const SizedBox(height: AppTokens.space16),
              TextFormField(
                key: const ValueKey('material-content'),
                controller: _content,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(labelText: 'Konten materi'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Konten materi perlu diisi.'
                    : null,
              ),
              const SizedBox(height: AppTokens.space24),
              BacaButton(
                label: 'Simpan materi',
                icon: Icons.save_outlined,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    TeacherDemoStore.instance.saveMaterial(
      id: widget.materialId,
      title: _title.text.trim(),
      aspect: _aspect,
      level: _level,
      content: _content.text.trim(),
    );
    Navigator.pop(context);
  }
}

class MaterialGeneratorPage extends StatefulWidget {
  const MaterialGeneratorPage({super.key});

  @override
  State<MaterialGeneratorPage> createState() => _MaterialGeneratorPageState();
}

class _MaterialGeneratorPageState extends State<MaterialGeneratorPage> {
  final _theme = TextEditingController();
  String _aspect = 'suku_kata';
  int _level = 1;
  bool _generating = false;

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drafts = TeacherDemoStore.instance.materials
        .where((item) => item.fromAi && item.status == 'draf')
        .toList();
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space16),
        children: [
          const TeacherPageHeading(
            title: 'Buat draf materi',
            subtitle: 'Simulasi antarmuka generator; tidak mengirim data ke layanan AI.',
          ),
          TeacherPanel(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _aspect,
                  decoration: const InputDecoration(labelText: 'Aspek membaca'),
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
                TextField(
                  controller: _theme,
                  decoration: const InputDecoration(
                    labelText: 'Tema materi (contoh: hewan)',
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                BacaButton(
                  key: const ValueKey('generate-material'),
                  label: _generating
                      ? 'Menyiapkan draf…'
                      : 'Buat draf simulasi',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: _generating ? null : _generate,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space16),
          const TeacherPanel(
            child: Text(
              'AI dapat salah. Tinjau dan ubah setiap draf sebelum menyetujuinya.',
            ),
          ),
          const SizedBox(height: AppTokens.space24),
          Text(
            'Draf untuk ditinjau (${drafts.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTokens.space12),
          if (drafts.isEmpty)
            const EmptyState(
              message: 'Belum ada draf. Isi tema lalu buat simulasi.',
            ),
          for (final item in drafts)
            TeacherPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Text(item.content),
                  const SizedBox(height: AppTokens.space12),
                  Wrap(
                    spacing: AppTokens.space8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => TeacherDemoStore.instance
                            .setMaterialStatus(item.id, 'aktif'),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Setujui'),
                      ),
                      TextButton(
                        onPressed: () => TeacherDemoStore.instance
                            .setMaterialStatus(item.id, 'arsip'),
                        child: const Text('Tolak'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final theme = _theme.text.trim().isEmpty
        ? 'kegiatan sehari-hari'
        : _theme.text.trim();
    TeacherDemoStore.instance.saveMaterial(
      title: '${aspectLabel(_aspect)} bertema $theme',
      aspect: _aspect,
      level: _level,
      content: _aspect == 'suku_kata'
          ? 'ba bi bu be bo • ca ci cu ce co'
          : 'Materi contoh tentang $theme.',
      fromAi: true,
    );
    setState(() => _generating = false);
  }
}
