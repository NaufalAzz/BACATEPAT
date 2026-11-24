/// Reading style used for a question's spoken prompt.
enum QuestionSpeechKind { instruction, letter, syllable, word, sentence }

class QuestionSpeechProfile {
  const QuestionSpeechProfile({required this.rate, required this.pitch});

  /// Flutter TTS uses 0.5 as Android's normal speech rate.
  final double rate;
  final double pitch;
}

const questionSpeechProfiles = <QuestionSpeechKind, QuestionSpeechProfile>{
  QuestionSpeechKind.instruction: QuestionSpeechProfile(
    rate: 0.53,
    pitch: 1.03,
  ),
  QuestionSpeechKind.letter: QuestionSpeechProfile(rate: 0.50, pitch: 1.0),
  QuestionSpeechKind.syllable: QuestionSpeechProfile(rate: 0.50, pitch: 1.0),
  QuestionSpeechKind.word: QuestionSpeechProfile(rate: 0.51, pitch: 1.0),
  QuestionSpeechKind.sentence: QuestionSpeechProfile(rate: 0.52, pitch: 1.02),
};

QuestionSpeechProfile questionSpeechProfileFor(QuestionSpeechKind kind) =>
    questionSpeechProfiles[kind]!;

QuestionSpeechKind questionSpeechKindForAspect(String aspect) {
  final normalized = aspect.trim().toLowerCase().replaceAll('-', '_');
  return switch (normalized) {
    'huruf' || 'letter' => QuestionSpeechKind.letter,
    'suku_kata' || 'suku kata' || 'syllable' => QuestionSpeechKind.syllable,
    'kata' || 'word' => QuestionSpeechKind.word,
    'kalimat' || 'sentence' => QuestionSpeechKind.sentence,
    _ => QuestionSpeechKind.instruction,
  };
}

QuestionSpeechKind questionSpeechKindForQuestion({
  required String aspect,
  required String questionType,
}) {
  if (questionType.trim().toLowerCase() != 'baca lisan') {
    return QuestionSpeechKind.instruction;
  }
  return questionSpeechKindForAspect(aspect);
}

class QuestionSpeechVoiceInfo {
  const QuestionSpeechVoiceInfo({
    required this.name,
    required this.locale,
    required this.networkRequired,
    this.quality = 'unknown',
    this.latency = 'unknown',
  });

  final String name;
  final String locale;
  final bool networkRequired;
  final String quality;
  final String latency;

  factory QuestionSpeechVoiceInfo.fromAndroidMap(Map<String, String> voice) =>
      QuestionSpeechVoiceInfo(
        name: voice['name'] ?? 'unknown',
        locale: voice['locale'] ?? 'unknown',
        networkRequired: voice['network_required'] != '0',
        quality: voice['quality'] ?? 'unknown',
        latency: voice['latency'] ?? 'unknown',
      );

  String toDiagnosticString({String? engine}) =>
      'name=$name locale=$locale networkRequired=$networkRequired '
      'quality=$quality latency=$latency'
      '${engine == null ? '' : ' engine=$engine'}';
}
