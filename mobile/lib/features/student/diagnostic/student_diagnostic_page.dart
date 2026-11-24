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
        icon: Icons.home_rounded,
        onPressed: () => Navigator.pushReplacementNamed(context, '/siswa'),
      ),
    ],
  );

  Widget _question(BuildContext context) {
    final item = _items[_index];
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        StudentPageHeading(
          title: _diagnostic!.title,
          subtitle:
              'Kerjakan pelan-pelan. Soal ${_index + 1} dari ${_items.length}.',
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (_index + 1) / _items.length,
            minHeight: 14,
            color: AppTokens.primary,
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        StudentPanel(
          color: StudentColors.sunshine,
          child: Column(
            children: [
              if (item.picture.isNotEmpty) ...[
                Semantics(
                  label: 'Gambar petunjuk',
                  child: Text(
                    item.picture,
                    style: const TextStyle(fontSize: 54, height: 1.1),
                  ),
                ),
                const SizedBox(height: AppTokens.space12),
              ],
              Text(
                'Aspek: ${aspectLabel(item.aspect)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTokens.space8),
              Text(
                item.prompt,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTokens.space8),
              QuestionAudioButton(
                key: ValueKey('diagnostic-audio-$_index'),
                text: item.prompt,
                kind: questionSpeechKindForQuestion(
                  aspect: item.aspect,
                  questionType: item.type,
                ),
              ),
              const SizedBox(height: AppTokens.space8),
              const Text('Baca pilihan jawaban, lalu ketuk satu jawaban.'),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        for (var i = 0; i < item.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space8),
            child: OutlinedButton(
              key: ValueKey('diagnostic-answer-$i'),
              onPressed: () => setState(() => _answers[_index] = i),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                backgroundColor: _answers[_index] == i
                    ? _answers[_index] == item.correctAnswerIndex
                          ? StudentColors.mint
                          : StudentColors.peach
                    : Colors.white,
                side: BorderSide(
                  color: _answers[_index] == i
                      ? _answers[_index] == item.correctAnswerIndex
                            ? AppTokens.primary
                            : AppTokens.coralDark
                      : AppTokens.outline,
                  width: 2,
                ),
              ),
              child: Text(
                item.choices[i],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        if (_answers[_index] != null) ...[
          const SizedBox(height: AppTokens.space8),
          StudentPanel(
            color: _answers[_index] == item.correctAnswerIndex
                ? StudentColors.mint
                : StudentColors.peach,
            child: Text(
              _answers[_index] == item.correctAnswerIndex
                  ? item.correctFeedback
                  : item.hint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
        const SizedBox(height: AppTokens.space8),
        if (_index > 0)
          OutlinedButton.icon(
            key: const ValueKey('diagnostic-back'),
            onPressed: _previous,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Soal sebelumnya'),
          ),
        StudentAction(
          key: const ValueKey('diagnostic-next'),
          label: _index == _items.length - 1 ? 'Selesai' : 'Lanjut',
          icon: _index == _items.length - 1
              ? Icons.check_rounded
              : Icons.arrow_forward_rounded,
          onPressed: _answers[_index] == null
              ? () => _showSelectHint(context)
              : _next,
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const StudentPageHeading(
          title: 'Tes selesai! 🎉',
          subtitle: 'Terima kasih sudah mencoba. Ini hasil diagnostikmu.',
        ),
        StudentPanel(
          color: StudentColors.mint,
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 56,
                color: Color(0xFFCC9B27),
              ),
              Text(
                'Kamu hebat sudah mencoba!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTokens.space12),
              for (final aspect in const [
                'huruf',
                'suku_kata',
                'kata',
                'kalimat',
              ]) ...[
                StudentProgressBar(
                  label: aspectLabel(aspect),
                  value: scores[aspect] ?? 0,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.space8),
                    child: Text(
                      _abilityLabel(scores[aspect] ?? 0),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        StudentAction(
          key: const ValueKey('diagnostic-finish'),
          label: 'Lihat latihan untukku',
          icon: Icons.auto_stories_rounded,
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/siswa/latihan'),
        ),
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/siswa'),
          child: const Text('Kembali ke beranda'),
        ),
      ],
    );
  }

  void _showSelectHint(BuildContext context) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Pilih satu jawaban dulu ya.')));

  String _abilityLabel(int score) {
    if (score < 60) return 'Belum dikuasai';
    if (score < 80) return 'Sedang berlatih';
    return 'Dikuasai';
  }
}
