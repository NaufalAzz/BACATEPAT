import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
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
          title: 'Tes Diagnostik',
          subtitle: 'Susun tes dari soal yang telah ditinjau, lalu aktifkan untuk kelas.',
        ),
        FilledButton.icon(
          key: const ValueKey('create-diagnostic'),
          onPressed: () => _createDiagnostic(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Buat tes diagnostik'),
        ),
        const SizedBox(height: AppTokens.space16),
        if (store.diagnostics.isEmpty)
          const TeacherPanel(
            child: EmptyState(message: 'Belum ada tes diagnostik.'),
          ),
        for (final test in store.diagnostics)
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
                      label: test.status,
                      good: test.status == 'aktif',
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                activated ? 'Tes diaktifkan.' : 'Tambahkan minimal satu soal untuk setiap aspek membaca.',
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

  void _createDiagnostic(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final titleController = TextEditingController();
    int classId = store.classes.first.id;
    final selected = <int>{};
    final approved = store.questions
        .where((item) => item.status == 'disetujui')
        .toList();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Buat tes diagnostik'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Nama tes'),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: classId,
                    decoration: const InputDecoration(labelText: 'Kelas'),
                    items: [
                      for (final item in store.classes)
                        DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => classId = value ?? classId),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pilih soal yang disetujui',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final question in approved)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: selected.contains(question.id),
                      title: Text(question.prompt),
                      subtitle: Text(aspectLabel(question.aspect)),
                      onChanged: (checked) => setDialogState(() {
                        if (checked == true) {
                          selected.add(question.id);
                        } else {
                          selected.remove(question.id);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty || selected.isEmpty) {
                  return;
                }
                store.addDiagnostic(
                  title: titleController.text.trim(),
                  classId: classId,
                  questionIds: selected.toList(),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Simpan draf'),
            ),
          ],
        ),
      ),
    ).whenComplete(titleController.dispose);
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
    final allResults = store.diagnosticStudents;
    final results = allResults.where((student) {
      final matchesName = student.name.toLowerCase().contains(_query);
      final average =
          student.scores!.values.reduce((a, b) => a + b) /
          student.scores!.length;
      final status = average < 60
          ? 'Belum dikuasai'
          : average < 80
          ? 'Sedang berlatih'
          : 'Dikuasai';
      return matchesName && (_status == 'Semua status' || status == _status);
    }).toList();
    final diagnostic = widget.diagnosticId == null
        ? null
        : store.diagnostics
              .where((item) => item.id == widget.diagnosticId)
              .isEmpty
        ? null
        : store.diagnostics.firstWhere(
            (item) => item.id == widget.diagnosticId,
          );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TeacherPageHeading(
          title: 'Hasil Diagnostik',
          subtitle: diagnostic?.title ?? 'Lihat hasil tes membaca siswa.',
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
        if (results.isEmpty)
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
                for (var index = 0; index < results.length; index++) ...[
                  InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/guru/siswa/detail',
                      arguments: results[index].id,
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
                                  results[index].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTokens.text,
                                  ),
                                ),
                                Text(
                                  store.className(results[index].classId),
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
                                '${results[index].scores![aspect]}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: results[index].scores![aspect]! < 60
                                      ? AppTokens.coral
                                      : AppTokens.text,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (index < results.length - 1)
                    const Divider(height: 1, color: AppTokens.outline),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

const _resultHeaderStyle = TextStyle(
  fontSize: 8,
  fontWeight: FontWeight.w800,
  color: AppTokens.mutedText,
);
