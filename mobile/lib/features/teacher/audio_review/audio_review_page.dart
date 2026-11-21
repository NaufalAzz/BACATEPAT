import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_tokens.dart';
import '../teacher_demo_store.dart';
import '../teacher_widgets.dart';

class AudioReviewPage extends StatefulWidget {
  const AudioReviewPage({super.key});

  @override
  State<AudioReviewPage> createState() => _AudioReviewPageState();
}

class _AudioReviewPageState extends State<AudioReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _accuracy = TextEditingController();
  final _fluency = TextEditingController();
  final _comment = TextEditingController();
  final _advice = TextEditingController();
  int? _selectedId;
  bool _playing = false;
  int _elapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final store = TeacherDemoStore.instance;
    final pending = store.recordings.where((item) {
      final student = store.studentById(item.studentId);
      return item.parentConsent &&
          student?.parentConsent == true &&
          item.status == 'terkirim';
    });
    final eligible = store.recordings.where((item) {
      return item.parentConsent &&
          store.studentById(item.studentId)?.parentConsent == true;
    });
    final first = pending.isEmpty
        ? (eligible.isEmpty ? null : eligible.first)
        : pending.first;
    _selectedId = first?.id;
    if (first != null) _loadEvaluation(first);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accuracy.dispose();
    _fluency.dispose();
    _comment.dispose();
    _advice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final eligible = store.recordings
        .where(
          (item) =>
              item.parentConsent &&
              store.studentById(item.studentId)?.parentConsent == true,
        )
        .toList();
    final selectedItems = eligible.where((item) => item.id == _selectedId);
    final selected = selectedItems.isEmpty ? null : selectedItems.first;
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        const TeacherPageHeading(
          title: 'Evaluasi Rekaman',
          subtitle:
              'Dengarkan bacaan, lalu tetapkan penilaian akhir sebagai Guru.',
        ),
        if (eligible.isEmpty)
          const TeacherPanel(
            child: EmptyState(
              message: 'Tidak ada rekaman yang dapat diakses. Rekaman tanpa persetujuan wali tidak tersedia di antrean.',
              icon: Icons.lock_outline_rounded,
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final queue = _recordingQueue(context, eligible, store);
              final detail = selected == null
                  ? const TeacherPanel(
                      child: EmptyState(message: 'Pilih rekaman dari antrean.'),
                    )
                  : _recordingDetail(context, selected, store);
              if (constraints.maxWidth < 760) {
                return Column(
                  children: [
                    queue,
                    const SizedBox(height: AppTokens.space16),
                    detail,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 320, child: queue),
                  const SizedBox(width: AppTokens.space16),
                  Expanded(child: detail),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _recordingQueue(
    BuildContext context,
    List<DemoRecording> recordings,
    TeacherDemoStore store,
  ) => TeacherPanel(
    title:
        'Antrean (${recordings.where((item) => item.status == 'terkirim').length} menunggu)',
    child: Column(
      children: [
        for (final recording in recordings)
          Card(
            color: recording.id == _selectedId
                ? AppTokens.primary.withValues(alpha: 0.08)
                : null,
            child: ListTile(
              key: ValueKey('recording-${recording.id}'),
              selected: recording.id == _selectedId,
              leading: const CircleAvatar(
                child: Icon(Icons.graphic_eq_rounded),
              ),
              title: Text(
                store.studentById(recording.studentId)?.name ?? 'Siswa',
              ),
              subtitle: Text(
                '${aspectLabel(recording.aspect)} • ${recording.durationSeconds} dtk',
              ),
              trailing: Icon(
                recording.status == 'dievaluasi'
                    ? Icons.check_circle_outline
                    : Icons.pending_outlined,
              ),
              onTap: () {
                _timer?.cancel();
                setState(() {
                  _selectedId = recording.id;
                  _playing = false;
                  _elapsed = 0;
                  _loadEvaluation(recording);
                });
              },
            ),
          ),
      ],
    ),
  );

  Widget _recordingDetail(
    BuildContext context,
    DemoRecording recording,
    TeacherDemoStore store,
  ) {
    final student = store.studentById(recording.studentId)!;
    final finalScore =
        recording.accuracyScore == null || recording.fluencyScore == null
        ? null
        : ((recording.accuracyScore! + recording.fluencyScore!) / 2).round();
    return Column(
      children: [
        TeacherPanel(
          title: student.name,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${store.className(student.classId)} • ${aspectLabel(recording.aspect)}',
              ),
              const SizedBox(height: AppTokens.space16),
              Text(
                'Teks target',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTokens.space8),
              Text(
                recording.targetText,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTokens.space16),
              Row(
                children: [
                  IconButton.filledTonal(
                    key: const ValueKey('toggle-audio-preview'),
                    tooltip: _playing ? 'Jeda simulasi' : 'Putar simulasi',
                    onPressed: recording.parentConsent ? _togglePlayback : null,
                    icon: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: recording.durationSeconds == 0
                          ? 0
                          : _elapsed / recording.durationSeconds,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space12),
                  Text('${_elapsed}s / ${recording.durationSeconds}s'),
                ],
              ),
              const SizedBox(height: AppTokens.space8),
              Text(
                'Kontrol audio ini hanya simulasi; tidak ada file audio yang diputar.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTokens.space12),
              Wrap(
                spacing: AppTokens.space8,
                children: [
                  StatusBadge(
                    label: 'Persetujuan wali tercatat',
                    good: recording.parentConsent,
                  ),
                  StatusBadge(
                    label: student.aiConsent
                        ? 'Persetujuan AI: ya'
                        : 'Persetujuan AI: tidak',
                    good: student.aiConsent,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        _aiIndication(context, recording, student),
        const SizedBox(height: AppTokens.space16),
        TeacherPanel(
          title: recording.status == 'dievaluasi'
              ? 'Evaluasi Guru tersimpan'
              : 'Penilaian Guru',
          child: recording.status == 'dievaluasi'
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ketepatan ${recording.accuracyScore}% • Kelancaran ${recording.fluencyScore}% • Skor bacaan $finalScore%',
                    ),
                    const SizedBox(height: AppTokens.space8),
                    Text(recording.comment),
                    Text('Saran: ${recording.advice}'),
                    const SizedBox(height: AppTokens.space12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => recording.status = 'terkirim'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Ubah evaluasi'),
                    ),
                  ],
                )
              : _evaluationForm(context, recording),
        ),
      ],
    );
  }

  Widget _aiIndication(
    BuildContext context,
    DemoRecording recording,
    DemoStudent student,
  ) {
    if (!recording.parentConsent || !student.parentConsent) {
      return const TeacherPanel(
        child: Text(
          'Rekaman tidak tersedia karena belum ada persetujuan wali.',
        ),
      );
    }
    if (!recording.aiConsent || !student.aiConsent) {
      return const TeacherPanel(
        child: Text(
          'Analisis AI tidak aktif karena persetujuan AI belum diberikan. Guru tetap dapat menilai secara manual.',
        ),
      );
    }
    if (!recording.aiAllowed) {
      return const TeacherPanel(
        child: Text(
          'Analisis AI hanya digunakan untuk konteks kata dan kalimat. Aspek ini dinilai langsung oleh Guru.',
        ),
      );
    }
    return TeacherPanel(
      title: 'Indikasi analisis otomatis',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(label: 'Indikasi • bukan nilai resmi', good: false),
          const SizedBox(height: AppTokens.space12),
          Text('Kemiripan simulasi: ${recording.simulatedAiSimilarity}%'),
          const SizedBox(height: AppTokens.space8),
          Text('Contoh transkrip simulasi: “${recording.targetText}”'),
          const SizedBox(height: AppTokens.space8),
          const Text(
            'Periksa dengan mendengarkan. Keputusan akhir dan nilai tetap ditetapkan Guru.',
          ),
          const SizedBox(height: AppTokens.space12),
          TextButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Analisis ulang simulasi selesai.')),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Analisis ulang simulasi'),
          ),
        ],
      ),
    );
  }

  Widget _evaluationForm(BuildContext context, DemoRecording recording) => Form(
    key: _formKey,
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: _scoreField(_accuracy, 'Nilai ketepatan')),
            const SizedBox(width: AppTokens.space12),
            Expanded(child: _scoreField(_fluency, 'Nilai kelancaran')),
          ],
        ),
        const SizedBox(height: AppTokens.space16),
        TextFormField(
          key: const ValueKey('evaluation-comment'),
          controller: _comment,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Komentar untuk siswa'),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Komentar perlu diisi.'
              : null,
        ),
        const SizedBox(height: AppTokens.space16),
        TextFormField(
          key: const ValueKey('evaluation-advice'),
          controller: _advice,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Saran latihan'),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Saran latihan perlu diisi.'
              : null,
        ),
        const SizedBox(height: AppTokens.space16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('save-evaluation'),
            onPressed: recording.parentConsent
                ? () => _saveEvaluation(recording)
                : null,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Simpan penilaian Guru'),
          ),
        ),
      ],
    ),
  );

  Widget _scoreField(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: InputDecoration(labelText: label, suffixText: '/ 100'),
        validator: (value) {
          final score = int.tryParse(value ?? '');
          return score == null || score < 0 || score > 100
              ? 'Isi 0–100.'
              : null;
        },
      );

  void _loadEvaluation(DemoRecording recording) {
    _accuracy.text = recording.accuracyScore?.toString() ?? '';
    _fluency.text = recording.fluencyScore?.toString() ?? '';
    _comment.text = recording.comment;
    _advice.text = recording.advice;
  }

  void _saveEvaluation(DemoRecording recording) {
    if (!_formKey.currentState!.validate()) return;
    TeacherDemoStore.instance.saveEvaluation(
      recordingId: recording.id,
      accuracy: int.parse(_accuracy.text),
      fluency: int.parse(_fluency.text),
      comment: _comment.text.trim(),
      advice: _advice.text.trim(),
    );
  }

  void _togglePlayback() {
    final matches = TeacherDemoStore.instance.recordings.where(
      (item) => item.id == _selectedId,
    );
    final recording = matches.isEmpty ? null : matches.first;
    if (recording == null) return;
    _timer?.cancel();
    if (_playing) {
      setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        _elapsed++;
        if (_elapsed >= recording.durationSeconds) {
          _elapsed = 0;
          _playing = false;
          timer.cancel();
        }
      });
    });
  }
}
