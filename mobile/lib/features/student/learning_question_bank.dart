class LearningQuestion {
  const LearningQuestion({
    required this.aspect,
    required this.prompt,
    required this.picture,
    required this.choices,
    required this.correctIndex,
    required this.hint,
    required this.correctFeedback,
  });

  final String aspect;
  final String prompt;
  final String picture;
  final List<String> choices;
  final int correctIndex;
  final String hint;
  final String correctFeedback;

  bool get hasValidAnswer =>
      choices.length >= 2 && correctIndex >= 0 && correctIndex < choices.length;

  bool get promptLeaksAnswer {
    if (!hasValidAnswer) return true;
    final answer = RegExp.escape(choices[correctIndex].toLowerCase());
    return RegExp('(^|[^a-z])$answer([^a-z]|\$)')
        .hasMatch(prompt.toLowerCase());
  }
}

const diagnosticQuestions = <LearningQuestion>[
  LearningQuestion(
    aspect: 'huruf',
    prompt: 'Huruf pertama nama gambar ini adalah …',
    picture: '👕',
    choices: ['b', 'd', 'm'],
    correctIndex: 0,
    hint: 'Sebutkan nama bendanya, lalu dengarkan bunyi paling awal.',
    correctFeedback: 'Tepat! Kamu menemukan bunyi huruf awalnya.',
  ),
  LearningQuestion(
    aspect: 'huruf',
    prompt: 'Huruf pertama nama gambar ini adalah …',
    picture: '⚽',
    choices: ['s', 'b', 'p'],
    correctIndex: 1,
    hint: 'Ucapkan nama gambar pelan-pelan. Bunyi pertama membantu kamu.',
    correctFeedback: 'Betul! Kamu mengenali huruf awal gambar.',
  ),
  LearningQuestion(
    aspect: 'suku_kata',
    prompt: 'Pilih suku kata awal nama gambar ini.',
    picture: '👕',
    choices: ['ba', 'bi', 'bu'],
    correctIndex: 0,
    hint: 'Ucapkan nama gambar. Dengarkan dua bunyi pertamanya.',
    correctFeedback: 'Hebat! Kamu menemukan suku kata awalnya.',
  ),
  LearningQuestion(
    aspect: 'suku_kata',
    prompt: 'Pilih suku kata awal nama gambar ini.',
    picture: '⚽',
    choices: ['be', 'bo', 'bu'],
    correctIndex: 1,
    hint: 'Ucapkan nama gambar perlahan dan dengarkan bagian awalnya.',
    correctFeedback: 'Benar! Bunyi awalnya cocok dengan gambar.',
  ),
  LearningQuestion(
    aspect: 'kata',
    prompt: 'Kata mana yang cocok dengan gambar ini?',
    picture: '📖',
    choices: ['buku', 'baju', 'bola'],
    correctIndex: 0,
    hint: 'Baca pilihan kata dari kiri ke kanan, lalu cocokkan dengan gambar.',
    correctFeedback: 'Tepat! Kamu mencocokkan kata dan gambar.',
  ),
  LearningQuestion(
    aspect: 'kata',
    prompt: 'Kata mana yang cocok dengan gambar ini?',
    picture: '🪑',
    choices: ['mata', 'meja', 'madu'],
    correctIndex: 1,
    hint: 'Perhatikan semua huruf pada pilihan, bukan hanya huruf awalnya.',
    correctFeedback: 'Bagus! Kamu membaca kata dengan teliti.',
  ),
  LearningQuestion(
    aspect: 'kalimat',
    prompt: 'Kalimat mana yang sesuai dengan gambar ini?',
    picture: '👩‍🍳🍚',
    choices: ['Ibu makan nasi.', 'Ibu memasak nasi.', 'Ibu mencuci baju.'],
    correctIndex: 1,
    hint:
        'Amati kegiatan pada gambar, lalu baca setiap kalimat sampai selesai.',
    correctFeedback: 'Betul! Kalimatmu sesuai dengan gambar.',
  ),
  LearningQuestion(
    aspect: 'kalimat',
    prompt: 'Kalimat mana yang sesuai dengan gambar ini?',
    picture: '🧒⚽',
    choices: ['Budi menendang bola.', 'Budi membaca buku.', 'Budi minum susu.'],
    correctIndex: 0,
    hint: 'Lihat apa yang dilakukan anak pada gambar dan cocokkan dengan kalimat.',
    correctFeedback: 'Hebat! Kamu memahami kalimat dan gambarnya.',
  ),
];
