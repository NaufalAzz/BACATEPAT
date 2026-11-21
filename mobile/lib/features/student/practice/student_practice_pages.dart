import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../teacher/teacher_demo_store.dart';
import '../student_demo_store.dart';
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
    final materials = store.materials
        .where(
          (item) =>
              item.status == 'aktif' &&
              (_aspect == 'semua' || item.aspect == _aspect),
        )
        .toList();
    final recommendationId = StudentDemoStore.instance.recommendedMaterialId;
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
        if (materials.isEmpty)
          const StudentEmptyState(
            message:
                'Belum ada latihan untuk pilihan ini. Coba pilihan lain ya!',
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
                  onTap: () => Navigator.pushNamed(
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
                              const SizedBox(height: 7),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: LinearProgressIndicator(
                                  value:
                                      (StudentDemoStore.instance.scores[material
                                              .aspect] ??
                                          0) /
                                      100,
                                  minHeight: 5,
                                  backgroundColor: const Color(0xFFE9EFED),
                                  color: AppTokens.primary,
                                ),
                              ),
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
  }
}

class StudentMaterialDetailPage extends StatelessWidget {
  const StudentMaterialDetailPage({this.materialId, super.key});

  final int? materialId;

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final material = materialId == null
        ? null
        : store.materialById(materialId!);
    if (material == null || material.status != 'aktif') {
      return const Center(
        child: StudentEmptyState(
          message: 'Materi ini belum tersedia. Coba pilih latihan lain ya!',
        ),
      );
    }
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
        StudentAction(
          key: const ValueKey('material-start-exercise'),
          label: 'Mulai latihan',
          icon: Icons.play_arrow_rounded,
          onPressed: () => Navigator.pushNamed(
            context,
            '/siswa/latihan/kerjakan',
            arguments: material.id,
          ),
        ),
      ],
    );
  }
}

class _PracticeQuestion {
  const _PracticeQuestion(this.prompt, this.choices, this.correctIndex);
  final String prompt;
  final List<String> choices;
  final int correctIndex;
}

class StudentExercisePage extends StatefulWidget {
  const StudentExercisePage({this.materialId, super.key});
  final int? materialId;

  @override
  State<StudentExercisePage> createState() => _StudentExercisePageState();
}

class _StudentExercisePageState extends State<StudentExercisePage> {
  int _questionIndex = 0;
  int _correct = 0;
  int? _selected;
  bool _finished = false;

  static const _questions = [
    _PracticeQuestion('Pilih suku kata “ba”.', ['ba', 'da', 'ma'], 0),
    _PracticeQuestion('Pilih suku kata “bi”.', ['bu', 'be', 'bi'], 2),
    _PracticeQuestion('Kata “bola” dimulai dengan huruf apa?', [
      'b',
      'm',
      's',
    ], 0),
    _PracticeQuestion('Mana yang dibaca “buku”?', ['buka', 'buku', 'daku'], 1),
    _PracticeQuestion('Lengkapi kalimat: Ibu membeli ___.', [
      'bola',
      'lari',
      'pagi',
    ], 0),
  ];

  @override
  Widget build(BuildContext context) {
    final material = widget.materialId == null
        ? null
        : TeacherDemoStore.instance.materialById(widget.materialId!);
    final title = material?.title ?? 'Latihan membaca';
    final aspect = material?.aspect ?? 'suku_kata';
    if (_finished) return _result(context, title, aspect);
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
                    '+${(_questionIndex + 1) * 10} bintang',
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
                    Image.asset(
                      'assets/illustrations/reading-book.png',
                      width: 100,
                      height: 78,
                      semanticLabel: 'Ilustrasi buku untuk latihan membaca',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      question.prompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.text,
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
                              ? StudentColors.mint
                              : Colors.white,
                          side: BorderSide(
                            color: _selected == i
                                ? AppTokens.primary
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
                  color: _selected == question.correctIndex
                      ? StudentColors.mint
                      : StudentColors.peach,
                  child: Text(
                    _selected == question.correctIndex
                        ? 'Hebat! Jawabanmu benar! ⭐'
                        : 'Tidak apa-apa, terus mencoba ya! 🌱',
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
              onPressed: () {
                if (_selected == question.correctIndex) _correct++;
                if (_questionIndex == _questions.length - 1) {
                  final score = (_correct * 100 / _questions.length).round();
                  StudentDemoStore.instance.finishPractice(
                    title: title,
                    aspect: aspect,
                    score: score,
                  );
                  setState(() => _finished = true);
                } else {
                  setState(() {
                    _questionIndex++;
                    _selected = null;
                  });
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _result(BuildContext context, String title, String aspect) => ListView(
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
              '${StudentDemoStore.instance.lastPracticeScore ?? 0}%',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            Text(
              'Skor latihanmu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              'Terus berlatih ${aspectLabel(aspect).toLowerCase()} ya!',
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
        onPressed: () =>
            Navigator.pushNamed(context, '/siswa/rekaman', arguments: title),
      ),
      const SizedBox(height: AppTokens.space8),
      OutlinedButton.icon(
        key: const ValueKey('exercise-repeat'),
        onPressed: () => setState(() {
          _questionIndex = 0;
          _correct = 0;
          _selected = null;
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
