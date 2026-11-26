import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../teacher/teacher_demo_store.dart';
import '../student_demo_store.dart';
import '../question_audio_button.dart';
import '../student_widgets.dart';

class StudentDiagnosticPage extends StatefulWidget {
  const StudentDiagnosticPage({super.key});

  @override
  State<StudentDiagnosticPage> createState() => _StudentDiagnosticPageState();
}

class _StudentDiagnosticPageState extends State<StudentDiagnosticPage> {
  late final DemoDiagnostic? _diagnostic;
  late final List<DemoQuestion> _items;
  late final List<int?> _answers;
  late final DateTime _startedAt;
  late final bool _completedAlready;
  final _scrollController = ScrollController();
  int _index = 0;
  bool _complete = false;
  DiagnosticAttempt? _attempt;

  @override
  void initState() {
    super.initState();
    final student = StudentDemoStore.instance.student;
    final teacherStore = TeacherDemoStore.instance;
    _diagnostic = teacherStore.activeDiagnosticForClass(student.classId);
    _completedAlready =
        _diagnostic != null &&
        StudentDemoStore.instance.attemptForDiagnostic(
              student.id,
              _diagnostic.id,
            ) !=
            null;
    _items = _diagnostic == null || _completedAlready
        ? const []
        : teacherStore.diagnosticQuestionsFor(_diagnostic);
    _answers = List<int?>.filled(_items.length, null);
    _startedAt = DateTime.now();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_complete) return _result(context);
    if (_diagnostic == null || _items.isEmpty) return _empty(context);
    return _question(context);
  }

  Widget _empty(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppTokens.space16),
    children: [
      StudentPageHeading(
        title: _completedAlready ? 'Tes selesai' : 'Tes Diagnostik',
        subtitle: 'Belajar membaca langkah demi langkah.',
      ),
      StudentEmptyState(
        message: _completedAlready
            ? 'Kamu sudah menyelesaikan tes ini. Hasilnya tersimpan di halaman evaluasi.'
            : 'Belum ada tes diagnostik yang tersedia untuk kelasmu. Tunggu Bapak/Ibu Guru ya!',
      ),
      const SizedBox(height: AppTokens.space16),
      StudentAction(
        label: 'Kembali ke beranda',
        icon: Icons.home_outlined,
        onPressed: () => Navigator.pushReplacementNamed(context, '/siswa'),
      ),
    ],
  );

  Widget _question(BuildContext context) {
    final item = _items[_index];
    final answered = _answers[_index] != null;
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        AppTokens.space12,
        AppTokens.space16,
        AppTokens.space24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _diagnostic!.title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppTokens.mutedText,
            ),
          ),
          const SizedBox(height: AppTokens.space8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Soal ${_index + 1} dari ${_items.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTokens.text,
                  ),
                ),
              ),
              Text(
                aspectLabel(item.aspect),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTokens.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusRound),
            child: LinearProgressIndicator(
              value: (_index + 1) / _items.length,
              minHeight: 4,
              color: AppTokens.secondary,
              backgroundColor: const Color(0xFFE4EAEA),
            ),
          ),
          const SizedBox(height: AppTokens.space16),
          QuestionAudioButton(
            key: ValueKey('diagnostic-audio-$_index'),
            text: item.prompt,
            kind: questionSpeechKindForQuestion(
              aspect: item.aspect,
              questionType: item.type,
            ),
          ),
          const SizedBox(height: AppTokens.space16),
          StudentPanel(
            padding: const EdgeInsets.all(AppTokens.space20),
            child: Column(
              children: [
                Text(
                  item.prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTokens.mutedText,
                  ),
                ),
                if (item.picture.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.space8),
                  Semantics(
                    label: 'Gambar petunjuk',
                    child: Text(
                      item.picture,
                      style: const TextStyle(fontSize: 44, height: 1.2),
                    ),
                  ),
                ],
                const SizedBox(height: AppTokens.space16),
                Row(
                  children: [
                    for (var i = 0; i < item.choices.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppTokens.space10),
                      Expanded(
                        child: StudentChoiceTile(
                          key: ValueKey('diagnostic-answer-$i'),
                          text: item.choices[i],
                          selected: _answers[_index] == i,
                          correct: item.correctAnswerIndex == i,
                          onTap: () => setState(() => _answers[_index] = i),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (answered) ...[
            const SizedBox(height: AppTokens.space12),
            Text(
              _answers[_index] == item.correctAnswerIndex
                  ? item.correctFeedback
                  : item.hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTokens.mutedText,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: AppTokens.space16),
          FilledButton(
            key: const ValueKey('diagnostic-next'),
            onPressed: answered ? _next : () => _showSelectHint(context),
            style: FilledButton.styleFrom(
              backgroundColor: answered
                  ? AppTokens.primary
                  : const Color(0xFF9AC7BC),
              minimumSize: const Size.fromHeight(AppTokens.studentButtonHeight),
            ),
            child: Text(
              _index == _items.length - 1 ? 'Selesai' : 'Soal berikutnya',
            ),
          ),
          if (_index > 0)
            Center(
              child: TextButton(
                key: const ValueKey('diagnostic-back'),
                onPressed: _previous,
                child: const Text(
                  'Sebelumnya',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTokens.secondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _next() {
    if (_index < _items.length - 1) {
      setState(() => _index++);
      _scrollToQuestionStart();
      return;
    }

    final submitted = <DiagnosticAnswerRecord>[];
    for (var index = 0; index < _items.length; index++) {
      final question = _items[index];
      final selectedIndex = _answers[index];
      if (selectedIndex == null) {
        _showSelectHint(context);
        return;
      }
      submitted.add(
        DiagnosticAnswerRecord(
          questionId: question.id,
          prompt: question.prompt,
          picture: question.picture,
          aspect: question.aspect,
          level: question.level,
          choices: question.choices,
          correctAnswerIndex: question.correctAnswerIndex!,
          answer: question.choices[selectedIndex],
          correctAnswer: question.correctAnswer!,
          isCorrect: selectedIndex == question.correctAnswerIndex,
          hint: question.hint,
          correctFeedback: question.correctFeedback,
        ),
      );
    }

    final diagnostic = _diagnostic;
    if (diagnostic == null) return;
    final student = StudentDemoStore.instance.student;
    _attempt = StudentDemoStore.instance.completeDiagnostic(
      diagnosticId: diagnostic.id,
      classId: student.classId,
      title: diagnostic.title,
      questionSnapshots: _items,
      answers: submitted,
      startedAt: _startedAt,
      finishedAt: DateTime.now(),
    );
    if (_attempt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hasil tes belum dapat disimpan. Periksa kembali jawabanmu.',
          ),
        ),
      );
      return;
    }
    setState(() => _complete = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  void _previous() {
    setState(() => _index--);
    _scrollToQuestionStart();
  }

  void _scrollToQuestionStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  Widget _result(BuildContext context) {
    final scores = _attempt!.aspectScores;
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        AppTokens.space24,
        AppTokens.space16,
        AppTokens.space24,
      ),
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppTokens.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 40,
              color: AppTokens.primary,
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        const Center(
          child: _SummaryBadge(label: 'Menunggu penilaian'),
        ),
        const SizedBox(height: AppTokens.space12),
        const Text(
          'Jawabanmu sudah terkirim!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            height: 1.25,
            fontWeight: FontWeight.w600,
            color: AppTokens.text,
          ),
        ),
        const SizedBox(height: AppTokens.space8),
        const Text(
          'Bu Andini dapat melihat rincian hasilmu.\nKerjakan latihan berikutnya, ya.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppTokens.mutedText,
          ),
        ),
        const SizedBox(height: AppTokens.space24),
        StudentPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SummaryRow(
                icon: Icons.check_box_outlined,
                tint: AppTokens.primary,
                title: '${_attempt!.answers.length} soal objektif',
                subtitle: 'Sudah dinilai otomatis',
                badge: 'Selesai',
                badgeColor: AppTokens.mint,
                badgeTextColor: AppTokens.primary,
              ),
              const Divider(height: 1, color: AppTokens.outline),
              const _SummaryRow(
                icon: Icons.mic_none_rounded,
                tint: AppTokens.warning,
                title: 'Nilai per aspek',
                subtitle: 'Tersimpan di kemajuanku',
                badge: 'Lihat',
                badgeColor: AppTokens.sunshine,
                badgeTextColor: AppTokens.warning,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        Container(
          padding: const EdgeInsets.all(AppTokens.space14),
          decoration: BoxDecoration(
            color: AppTokens.sunshine,
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            border: Border.all(color: const Color(0xFFEBD78D)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: AppTokens.warning,
              ),
              SizedBox(width: AppTokens.space10),
              Expanded(
                child: Text(
                  'Tes ini sudah selesai dan tidak dapat dikerjakan kembali.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppTokens.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space20),
        StudentPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StudentSectionLabel('Hasil per aspek'),
              const SizedBox(height: AppTokens.space8),
              for (final aspect in const [
                'huruf',
                'suku_kata',
                'kata',
                'kalimat',
              ])
                StudentProgressBar(
                  label: aspectLabel(aspect),
                  value: scores[aspect] ?? 0,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space20),
        StudentAction(
          key: const ValueKey('diagnostic-finish'),
          label: 'Kembali ke beranda',
          icon: Icons.home_outlined,
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/siswa'),
        ),
        Center(
          child: TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/siswa/latihan'),
            child: const Text(
              'Lihat latihan untukku',
              style: TextStyle(
                fontSize: 12,
                color: AppTokens.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSelectHint(BuildContext context) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Pilih satu jawaban dulu ya.')));
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: AppTokens.sunshine,
      borderRadius: BorderRadius.circular(AppTokens.radiusRound),
      border: Border.all(color: const Color(0xFFEBD78D)),
    ),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 9,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w900,
        color: AppTokens.warning,
      ),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final Color badgeTextColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppTokens.space14),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
          child: Icon(icon, size: 19, color: tint),
        ),
        const SizedBox(width: AppTokens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.text,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTokens.mutedText,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(AppTokens.radiusRound),
          ),
          child: Text(
            badge.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w900,
              color: badgeTextColor,
            ),
          ),
        ),
      ],
    ),
  );
}
