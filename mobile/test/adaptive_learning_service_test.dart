import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/student/adaptive_learning_service.dart';

void main() {
  const service = AdaptiveLearningService();
  const materials = [
    AdaptiveMaterial(id: 1, aspect: 'suku_kata', level: 1, title: 'Ba bi bu'),
    AdaptiveMaterial(id: 2, aspect: 'suku_kata', level: 1, title: 'Ka ki ku'),
    AdaptiveMaterial(id: 3, aspect: 'suku_kata', level: 2, title: 'Kata suku'),
    AdaptiveMaterial(
      id: 4,
      aspect: 'suku_kata',
      level: 3,
      title: 'Kata lanjut',
    ),
    AdaptiveMaterial(id: 5, aspect: 'kata', level: 2, title: 'Kata harian'),
  ];

  test('does not infer mastery from an incomplete diagnostic', () {
    expect(
      service.fromDiagnostic(
        scores: const {'huruf': 100, 'suku_kata': 30, 'kata': 20},
        materials: materials,
        attemptedMaterialIds: const {},
      ),
      isNull,
    );
  });

  test('BRD example prioritizes syllable level one', () {
    final result = service.fromDiagnostic(
      scores: const {'huruf': 90, 'suku_kata': 50, 'kata': 30, 'kalimat': 20},
      materials: materials,
      attemptedMaterialIds: const {},
    );
    expect(result?.aspect, 'suku_kata');
    expect(result?.level, 1);
    expect(result?.materialId, 1);
    expect(result?.masteryStatus, 'belum_dikuasai');
  });

  test(
    'diagnostic thresholds assign levels and all mastered has no target',
    () {
      final low = service.fromDiagnostic(
        scores: const {
          'huruf': 59,
          'suku_kata': 100,
          'kata': 100,
          'kalimat': 100,
        },
        materials: materials,
        attemptedMaterialIds: const {},
      );
      final medium = service.fromDiagnostic(
        scores: const {
          'huruf': 60,
          'suku_kata': 100,
          'kata': 100,
          'kalimat': 100,
        },
        materials: materials,
        attemptedMaterialIds: const {},
      );
      expect(low?.level, 1);
      expect(medium?.level, 2);
      expect(
        service.fromDiagnostic(
          scores: const {
            'huruf': 80,
            'suku_kata': 80,
            'kata': 80,
            'kalimat': 80,
          },
          materials: materials,
          attemptedMaterialIds: const {},
        ),
        isNull,
      );
    },
  );

  test('one high score chooses a different material at the same level', () {
    final result = _practiceDecision(
      service,
      materials: materials,
      score: 85,
      attempted: const {1},
      previous: const [],
    );
    expect(result.level, 1);
    expect(result.materialId, 2);
    expect(result.masteryStatus, 'sedang_berlatih');
  });

  test('two high scores promote and level three mastery advances aspect', () {
    final promoted = _practiceDecision(
      service,
      materials: materials,
      score: 90,
      attempted: const {1, 2},
      previous: [_result(1, score: 85)],
    );
    expect(promoted.level, 2);
    expect(promoted.materialId, 3);

    final mastered = _practiceDecision(
      service,
      materials: materials,
      score: 90,
      level: 3,
      materialId: 4,
      attempted: const {1, 2, 4},
      previous: [_result(1, level: 3, materialId: 4, score: 85)],
      statuses: const {
        'huruf': 'dikuasai',
        'suku_kata': 'sedang_berlatih',
        'kata': 'belum_dikuasai',
        'kalimat': 'belum_dikuasai',
      },
      levels: const {'kata': 2},
    );
    expect(mastered.masteryStatus, 'dikuasai');
    expect(mastered.aspect, 'kata');
    expect(mastered.level, 2);
    expect(mastered.materialId, 5);
  });

  test('mid score reinforces and low score repeats same material', () {
    final mid = _practiceDecision(
      service,
      materials: materials,
      score: 70,
      attempted: const {1},
      previous: const [],
    );
    final low = _practiceDecision(
      service,
      materials: materials,
      score: 50,
      attempted: const {1},
      previous: const [],
    );
    expect(mid.level, 1);
    expect(mid.materialId, 2);
    expect(low.level, 1);
    expect(low.materialId, 1);
  });

  test('practice score boundaries 59, 60, 79, and 80 follow BRD actions', () {
    final low59 = _practiceDecision(
      service,
      materials: materials,
      score: 59,
      attempted: const {1},
      previous: const [],
    );
    final reinforce60 = _practiceDecision(
      service,
      materials: materials,
      score: 60,
      attempted: const {1},
      previous: const [],
    );
    final reinforce79 = _practiceDecision(
      service,
      materials: materials,
      score: 79,
      attempted: const {1},
      previous: const [],
    );
    final high80 = _practiceDecision(
      service,
      materials: materials,
      score: 80,
      attempted: const {1},
      previous: const [],
    );

    expect(low59.materialId, 1);
    expect(low59.masteryStatus, 'belum_dikuasai');
    expect(reinforce60.materialId, 2);
    expect(reinforce79.materialId, 2);
    expect(high80.materialId, 2);
    expect(high80.level, 1);
  });

  test('three low scores lower a higher level and flag level one support', () {
    final lower = _practiceDecision(
      service,
      materials: materials,
      score: 40,
      level: 2,
      materialId: 3,
      attempted: const {1, 3},
      previous: [
        _result(1, level: 2, materialId: 3, score: 45),
        _result(1, level: 2, materialId: 3, score: 50),
      ],
    );
    final support = _practiceDecision(
      service,
      materials: materials,
      score: 40,
      attempted: const {1},
      previous: [_result(1, score: 45), _result(1, score: 50)],
      sameMaterialAttempts: 3,
    );
    expect(lower.level, 1);
    expect(lower.needsSupport, isFalse);
    expect(support.level, 1);
    expect(support.needsSupport, isTrue);
    expect(support.materialId, 2);
  });

  test('twenty point aspect drop flags support', () {
    final result = _practiceDecision(
      service,
      materials: materials,
      score: 50,
      previousAspectScore: 70,
      attempted: const {1},
      previous: const [],
    );
    expect(result.needsSupport, isTrue);
    final nineteenPointDrop = _practiceDecision(
      service,
      materials: materials,
      score: 51,
      previousAspectScore: 70,
      attempted: const {1},
      previous: const [],
    );
    expect(nineteenPointDrop.needsSupport, isFalse);
  });

  test('a missing alternative does not create support or change mastery', () {
    final result = _practiceDecision(
      service,
      materials: [materials[0]],
      score: 50,
      sameMaterialAttempts: 3,
      attempted: const {1},
      previous: const [],
      previousAspectScore: 50,
    );
    expect(result.materialMissing, isTrue);
    expect(result.needsSupport, isFalse);
    expect(result.masteryStatus, 'belum_dikuasai');
  });

  test(
    'missing alternative preserves an independently earned support flag',
    () {
      final result = _practiceDecision(
        service,
        materials: [materials[0]],
        score: 50,
        sameMaterialAttempts: 3,
        attempted: const {1},
        previous: const [],
        previousAspectScore: 70,
      );
      expect(result.materialMissing, isTrue);
      expect(result.needsSupport, isTrue);
      expect(result.masteryStatus, 'belum_dikuasai');
    },
  );

  test('same material is selected after attempts one and two, not three', () {
    final afterFirst = _practiceDecision(
      service,
      materials: materials,
      score: 50,
      sameMaterialAttempts: 1,
      attempted: const {1},
      previous: const [],
    );
    final afterSecond = _practiceDecision(
      service,
      materials: materials,
      score: 50,
      sameMaterialAttempts: 2,
      attempted: const {1},
      previous: const [],
    );
    final afterThird = _practiceDecision(
      service,
      materials: materials,
      score: 50,
      sameMaterialAttempts: 3,
      attempted: const {1},
      previous: const [],
    );
    expect(afterFirst.materialId, 1);
    expect(afterSecond.materialId, 1);
    expect(afterThird.materialId, 2);
    expect(afterThird.needsSupport, isFalse);
  });

  test('high and low streaks break when an intervening score differs', () {
    final highInterruptedByLow = _practiceDecision(
      service,
      materials: materials,
      score: 90,
      attempted: const {1},
      previous: [
        _result(1, score: 50, minute: 2),
        _result(1, score: 85, minute: 1),
      ],
    );
    final lowInterruptedByHigh = _practiceDecision(
      service,
      materials: materials,
      score: 40,
      attempted: const {1},
      previous: [
        _result(1, score: 85, minute: 2),
        _result(1, score: 45, minute: 1),
      ],
    );
    expect(highInterruptedByLow.level, 1);
    expect(highInterruptedByLow.masteryStatus, 'sedang_berlatih');
    expect(lowInterruptedByHigh.level, 1);
    expect(lowInterruptedByHigh.needsSupport, isFalse);
  });

  test('streak resets when the latest practice changes aspect or level', () {
    final changedAspect = _practiceDecision(
      service,
      materials: materials,
      score: 40,
      attempted: const {1},
      previous: [_result(1, score: 45, minute: 2, aspect: 'kata')],
    );
    final changedLevel = _practiceDecision(
      service,
      materials: materials,
      score: 40,
      attempted: const {1},
      previous: [_result(1, score: 45, minute: 2, level: 2)],
    );
    expect(changedAspect.needsSupport, isFalse);
    expect(changedLevel.needsSupport, isFalse);
    expect(changedLevel.level, 1);
  });

  test('same material limit selects alternative or reports a gap', () {
    final alternative = _practiceDecision(
      service,
      materials: materials,
      score: 50,
      sameMaterialAttempts: 3,
      attempted: const {1},
      previous: const [],
    );
    final missing = _practiceDecision(
      service,
      materials: [materials[0]],
      score: 50,
      sameMaterialAttempts: 3,
      attempted: const {1},
      previous: const [],
    );
    expect(alternative.materialId, 2);
    expect(alternative.needsSupport, isFalse);
    expect(missing.materialMissing, isTrue);
    expect(missing.needsSupport, isFalse);
  });
}

AdaptiveDecision _practiceDecision(
  AdaptiveLearningService service, {
  required List<AdaptiveMaterial> materials,
  required int score,
  int level = 1,
  int materialId = 1,
  int sameMaterialAttempts = 1,
  Set<int> attempted = const {},
  List<AdaptivePracticeResult> previous = const [],
  Map<String, String> statuses = const {
    'huruf': 'dikuasai',
    'suku_kata': 'belum_dikuasai',
    'kata': 'belum_dikuasai',
    'kalimat': 'belum_dikuasai',
  },
  Map<String, int> levels = const {'suku_kata': 1, 'kata': 1, 'kalimat': 1},
  int previousAspectScore = 50,
}) => service.fromPractice(
  current: _result(1, level: level, materialId: materialId, score: score),
  previous: previous,
  masteryStatuses: statuses,
  masteryLevels: levels,
  previousAspectScores: {'suku_kata': previousAspectScore},
  materials: materials,
  attemptedMaterialIds: attempted,
  sameMaterialAttemptCount: sameMaterialAttempts,
);

AdaptivePracticeResult _result(
  int studentId, {
  int level = 1,
  int materialId = 1,
  int score = 80,
  int? minute,
  String aspect = 'suku_kata',
}) => AdaptivePracticeResult(
  studentId: studentId,
  aspect: aspect,
  level: level,
  materialId: materialId,
  score: score,
  finishedAt: DateTime(2026, 1, 1, 0, minute ?? score),
);
