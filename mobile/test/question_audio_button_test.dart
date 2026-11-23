import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/student/question_audio_button.dart';

void main() {
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
  int stopCount = 0;
  VoidCallback? _onStart;
  VoidCallback? _onComplete;

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
  Future<void> speak(String text) async {
    spokenTexts.add(text);
    _onStart?.call();
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _onComplete?.call();
  }
}
