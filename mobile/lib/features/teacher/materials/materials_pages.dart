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
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final materials = store.materials
        .where(
          (item) =>
              item.title.toLowerCase().contains(_query) &&
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
          section: 'Bank Materi',
          title: 'Semua materi',
          subtitle:
              '${store.materials.length} materi · ${store.materials.where((item) => item.status == 'aktif').length} aktif',
          action: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/guru/materi/generator'),
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
                onPressed: () =>
                    Navigator.pushNamed(context, '/guru/materi/tambah'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Buat materi'),
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
        _FilterBar(
          aspect: _aspect,
          level: _level,
          status: _status,
          onQueryChanged: (value) =>
              setState(() => _query = value.toLowerCase()),
          onAspectChanged: (value) =>
              setState(() => _aspect = value ?? 'Semua aspek'),
          onLevelChanged: (value) => setState(() => _level = value),
          onStatusChanged: (value) =>
              setState(() => _status = value ?? 'Semua status'),
        ),
        const SizedBox(height: AppTokens.space20),
        if (materials.isEmpty)
          TeacherPanel(
            child: EmptyState(
              message: 'Belum ada materi untuk filter ini.',
              icon: Icons.menu_book_outlined,
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
                const _MaterialTableHeader(),
                for (var index = 0; index < materials.length; index++)
                  _MaterialCard(
                    item: materials[index],
                    showDivider: index < materials.length - 1,
                    onEdit: () => Navigator.pushNamed(
                      context,
                      '/guru/materi/tambah',
                      arguments: materials[index].id,
                    ),
                    onStatusToggle: () => store.setMaterialStatus(
                      materials[index].id,
                      materials[index].status == 'arsip' ? 'aktif' : 'arsip',
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.aspect,
    required this.level,
    required this.status,
    required this.onQueryChanged,
    required this.onAspectChanged,
    required this.onLevelChanged,
    required this.onStatusChanged,
  });

  final String aspect;
  final int? level;
  final String status;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onAspectChanged;
  final ValueChanged<int?> onLevelChanged;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        decoration: const InputDecoration(
          hintText: 'Cari materi...',
          prefixIcon: Icon(Icons.search_rounded),
        ),
        onChanged: onQueryChanged,
      ),
      const SizedBox(height: AppTokens.space12),
      Wrap(
        spacing: AppTokens.space12,
        runSpacing: AppTokens.space12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: aspect,
              decoration: InputDecoration(
                labelText: 'Aspek membaca',
                filled: true,
                fillColor: AppTokens.surface,
              ),
              items:
                  [
                        'Semua aspek',
                        'Huruf',
                        'Suku kata',
                        'Kata',
                        'Kalimat sederhana',
                      ]
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
              onChanged: onAspectChanged,
            ),
          ),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<int?>(
              isExpanded: true,
              initialValue: level,
              decoration: InputDecoration(
                labelText: 'Tingkat',
                filled: true,
                fillColor: AppTokens.surface,
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Semua tingkat'),
                ),
                for (var i = 1; i <= 3; i++)
                  DropdownMenuItem<int?>(value: i, child: Text('Tingkat $i')),
              ],
              onChanged: onLevelChanged,
            ),
          ),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: status,
              decoration: InputDecoration(
                labelText: 'Status',
                filled: true,
                fillColor: AppTokens.surface,
              ),
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
              onChanged: onStatusChanged,
            ),
          ),
        ],
      ),
    ],
  );
}

class _MaterialTableHeader extends StatelessWidget {
  const _MaterialTableHeader();

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFF2F6F5),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Row(
      children: [
        const Expanded(
          flex: 5,
          child: Text('MATERI', style: _tableHeaderStyle),
        ),
        const Expanded(flex: 2, child: Text('ASPEK', style: _tableHeaderStyle)),
        const Expanded(
          flex: 2,
          child: Text('TINGKAT', style: _tableHeaderStyle),
        ),
        const SizedBox(width: 48),
      ],
    ),
  );
}

const _tableHeaderStyle = TextStyle(
  color: AppTokens.mutedText,
  fontSize: 9,
  fontWeight: FontWeight.w800,
);

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    required this.item,
    required this.onEdit,
    required this.onStatusToggle,
    required this.showDivider,
  });

  final DemoMaterial item;
  final VoidCallback onEdit;
  final VoidCallback onStatusToggle;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      InkWell(
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
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTokens.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.fromAi
                          ? 'Dibuat dengan AI'
                          : _statusLabel(item.status),
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
                tooltip: 'Aksi materi',
                onSelected: (action) {
                  if (action == 'edit') onEdit();
                  if (action == 'status') onStatusToggle();
                  if (action == 'approve') {
                    TeacherDemoStore.instance.setMaterialStatus(
                      item.id,
                      'aktif',
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                  PopupMenuItem(
                    value: 'status',
                    child: Text(
                      item.status == 'arsip' ? 'Aktifkan' : 'Arsipkan',
                    ),
                  ),
                  if (item.status == 'draf')
                    const PopupMenuItem(
                      value: 'approve',
                      child: Text('Setujui'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      if (showDivider) const Divider(height: 1, color: AppTokens.outline),
    ],
  );
}

String _statusLabel(String status) => switch (status) {
  'aktif' => 'Aktif',
  'draf' => 'Draf',
  'arsip' => 'Arsip',
  _ => status,
};

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
              TeacherPageHeading(
                section: 'Tambah Materi',
                title: _material == null ? 'Detail materi' : 'Ubah materi',
                subtitle:
                    'Gunakan bahasa singkat dan sesuai tingkat siswa.',
              ),
              TeacherFormPanel(
                saveLabel: 'Simpan materi',
                onCancel: () => Navigator.pop(context),
                onSave: _save,
                sections: [
                  TeacherFormSection(
                    title: 'Detail materi',
                    description:
                        'Gunakan bahasa singkat dan sesuai tingkat siswa.',
                    children: [
                      TextFormField(
                        controller: _title,
                        decoration: const InputDecoration(
                          labelText: 'Judul materi',
                          hintText: 'Contoh: Kata di sekitarku',
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 3
                            ? 'Judul minimal 3 karakter.'
                            : null,
                      ),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _aspect,
                        decoration: const InputDecoration(
                          labelText: 'Aspek membaca',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'huruf',
                            child: Text('Huruf'),
                          ),
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
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: _level,
                        decoration: const InputDecoration(
                          labelText: 'Tingkat kesulitan',
                        ),
                        items: [
                          for (var i = 1; i <= 3; i++)
                            DropdownMenuItem(
                              value: i,
                              child: Text('Tingkat $i'),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _level = value ?? _level),
                      ),
                      TextFormField(
                        controller: _content,
                        minLines: 6,
                        maxLines: 12,
                        decoration: const InputDecoration(
                          labelText: 'Konten materi',
                          hintText: 'Tulis konten bacaan di sini...',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Konten materi perlu diisi.'
                            : null,
                      ),
                    ],
                  ),
                ],
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
        padding: const EdgeInsets.all(AppTokens.space20),
        children: [
          TeacherPageHeading(
            title: 'Buat draf materi',
            subtitle: 'Simulasi antarmuka generator; tidak mengirim data ke layanan AI.',
          ),
          TeacherPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _aspect,
                  decoration: const InputDecoration(
                    labelText: 'Aspek membaca',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
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
                const SizedBox(height: AppTokens.space20),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _level,
                  decoration: const InputDecoration(
                    labelText: 'Tingkat',
                    prefixIcon: Icon(Icons.trending_up_rounded),
                  ),
                  items: [
                    for (var i = 1; i <= 3; i++)
                      DropdownMenuItem(value: i, child: Text('Tingkat $i')),
                  ],
                  onChanged: (value) =>
                      setState(() => _level = value ?? _level),
                ),
                const SizedBox(height: AppTokens.space20),
                TextField(
                  controller: _theme,
                  decoration: const InputDecoration(
                    labelText: 'Tema materi (contoh: hewan)',
                    prefixIcon: Icon(Icons.topic_outlined),
                  ),
                ),
                const SizedBox(height: AppTokens.space24),
                BacaButton(
                  label: _generating
                      ? 'Menyiapkan draf…'
                      : 'Buat draf simulasi',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: _generating ? null : _generate,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space20),
          TeacherPanel(
            color: AppTokens.sky,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppTokens.secondary,
                  size: 22,
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: Text(
                    'AI dapat salah. Tinjau dan ubah setiap draf sebelum menyetujuinya.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTokens.text),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space24),
          Text(
            'Draf untuk ditinjau (${drafts.length})',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTokens.space16),
          if (drafts.isEmpty)
            TeacherPanel(
              child: EmptyState(
                message: 'Belum ada draf. Isi tema lalu buat simulasi.',
                icon: Icons.auto_awesome_outlined,
              ),
            )
          else
            for (final item in drafts) _DraftCard(item: item),
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

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.item});

  final DemoMaterial item;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppTokens.space12),
    child: Padding(
      padding: const EdgeInsets.all(AppTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppTokens.space4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space10,
                        vertical: AppTokens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTokens.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusRound,
                        ),
                      ),
                      child: Text(
                        'Draf dari AI',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTokens.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(label: 'Draf', variant: StatusVariant.pending),
            ],
          ),
          const SizedBox(height: AppTokens.space12),
          Text(
            item.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppTokens.space16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => TeacherDemoStore.instance.setMaterialStatus(
                    item.id,
                    'aktif',
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Setujui'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTokens.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.space14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => TeacherDemoStore.instance.setMaterialStatus(
                    item.id,
                    'arsip',
                  ),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Tolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTokens.error,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.space14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
