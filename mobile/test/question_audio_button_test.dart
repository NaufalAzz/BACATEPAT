import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/student/question_audio_button.dart';

void main() {
  test('selects the best installed Indonesian offline voice', () {
    final selected = chooseIndonesianOfflineVoice([
      {
        'name': 'remote-neural',
        'locale': 'id-ID',
        'quality': 'very high',
        'network_required': '1',
        'features': '',
      },
      {
        'name': 'not-downloaded',
        'locale': 'id-ID',
        'quality': 'very high',
        'network_required': '0',
        'features': 'notInstalled',
      },
      {
        'name': 'local-basic',
        'locale': 'id-ID',
        'quality': 'normal',
        'network_required': '0',
        'features': '',
      },
      {
        'name': 'local-high-quality',
        'locale': 'id-ID',
        'quality': 'high',
        'latency': 'normal',
        'network_required': '0',
        'features': '',
      },
      {
        'name': 'local-low-latency',
        'locale': 'id-ID',
        'quality': 'normal',
        'latency': 'very low',
        'network_required': '0',
        'features': '',
      },
    ]);

    expect(selected?['name'], 'local-low-latency');
    expect(
      chooseIndonesianOfflineVoice([
        {
          'name': 'remote-only',
          'locale': 'id-ID',
          'quality': 'very high',
          'network_required': '1',
          'features': '',
        },
      ]),
      isNull,
    );
    expect(
      chooseIndonesianOfflineVoice([
        {
          'name': 'network-status-unknown',
          'locale': 'id-ID',
          'quality': 'very high',
          'features': '',
        },
      ]),
      isNull,
    );
  });

  test('maps reading content to centrally defined speech profiles', () {
    expect(questionSpeechKindForAspect('huruf'), QuestionSpeechKind.letter);
    expect(
      questionSpeechKindForAspect('suku_kata'),
      QuestionSpeechKind.syllable,
    );
    expect(questionSpeechKindForAspect('kata'), QuestionSpeechKind.word);
    expect(questionSpeechKindForAspect('kalimat'), QuestionSpeechKind.sentence);
    expect(
      questionSpeechKindForAspect('lainnya'),
      QuestionSpeechKind.instruction,
    );
    expect(
      questionSpeechKindForQuestion(
        aspect: 'kata',
        questionType: 'Pilihan ganda',
      ),
      QuestionSpeechKind.instruction,
    );
    expect(
      questionSpeechKindForQuestion(aspect: 'kata', questionType: 'Baca lisan'),
      QuestionSpeechKind.word,
    );

    expect(questionSpeechProfileFor(QuestionSpeechKind.letter).rate, 0.40);
    expect(questionSpeechProfileFor(QuestionSpeechKind.syllable).rate, 0.40);
    expect(questionSpeechProfileFor(QuestionSpeechKind.word).rate, 0.41);
    expect(questionSpeechProfileFor(QuestionSpeechKind.sentence).rate, 0.42);
    expect(questionSpeechProfileFor(QuestionSpeechKind.instruction).rate, 0.43);
    expect(questionSpeechProfileFor(QuestionSpeechKind.sentence).pitch, 1.02);
  });

  test('voice diagnostics expose selected voice metadata', () {
    final info = QuestionSpeechVoiceInfo.fromAndroidMap({
      'name': 'id-id-x-local',
      'locale': 'id-ID',
      'network_required': '0',
      'quality': 'high',
      'latency': 'low',
    });
    expect(info.name, 'id-id-x-local');
    expect(info.locale, 'id-ID');
    expect(info.networkRequired, isFalse);
    expect(
      info.toDiagnosticString(engine: 'android.tts'),
      contains('engine=android.tts'),
    );
    expect(info.toDiagnosticString(), contains('networkRequired=false'));
  });

  testWidgets('plays the prompt on demand, replays, and stops on second tap', (
    tester,
  ) async {
    final engine = _FakeQuestionSpeechEngine();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestionAudioButton(
            text: 'Lengkapi kalimat: Ayah minum ___.',
            engine: engine,
          ),
        ),
      ),
    );

    expect(engine.spokenTexts, isEmpty);
    await tester.tap(find.byKey(const ValueKey('question-audio-button')));
    await tester.pumpAndSettle();
    expect(engine.spokenTexts, [
      'Lengkapi kalimat: Ayah minum bagian yang kosong.',
    ]);
    expect(engine.spokenKinds, [QuestionSpeechKind.instruction]);
    expect(find.text('Sedang dibacakan'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('question-audio-button')));
    await tester.pumpAndSettle();
    expect(engine.stopCount, 2);
    expect(find.text('Sedang dibacakan'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('question-audio-button')));
    await tester.pumpAndSettle();
    expect(engine.spokenTexts, hasLength(2));
  });

  testWidgets('stops when the question widget is replaced or removed', (
    tester,
  ) async {
    final engine = _FakeQuestionSpeechEngine();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestionAudioButton(
            key: const ValueKey('question-a'),
            text: 'Pilih huruf awal.',
            engine: engine,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('question-audio-button')));
    await tester.pumpAndSettle();
    final stopsBeforeReplacement = engine.stopCount;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestionAudioButton(
            key: const ValueKey('question-b'),
            text: 'Pilih suku kata.',
            engine: engine,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(engine.stopCount, greaterThan(stopsBeforeReplacement));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(engine.stopCount, greaterThan(stopsBeforeReplacement + 1));
  });

  testWidgets('shows a fallback when Indonesian speech is unavailable', (
    tester,
  ) async {
    final engine = _FakeQuestionSpeechEngine(indonesianAvailable: false);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestionAudioButton(text: 'Dengarkan soal.', engine: engine),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('question-audio-button')));
    await tester.pumpAndSettle();
    expect(find.text('Suara bahasa Indonesia tidak tersedia.'), findsOneWidget);
    expect(engine.spokenTexts, isEmpty);
  });
}

class _FakeQuestionSpeechEngine implements QuestionSpeechEngine {
  _FakeQuestionSpeechEngine({this.indonesianAvailable = true});

  final bool indonesianAvailable;
  final List<String> spokenTexts = [];
  final List<QuestionSpeechKind> spokenKinds = [];
  int stopCount = 0;
  VoidCallback? _onStart;
  VoidCallback? _onComplete;

  @override
  QuestionSpeechVoiceInfo? get selectedVoiceInfo => null;

  @override
  set onStart(VoidCallback? callback) => _onStart = callback;

  @override
  set onComplete(VoidCallback? callback) => _onComplete = callback;

  @override
  set onError(VoidCallback? callback) {}

  @override
  Future<bool> supportsIndonesian() async => indonesianAvailable;

  @override
  Future<void> configure() async {}

  @override
  Future<void> speak(
    String text, {
    QuestionSpeechKind kind = QuestionSpeechKind.instruction,
  }) async {
    spokenTexts.add(text);
    spokenKinds.add(kind);
    _onStart?.call();
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _onComplete?.call();
  }
}
