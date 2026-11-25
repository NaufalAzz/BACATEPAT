import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../teacher/teacher_demo_store.dart';
import '../student_demo_store.dart';
import '../question_audio_button.dart';
import '../student_widgets.dart';

class StudentPracticeListPage extends StatefulWidget {
  const StudentPracticeListPage({
    super.key,
    this.catalog,
    this.recommendedId,
    this.reason,
    this.hasDiagnostic,
    this.completeBaseline,
    this.onOpen,
    this.scores,
  });
  final List<DemoMaterial>? catalog;
  final int? recommendedId;
  final String? reason;
  final bool? hasDiagnostic, completeBaseline;
  final ValueChanged<DemoMaterial>? onOpen;
  final Map<String, int>? scores;

  @override
  State<StudentPracticeListPage> createState() =>
      _StudentPracticeListPageState();
}

class _StudentPracticeListPageState extends State<StudentPracticeListPage> {
  String _aspect = 'semua';

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final studentStore = StudentDemoStore.instance;
    return AnimatedBuilder(
      animation: studentStore,
      builder: (context, _) {
        final materials = (widget.catalog ?? store.materials)
            .where(
              (item) =>
                  item.status == 'aktif' &&
                  (_aspect == 'semua' || item.aspect == _aspect),
            )
            .toList();
        final recommendation = widget.catalog == null
            ? studentStore.activeRecommendation
            : null;
        final recommendationId =
            widget.recommendedId ?? recommendation?.materialId;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const StudentPageHeading(
              title: 'Latihan Membaca',
              subtitle: 'Pilih bacaan yang ingin kamu latih hari ini.',
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in const [
                    ('semua', 'Semua'),
                    ('huruf', 'Huruf'),
                    ('suku_kata', 'Suku kata'),
                    ('kata', 'Kata'),
                    ('kalimat', 'Kalimat'),
                  ]) ...[
                    if (option.$1 != 'semua') const SizedBox(width: 6),
                    ChoiceChip(
                      key: ValueKey('practice-filter-${option.$1}'),
                      label: Text(option.$2),
                      selected: _aspect == option.$1,
                      onSelected: (_) => setState(() => _aspect = option.$1),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),
            if (!(widget.completeBaseline ??
                studentStore.hasCompleteDiagnosticBaseline))
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space12),
                child: Text(
                  (widget.hasDiagnostic ?? studentStore.hasAnyDiagnostic)
                      ? 'Hasil diagnostik belum mencakup semua aspek. Minta bantuan Gurumu untuk melengkapi tes.'
                      : 'Kerjakan tes diagnostik terlebih dahulu agar latihan yang disarankan sesuai kemampuanmu.',
                  style: const TextStyle(
                    color: AppTokens.mutedText,
                    fontSize: 12,
                  ),
                ),
              ),
            if (materials.isEmpty)
              const StudentEmptyState(
                message: 'Belum ada latihan untuk pilihan ini. Coba pilihan lain ya!',
              )
            else
              for (final material in materials)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      key: ValueKey('practice-material-${material.id}'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: widget.onOpen != null
                          ? () => widget.onOpen!(material)
                          : () => Navigator.pushNamed(
                              context,
                              '/siswa/latihan/materi',
                              arguments: material.id,
                            ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _aspectColor(material.aspect),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                _aspectGlyph(material.aspect),
                                style: const TextStyle(
                                  fontSize: 19,
                                  color: AppTokens.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          material.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTokens.text,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      if (material.id == recommendationId)
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 15,
                                          color: Color(0xFFD8A42A),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${aspectLabel(material.aspect)} · Tingkat ${material.level}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTokens.mutedText,
                                    ),
                                  ),
                                  if (material.id == recommendationId &&
                                      (recommendation != null ||
                                          widget.reason != null)) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      widget.reason ??
                                          (recommendation!.source == 'guru'
                                              ? 'Pilihan Gurumu: ${recommendation.reason}'
                                              : 'Disarankan: ${recommendation.reason}'),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTokens.mutedText,
                                      ),
                                    ),
                                  ],
                                  finalScore(material.aspect, studentStore),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 21,
                              color: AppTokens.mutedText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Widget finalScore(String aspect, StudentDemoStore store) {
    final score = (widget.scores ?? store.practiceScores)[aspect];
    if (score == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: LinearProgressIndicator(
          value: score / 100,
          minHeight: 5,
          backgroundColor: const Color(0xFFE9EFED),
          color: AppTokens.primary,
        ),
      ),
    );
  }
}

class StudentMaterialDetailPage extends StatelessWidget {
  const StudentMaterialDetailPage({
    this.materialId,
    this.item,
    this.onStart,
    super.key,
  });
  final DemoMaterial? item;
  final VoidCallback? onStart;

  final int? materialId;

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final material =
        item ?? (materialId == null ? null : store.materialById(materialId!));
    if (material == null || material.status != 'aktif') {
      return const Center(
        child: StudentEmptyState(
          message: 'Materi ini belum tersedia. Coba pilih latihan lain ya!',
        ),
      );
    }
    final hasPracticeQuestions =
        onStart != null ||
        store.practiceQuestionsForMaterial(material.id).isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.coralSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${aspectLabel(material.aspect).toUpperCase()} · TINGKAT ${material.level}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTokens.coralDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                material.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  color: AppTokens.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lihat, dengar, lalu baca bersama.',
                style: TextStyle(fontSize: 13, color: AppTokens.mutedText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StudentPanel(
          color: Colors.white,
          child: Column(
            children: [
              Image.asset(
                'assets/illustrations/reading-book.png',
                width: 112,
                height: 98,
                semanticLabel: 'Ilustrasi buku terbuka',
              ),
              const SizedBox(height: AppTokens.space16),
              Text(
                material.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTokens.space8),
              Text(
                '${aspectLabel(material.aspect)} • tingkat ${material.level}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        StudentPanel(
          color: StudentColors.sunshine,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ayo baca bersama!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTokens.space12),
              Center(
                child: Text(
                  material.content.replaceAll(' • ', '    '),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall
                      ?.copyWith(height: 1.5),
                ),
              ),
              const SizedBox(height: AppTokens.space12),
              const Text(
                'Tunjuk setiap huruf atau kata sambil membacanya. Pelan-pelan saja.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        if (hasPracticeQuestions)
          StudentAction(
            key: const ValueKey('material-start-exercise'),
            label: 'Mulai latihan',
            icon: Icons.play_arrow_rounded,
            onPressed:
                onStart ??
                () => Navigator.pushNamed(
                  context,
                  '/siswa/latihan/kerjakan',
                  arguments: material.id,
                ),
          )
        else
          const StudentEmptyState(
            message:
                'Latihan untuk materi ini belum tersedia. Coba materi lain ya!',
          ),
      ],
    );
  }
}

class StudentExercisePage extends StatefulWidget {
  const StudentExercisePage({this.materialId, super.key});
  final int? materialId;

  @override
  State<StudentExercisePage> createState() => _StudentExercisePageState();
}

class _StudentExercisePageState extends State<StudentExercisePage> {
  late final DemoMaterial? _material;
  late final List<DemoQuestion> _questions;
  late DateTime _startedAt;
  late String _completionToken;
  int? _recommendationId;
  int _questionIndex = 0;
  int _correct = 0;
  int? _selected;
  bool _finished = false;
  PracticeAttempt? _attempt;
  final List<PracticeAnswerRecord> _answers = [];

  @override
  void initState() {
    super.initState();
    final store = TeacherDemoStore.instance;
    _material = widget.materialId == null
        ? null
        : store.materialById(widget.materialId!);
    final eligible = _material == null || _material.status != 'aktif'
        ? <DemoQuestion>[]
        : store.practiceQuestionsForMaterial(_material.id).toList();
    eligible.shuffle(Random());
    _questions = eligible
        .map((item) => item.copyWithIdAndStatus(item.id, item.status))
        .toList(growable: false);
    _startedAt = DateTime.now();
    _completionToken = '${_startedAt.microsecondsSinceEpoch}-$hashCode';
    final recommendation = StudentDemoStore.instance.activeRecommendation;
    _recommendationId = recommendation?.materialId == _material?.id
        ? recommendation?.id
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final material = _material;
    if (material == null || material.status != 'aktif') {
      return const Center(
        child: StudentEmptyState(message: 'Materi ini belum tersedia.'),
      );
    }
    if (_questions.isEmpty) {
      return const Center(
        child: StudentEmptyState(
          message:
              'Latihan untuk materi ini belum tersedia. Coba materi lain ya!',
        ),
      );
    }
    if (_finished) return _result(context);

    final question = _questions[_questionIndex];
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Soal ${_questionIndex + 1} dari ${_questions.length}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTokens.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_correct + (_selected == question.correctAnswerIndex ? 1 : 0)} bintang',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTokens.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_questionIndex + 1) / _questions.length,
                  minHeight: 6,
                  color: AppTokens.coral,
                  backgroundColor: const Color(0xFFE7EDEB),
                ),
              ),
              const SizedBox(height: 14),
              StudentPanel(
                color: Colors.white,
                child: Column(
                  children: [
                    if (question.picture.isNotEmpty) ...[
                      Semantics(
                        label: 'Gambar petunjuk',
                        child: Text(
                          question.picture,
                          style: const TextStyle(fontSize: 54, height: 1.1),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      question.prompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    QuestionAudioButton(
                      key: ValueKey('exercise-audio-$_questionIndex'),
                      text: question.prompt,
                      kind: questionSpeechKindForQuestion(
                        aspect: question.aspect,
                        questionType: question.type,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < question.choices.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        key: ValueKey('exercise-answer-$i'),
                        onPressed: _selected == null
                            ? () => setState(() => _selected = i)
                            : null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          backgroundColor: _selected == i
                              ? _selected == question.correctAnswerIndex
                                    ? StudentColors.mint
                                    : StudentColors.peach
                              : Colors.white,
                          side: BorderSide(
                            color: _selected == i
                                ? _selected == question.correctAnswerIndex
                                      ? AppTokens.primary
                                      : AppTokens.coralDark
                                : AppTokens.outline,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          question.choices[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.text,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (_selected != null)
                StudentPanel(
                  color: _selected == question.correctAnswerIndex
                      ? StudentColors.mint
                      : StudentColors.peach,
                  child: Text(
                    _selected == question.correctAnswerIndex
                        ? question.correctFeedback
                        : 'Tidak apa-apa. ${question.hint}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
            ],
          ),
        ),
        if (_selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: StudentAction(
              key: const ValueKey('exercise-next'),
              label: _questionIndex == _questions.length - 1
                  ? 'Lihat hasil'
                  : 'Soal berikutnya',
              icon: Icons.arrow_forward_rounded,
              onPressed: _submitCurrentAnswer,
            ),
          ),
      ],
    );
  }

  void _submitCurrentAnswer() {
    final material = _material;
    if (material == null) return;
    final question = _questions[_questionIndex];
    final selected = _selected!;
    final answer = PracticeAnswerRecord(
      questionId: question.id,
      aspect: question.aspect,
      answer: question.choices[selected],
      correctAnswer: question.correctAnswer!,
      isCorrect: selected == question.correctAnswerIndex,
    );
    _answers.add(answer);
    if (answer.isCorrect) _correct++;

    if (_questionIndex == _questions.length - 1) {
      _attempt = StudentDemoStore.instance.completePractice(
        materialId: material.id,
        title: material.title,
        aspect: material.aspect,
        availableQuestionCount: _questions.length,
        questionSnapshots: List.unmodifiable(_questions),
        answers: List.unmodifiable(_answers),
        startedAt: _startedAt,
        finishedAt: DateTime.now(),
        completionToken: _completionToken,
        recommendationId: _recommendationId,
      );
      setState(() => _finished = _attempt != null);
      return;
    }

    setState(() {
      _questionIndex++;
      _selected = null;
    });
  }

  Widget _result(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    children: [
      const StudentPageHeading(
        title: 'Latihan selesai!',
        subtitle: 'Kamu sudah berusaha dengan hebat.',
      ),
      StudentPanel(
        color: StudentColors.sunshine,
        child: Column(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              size: 64,
              color: Color(0xFFCC9B27),
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              '${_attempt?.score ?? 0}%',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            Text(
              'Skor latihanmu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              'Terus berlatih ${aspectLabel(_material!.aspect).toLowerCase()} ya!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppTokens.space16),
      StudentAction(
        key: const ValueKey('exercise-record-reading'),
        label: 'Baca dengan suara',
        icon: Icons.mic_rounded,
        color: const Color(0xFF4F71A8),
        onPressed: () => Navigator.pushNamed(
          context,
          '/siswa/rekaman',
          arguments: _material.title,
        ),
      ),
      const SizedBox(height: AppTokens.space8),
      OutlinedButton.icon(
        key: const ValueKey('exercise-repeat'),
        onPressed: () => setState(() {
          _questionIndex = 0;
          _correct = 0;
          _selected = null;
          _answers.clear();
          _attempt = null;
          _startedAt = DateTime.now();
          _completionToken = '${_startedAt.microsecondsSinceEpoch}-$hashCode';
          final recommendation = StudentDemoStore.instance.activeRecommendation;
          _recommendationId =
              recommendation != null &&
                  recommendation.materialId == _material.id
              ? recommendation.id
              : null;
          _finished = false;
        }),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Coba latihan lagi'),
      ),
      TextButton(
        onPressed: () =>
            Navigator.pushReplacementNamed(context, '/siswa/latihan'),
        child: const Text('Pilih latihan lain'),
      ),
    ],
  );
}

String _aspectGlyph(String aspect) => switch (aspect) {
  'huruf' => 'Aa',
  'suku_kata' => 'ba',
  'kata' => 'Ibu',
  'kalimat' => 'Aa…',
  _ => 'ba',
};

Color _aspectColor(String aspect) => switch (aspect) {
  'huruf' => const Color(0xFFFFF0D3),
  'suku_kata' => const Color(0xFFE0F1E9),
  'kata' => const Color(0xFFE5F0FA),
  'kalimat' => const Color(0xFFF9E6E0),
  _ => StudentColors.mint,
};
