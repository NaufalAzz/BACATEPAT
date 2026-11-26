import 'dart:math';

import '../../../core/api/learning_session.dart';
import '../../../core/api/bacatepat_api.dart';

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../teacher/teacher_demo_store.dart';
import '../student_demo_store.dart';
import '../question_audio_button.dart';
import '../student_widgets.dart';

class StudentPracticeListPage extends StatefulWidget {
  const StudentPracticeListPage({super.key});

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
        final materials = store.materials
            .where(
              (item) =>
                  item.status == 'aktif' &&
                  (_aspect == 'semua' || item.aspect == _aspect),
            )
            .toList();
        final recommendation = studentStore.activeRecommendation;
        final recommendationId = recommendation?.materialId;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space16,
            AppTokens.space16,
            AppTokens.space16,
            AppTokens.space24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StudentSectionLabel(
                'Ayo membaca',
                color: AppTokens.primary,
              ),
              const SizedBox(height: AppTokens.space4),
              const Text(
                'Pilih latihanmu',
                style: TextStyle(
                  fontSize: 22,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.text,
                ),
              ),
              const SizedBox(height: AppTokens.space4),
              const Text(
                'Mulai dari yang bertanda pilihan Guru.',
                style: TextStyle(fontSize: 12.5, color: AppTokens.mutedText),
              ),
              const SizedBox(height: AppTokens.space16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final option in const [
                      ('semua', 'Semua', Icons.apps_rounded),
                      ('huruf', 'Huruf', Icons.text_fields_rounded),
                      (
                        'suku_kata',
                        'Suku kata',
                        Icons.format_list_bulleted_rounded,
                      ),
                      ('kata', 'Kata', Icons.auto_stories_rounded),
                      ('kalimat', 'Kalimat', Icons.menu_book_rounded),
                    ]) ...[
                      if (option.$1 != 'semua')
                        const SizedBox(width: AppTokens.space8),
                      _AspectFilterChip(
                        label: option.$2,
                        selected: _aspect == option.$1,
                        onSelected: (_) => setState(() => _aspect = option.$1),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.space20),
              if (materials.isEmpty)
                StudentEmptyState(
                  message:
                      'Belum ada latihan untuk pilihan ini.\nCoba pilih aspek lain ya!',
                  icon: Icons.menu_book_outlined,
                )
              else
                for (final material in materials)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.space12),
                    child: _MaterialCard(
                      key: ValueKey('practice-material-${material.id}'),
                      material: material,
                      isRecommended: material.id == recommendationId,
                      score: studentStore.practiceScores[material.aspect],
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/siswa/latihan/materi',
                        arguments: material.id,
                      ),
                    ),
                  ),
              if (!studentStore.hasCompleteDiagnosticBaseline)
                Padding(
                  padding: const EdgeInsets.only(top: AppTokens.space8),
                  child: Container(
                    padding: const EdgeInsets.all(AppTokens.space12),
                    decoration: BoxDecoration(
                      color: AppTokens.sunshine,
                      borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                      border: Border.all(color: const Color(0xFFEBD78D)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppTokens.warning,
                          size: 18,
                        ),
                        const SizedBox(width: AppTokens.space10),
                        Expanded(
                          child: Text(
                            studentStore.hasAnyDiagnostic
                                ? 'Hasil diagnostik belum mencakup semua aspek. Minta bantuan Gurumu untuk melengkapi tes.'
                                : 'Kerjakan tes diagnostik terlebih dahulu agar latihan yang disarankan sesuai kemampuanmu.',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: AppTokens.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AspectFilterChip extends StatelessWidget {
  const _AspectFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    selectedColor: AppTokens.text,
    labelStyle: TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: selected ? AppTokens.surface : AppTokens.text,
    ),
    backgroundColor: AppTokens.surface,
    side: BorderSide(
      color: selected ? AppTokens.text : AppTokens.outline,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusRound),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: AppTokens.space10,
      vertical: AppTokens.space6,
    ),
    showCheckmark: false,
  );
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    super.key,
    required this.material,
    required this.isRecommended,
    this.score,
    required this.onTap,
  });

  final DemoMaterial material;
  final bool isRecommended;
  final int? score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = _aspectTint(material.aspect);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            color: AppTokens.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            border: Border.all(
              color: isRecommended ? AppTokens.primary : AppTokens.outline,
            ),
            boxShadow: AppTokens.cardShadow,
          ),
          padding: const EdgeInsets.all(AppTokens.space12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                ),
                child: Text(
                  _aspectGlyph(material.aspect),
                  style: TextStyle(
                    fontSize: 20,
                    color: AppTokens.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isRecommended) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTokens.sunshine,
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusRound,
                          ),
                        ),
                        child: const Text(
                          'PILIHAN GURU',
                          style: TextStyle(
                            fontSize: 8.5,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w900,
                            color: AppTokens.warning,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      material.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${aspectLabel(material.aspect)} · Tingkat ${material.level}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTokens.mutedText,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTokens.radiusRound),
                      child: LinearProgressIndicator(
                        value: (score ?? 0) / 100,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE9EEEC),
                        color: _aspectBarColor(material.aspect),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.space8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTokens.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _aspectGlyph(String aspect) => switch (aspect) {
  'huruf' => 'Aa',
  'suku_kata' => 'ba',
  'kata' => 'tas',
  'kalimat' => 'Aa…',
  _ => 'ba',
};

Color _aspectTint(String aspect) => switch (aspect) {
  'huruf' => const Color(0xFFFCEFC9),
  'suku_kata' => AppTokens.sky,
  'kata' => AppTokens.coralSoft,
  _ => const Color(0xFFF1EFE6),
};

Color _aspectBarColor(String aspect) => switch (aspect) {
  'huruf' => AppTokens.accent,
  'suku_kata' => AppTokens.secondary,
  'kata' => AppTokens.coral,
  _ => AppTokens.primary,
};

class StudentMaterialDetailPage extends StatelessWidget {
  const StudentMaterialDetailPage({super.key, this.materialId});

  final int? materialId;

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final material = materialId == null
        ? null
        : store.materialById(materialId!);
    if (material == null || material.status != 'aktif') {
      return Center(
        child: StudentEmptyState(
          message: 'Materi ini belum tersedia. Coba pilih latihan lain ya!',
          icon: Icons.menu_book_outlined,
        ),
      );
    }
    final catalog = store.questions.where(
      (q) =>
          q.materialId == material.id &&
          q.status == 'disetujui' &&
          q.usage != 'diagnostik',
    );
    final hasPracticeQuestions = LearningSession.enabled
        ? catalog.isNotEmpty && catalog.every((q) => q.type == 'Pilihan ganda')
        : store.practiceQuestionsForMaterial(material.id).isNotEmpty;
    final contentLines = material.content.split('\n');
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        AppTokens.space16,
        AppTokens.space16,
        AppTokens.space24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTokens.coralSoft,
                borderRadius: BorderRadius.circular(AppTokens.radiusRound),
              ),
              child: Text(
                '${aspectLabel(material.aspect).toUpperCase()} · TINGKAT ${material.level}',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTokens.coralDark,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space10),
          Text(
            material.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          const Text(
            'Lihat, dengar, lalu baca bersama.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppTokens.mutedText),
          ),
          const SizedBox(height: AppTokens.space16),
          StudentPanel(
            padding: const EdgeInsets.all(AppTokens.space20),
            child: Column(
              children: [
                Image.asset(
                  'assets/illustrations/reading-book.png',
                  width: 120,
                  height: 96,
                  semanticLabel: 'Ilustrasi buku terbuka',
                ),
                const SizedBox(height: AppTokens.space12),
                Text(
                  contentLines.first.replaceAll(' • ', '   '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.text,
                  ),
                ),
                if (contentLines.length > 1) ...[
                  const SizedBox(height: AppTokens.space8),
                  Text(
                    contentLines.skip(1).join('\n').replaceAll(' • ', '   '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppTokens.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space12),
          Container(
            padding: const EdgeInsets.all(AppTokens.space14),
            decoration: BoxDecoration(
              color: AppTokens.sunshine,
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
              border: Border.all(color: const Color(0xFFEBD78D)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: AppTokens.warning,
                ),
                SizedBox(width: AppTokens.space10),
                Expanded(
                  child: Text(
                    'Tunjuk setiap huruf atau kata sambil membacanya. Pelan-pelan saja.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppTokens.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space20),
          if (hasPracticeQuestions)
            StudentAction(
              key: const ValueKey('material-start-exercise'),
              label: 'Mulai latihan',
              icon: Icons.play_arrow_rounded,
              onPressed: () => Navigator.pushNamed(
                context,
                '/siswa/latihan/kerjakan',
                arguments: material.id,
              ),
            )
          else
            StudentEmptyState(
              message:
                  'Latihan untuk materi ini belum tersedia.\nCoba materi lain ya!',
              icon: Icons.quiz_outlined,
            ),
        ],
      ),
    );
  }
}

class StudentExercisePage extends StatefulWidget {
  const StudentExercisePage({super.key, this.materialId});
  final int? materialId;

  @override
  State<StudentExercisePage> createState() => _StudentExercisePageState();
}

class _StudentExercisePageState extends State<StudentExercisePage> {
  late final DemoMaterial? _material;
  late List<DemoQuestion> _questions;
  int? _remoteId;
  bool _busy = false;
  bool _correctSelection = false;
  Future<void>? _loading;
  Future<void> _startRemote() async {
    final material = _material!;
    final result = await LearningSession.api.request(
      'siswa/latihan/mulai',
      body: {'materi_id': material.id},
    );
    if (!mounted) return;
    final data = result['data'];
    _remoteId = data['hasil_id'];
    _questions = [
      for (final r in data['soal'])
        DemoQuestion(
          id: r['soal_id'],
          materialId: material.id,
          prompt: r['pertanyaan'],
          picture: r['stimulus'] ?? '',
          aspect: material.aspect,
          level: material.level,
          type: 'Pilihan ganda',
          choices: List<String>.from(r['opsi']),
          hint:
              TeacherDemoStore.instance.questions
                  .where((q) => q.id == r['soal_id'])
                  .firstOrNull
                  ?.hint ??
              '',
          correctFeedback: 'Bagus, jawabanmu tepat!',
        ),
    ];
  }

  Future<void> _choose(int index) async {
    if (_busy) return;
    if (LearningSession.enabled) {
      _busy = true;
      try {
        final q = _questions[_questionIndex];
        final result = await LearningSession.api.request(
          'siswa/latihan/$_remoteId/jawaban',
          body: {'soal_id': q.id, 'jawaban': q.choices[index]},
        );
        if (!mounted) return;
        _correctSelection = result['benar'] == true;
      } on ApiError catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
        return;
      } finally {
        _busy = false;
      }
    }

    setState(() => _selected = index);
  }

  bool get _isRight =>
      _selected != null &&
      (LearningSession.enabled
          ? _correctSelection
          : _selected == _questions[_questionIndex].correctAnswerIndex);

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
    if (LearningSession.enabled && _material != null) _loading = _startRemote();
    _startedAt = DateTime.now();
    _completionToken = '${_startedAt.microsecondsSinceEpoch}-$hashCode';
    final recommendation = StudentDemoStore.instance.activeRecommendation;
    _recommendationId = recommendation?.materialId == _material?.id
        ? recommendation?.id
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading != null) {
      return FutureBuilder<void>(
        future: _loading,
        builder: (context, state) {
          if (state.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.hasError) {
            return Center(
              child: StudentPanel(
                padding: const EdgeInsets.all(AppTokens.space20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: AppTokens.error,
                    ),
                    const SizedBox(height: AppTokens.space12),
                    const Text(
                      'Gagal memuat latihan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space8),
                    Text(
                      '${state.error}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTokens.mutedText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTokens.space16),
                    StudentAction(
                      label: 'Coba lagi',
                      icon: Icons.refresh_rounded,
                      onPressed: () => setState(() => _loading = _startRemote()),
                      expanded: false,
                    ),
                  ],
                ),
              ),
            );
          }
          return _exercise(context);
        },
      );
    }
    return _exercise(context);
  }

  Widget _exercise(BuildContext context) {
    final material = _material;
    if (material == null || material.status != 'aktif') {
      return Center(
        child: StudentEmptyState(message: 'Materi ini belum tersedia.'),
      );
    }
    if (_questions.isEmpty) {
      return Center(
        child: StudentEmptyState(
          message: 'Latihan untuk materi ini belum tersedia. Coba materi lain ya!',
        ),
      );
    }
    if (_finished) return _result(context);

    final question = _questions[_questionIndex];
    final answered = _selected != null;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space16,
              AppTokens.space12,
              AppTokens.space16,
              AppTokens.space16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_questionIndex + 1} dari ${_questions.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTokens.text,
                        ),
                      ),
                    ),
                    Text(
                      '+${_correct * 10} bintang',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusRound),
                  child: LinearProgressIndicator(
                    value: (_questionIndex + 1) / _questions.length,
                    minHeight: 4,
                    color: AppTokens.coral,
                    backgroundColor: const Color(0xFFE4EAEA),
                  ),
                ),
                const SizedBox(height: AppTokens.space24),
                if (question.picture.isNotEmpty)
                  Semantics(
                    label: 'Gambar petunjuk',
                    child: Text(
                      question.picture,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 88, height: 1.2),
                    ),
                  ),
                const SizedBox(height: AppTokens.space12),
                if (question.prompt != 'Pilih kata yang cocok dengan gambar.')
                  Text(
                    question.prompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: AppTokens.text,
                    ),
                  ),
                const SizedBox(height: AppTokens.space16),
                Row(
                  children: [
                    for (var i = 0; i < question.choices.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppTokens.space10),
                      Expanded(
                        child: StudentChoiceTile(
                          key: ValueKey('exercise-answer-$i'),
                          text: question.choices[i],
                          selected: _selected == i,
                          correct: question.correctAnswerIndex == i,
                          enabled: !answered,
                          onTap: () => _choose(i),
                        ),
                      ),
                    ],
                  ],
                ),
                if (answered) ...[
                  const SizedBox(height: AppTokens.space12),
                  Text(
                    _isRight
                        ? question.correctFeedback
                        : 'Tidak apa-apa. ${question.hint}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: _isRight
                          ? AppTokens.primary
                          : AppTokens.coralDark,
                    ),
                  ),
                ],
                const SizedBox(height: AppTokens.space20),
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
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space16,
            AppTokens.space8,
            AppTokens.space16,
            AppTokens.space16,
          ),
          child: FilledButton(
            key: const ValueKey('exercise-next'),
            onPressed: answered ? _submitCurrentAnswer : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.primary,
              disabledBackgroundColor: const Color(0xFF9AC7BC),
              minimumSize: const Size.fromHeight(AppTokens.studentButtonHeight),
            ),
            child: Text(
              _questionIndex == _questions.length - 1
                  ? 'Lihat hasil'
                  : 'Soal berikutnya',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitCurrentAnswer() async {
    final material = _material;
    if (material == null) return;
    final question = _questions[_questionIndex];
    final selected = _selected!;
    if (LearningSession.enabled) {
      if (_busy) return;
      if (_questionIndex + 1 == _questions.length) {
        _busy = true;
        try {
          await LearningSession.api.request(
            'siswa/latihan/$_remoteId/selesai',
            body: {},
          );
          await LearningSession.refresh();
          if (!mounted) return;
          _attempt = StudentDemoStore.instance.practiceHistory.firstWhere(
            (a) => a.id == _remoteId,
          );
          setState(() => _finished = true);
        } on ApiError catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.message)));
          }
        } finally {
          _busy = false;
        }
        return;
      }
    } else {
      final answer = PracticeAnswerRecord(
        questionId: question.id,
        aspect: question.aspect,
        answer: question.choices[selected],
        correctAnswer: question.correctAnswer!,
        isCorrect: selected == question.correctAnswerIndex,
      );
      _answers.add(answer);
      if (answer.isCorrect) _correct++;
    }

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

  Widget _result(BuildContext context) {
    final attempt = _attempt;
    final score = attempt?.score ?? 0;
    final correct = attempt?.answers.where((a) => a.isCorrect).length ?? 0;
    final total = attempt?.answers.length ?? _questions.length;
    final stars = score >= 85
        ? 3
        : score >= 60
        ? 2
        : 1;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        AppTokens.space24,
        AppTokens.space16,
        AppTokens.space24,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Icon(
                Icons.star_rounded,
                size: 30,
                color: i < stars ? AppTokens.accent : AppTokens.outline,
              ),
          ],
        ),
        const SizedBox(height: AppTokens.space16),
        Text(
          'Hebat, ${StudentDemoStore.instance.studentName.split(' ').first}!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppTokens.text,
          ),
        ),
        const SizedBox(height: AppTokens.space8),
        Text(
          'Kamu menyelesaikan latihan ${_material!.title}.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppTokens.mutedText,
          ),
        ),
        const SizedBox(height: AppTokens.space20),
        Container(
          padding: const EdgeInsets.all(AppTokens.space16),
          decoration: BoxDecoration(
            color: AppTokens.primary,
            borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.white24,
                        color: AppTokens.accent,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'nilai',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTokens.mint,
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusRound,
                        ),
                      ),
                      child: const Text(
                        'DIKUASAI',
                        style: TextStyle(
                          fontSize: 8.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w900,
                          color: AppTokens.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.space6),
                    Text(
                      '$correct dari $total benar',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Dua latihan bagus lagi dapat membawamu naik tingkat.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        StudentAction(
          key: const ValueKey('exercise-see-progress'),
          label: 'Lihat kemajuanku',
          icon: Icons.show_chart_rounded,
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/siswa/perkembangan'),
        ),
        const SizedBox(height: AppTokens.space10),
        OutlinedButton(
          key: const ValueKey('exercise-home'),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/siswa'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppTokens.studentButtonHeight),
            side: const BorderSide(color: AppTokens.outline),
            foregroundColor: AppTokens.primary,
          ),
          child: const Text('Kembali ke beranda'),
        ),
        Center(
          child: TextButton(
            key: const ValueKey('exercise-repeat'),
            onPressed: () => setState(() {
              if (LearningSession.enabled) _loading = _startRemote();
              _questionIndex = 0;
              _correct = 0;
              _selected = null;
              _answers.clear();
              _attempt = null;
              _startedAt = DateTime.now();
              _completionToken =
                  '${_startedAt.microsecondsSinceEpoch}-$hashCode';
              final recommendation =
                  StudentDemoStore.instance.activeRecommendation;
              _recommendationId =
                  recommendation != null &&
                      recommendation.materialId == _material.id
                  ? recommendation.id
                  : null;
              _finished = false;
            }),
            child: const Text(
              'Ulangi latihan',
              style: TextStyle(fontSize: 12, color: AppTokens.secondary),
            ),
          ),
        ),
        if (attempt != null) ...[
          const SizedBox(height: AppTokens.space8),
          StudentAction(
            key: const ValueKey('exercise-record-reading'),
            label: 'Baca dengan suara',
            icon: Icons.mic_none_rounded,
            color: AppTokens.secondary,
            onPressed: () => Navigator.pushNamed(
              context,
              '/siswa/rekaman',
              arguments: _material.title,
            ),
          ),
        ],
      ],
    );
  }
}
