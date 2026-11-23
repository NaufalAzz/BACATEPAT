import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/teacher/teacher_demo_store.dart';

void main() {
  final store = TeacherDemoStore.instance;

  test('seeded question bank carries keyed choices and oral targets', () {
    final letter = store.questionById(1)!;
    expect(letter.materialId, isNull);
    expect(letter.choices, ['b', 'd', 'm']);
    expect(letter.correctAnswer, 'b');
    expect(
      letter.canBeUsedFor('diagnostik', materials: store.materials),
      isTrue,
    );
    final practiceQuestion = store.questionById(7)!;
    expect(practiceQuestion.materialId, 5);
    expect(
      practiceQuestion.canBeUsedFor('latihan', materials: store.materials),
      isTrue,
    );
    expect(store.questionById(3)!.targetText, 'bola');
    expect(
      store.questionById(3)!.validationIssues(materials: store.materials),
      isEmpty,
    );
  });

  test(
    'incomplete, duplicate, missing-key and leaking multiple choice fail',
    () {
      DemoQuestion question({
        List<String> choices = const ['ba', 'bi'],
        int? answer = 0,
        String prompt = 'Pilih suku kata awal pada gambar.',
      }) => DemoQuestion(
        id: 90,
        prompt: prompt,
        aspect: 'suku_kata',
        level: 1,
        type: 'Pilihan ganda',
        choices: choices,
        correctAnswerIndex: answer,
      );

      expect(question().validationIssues(), isEmpty);
      expect(question(choices: ['ba', 'BA']).validationIssues(), isNotEmpty);
      expect(question(answer: null).validationIssues(), isNotEmpty);
      expect(
        question(prompt: 'Pilih BA untuk gambar ini.').validationIssues(),
        isNotEmpty,
      );
      expect(
        question(choices: ['ba'], answer: 0).validationIssues(),
        isNotEmpty,
      );
    },
  );

  test(
    'save and edit preserve fields; incomplete questions cannot be approved',
    () {
      final id = store.saveQuestion(
        prompt: 'Pilih suku kata awal pada gambar.',
        aspect: 'suku_kata',
        level: 2,
        type: 'Pilihan ganda',
        materialId: 1,
        choices: ['ba', 'bi', 'bu'],
        correctAnswerIndex: 0,
        hint: 'Dengarkan bunyi awalnya.',
        correctFeedback: 'Bagus, kamu teliti!',
        usage: 'latihan',
      );
      final item = store.questionById(id)!;
      expect(item.status, 'draf');
      expect(item.materialId, 1);
      expect(item.correctAnswer, 'ba');
      expect(item.hint, 'Dengarkan bunyi awalnya.');
      expect(store.setQuestionStatus(id, 'disetujui'), isTrue);

      final editedId = store.saveQuestion(
        id: id,
        prompt: 'Pilih suku kata awal untuk gambar baru.',
        aspect: 'suku_kata',
        level: 2,
        type: 'Pilihan ganda',
        materialId: 1,
        choices: ['ka', 'ki'],
        correctAnswerIndex: null,
      );
      expect(editedId, id);
      expect(store.questionById(id)!.status, 'draf');
      expect(store.setQuestionStatus(id, 'disetujui'), isFalse);
      expect(store.deleteQuestion(id), isTrue);
    },
  );

  test('editing a question already referenced by a diagnostic creates a draft copy', () {
    final original = store.questionById(1)!;
    final originalPrompt = original.prompt;
    final id = store.saveQuestion(
      id: 1,
      prompt: 'Pilih huruf awal nama gambar.',
      aspect: 'huruf',
      level: 1,
      type: 'Pilihan ganda',
      materialId: 5,
      choices: ['b', 'd', 'm'],
      correctAnswerIndex: 0,
    );
    expect(id, isNot(1));
    expect(store.questionById(1)!.prompt, originalPrompt);
    expect(store.questionById(id)!.status, 'draf');
    expect(store.deleteQuestion(id), isTrue);
  });

  test(
    'diagnostic activation rejects questions that are not approved and valid',
    () {
      final draftId = store.saveQuestion(
        prompt: 'Pilih huruf pada gambar.',
        aspect: 'huruf',
        level: 1,
        type: 'Pilihan ganda',
        choices: ['b', 'd'],
        correctAnswerIndex: 0,
        status: 'draf',
      );
      final diagnostic = DemoDiagnostic(
        id: 99,
        title: 'Tes validasi sementara',
        classId: 1,
        questionIds: [draftId, 2, 3, 4],
      );
      store.diagnostics.add(diagnostic);
      expect(store.activateDiagnostic(diagnostic.id), isFalse);
      store.diagnostics.remove(diagnostic);
      expect(store.deleteQuestion(draftId), isTrue);
    },
  );

  test(
    'changing status of a referenced question preserves its used version',
    () {
      final original = store.questionById(1)!;
      final countBefore = store.questions.length;
      expect(store.setQuestionStatus(1, 'nonaktif'), isTrue);
      expect(store.questionById(1)!.status, 'disetujui');
      expect(store.questions.length, countBefore + 1);
      final newVersion = store.questions.last;
      expect(newVersion.id, isNot(1));
      expect(newVersion.status, 'nonaktif');
      expect(newVersion.prompt, original.prompt);
      expect(store.deleteQuestion(newVersion.id), isTrue);
    },
  );
}
