class AdaptiveMaterial {
  const AdaptiveMaterial({
    required this.id,
    required this.aspect,
    required this.level,
    required this.title,
  });

  final int id;
  final String aspect;
  final int level;
  final String title;
}

class AdaptivePracticeResult {
  const AdaptivePracticeResult({
    required this.studentId,
    required this.aspect,
    required this.level,
    required this.materialId,
    required this.score,
    required this.finishedAt,
  });

  final int studentId;
  final String aspect;
  final int level;
  final int materialId;
  final int score;
  final DateTime finishedAt;
}

class AdaptiveDecision {
  const AdaptiveDecision({
    required this.aspect,
    required this.level,
    required this.score,
    required this.masteryStatus,
    required this.reason,
    this.materialId,
    this.needsSupport = false,
    this.materialMissing = false,
  });

  final String aspect;
  final int level;
  final int score;
  final String masteryStatus;
  final String reason;
  final int? materialId;
  final bool needsSupport;
  final bool materialMissing;
}

class AdaptiveLearningService {
  const AdaptiveLearningService();

  static const aspects = ['huruf', 'suku_kata', 'kata', 'kalimat'];
  static const masteryThreshold = 80;
  static const practiceThreshold = 60;
  static const promotionStreak = 2;
  static const maxSameMaterialAttempts = 3;
  static const supportDropThreshold = 20;

  AdaptiveDecision? fromDiagnostic({
    required Map<String, int> scores,
    required List<AdaptiveMaterial> materials,
    required Set<int> attemptedMaterialIds,
  }) {
    if (!aspects.every(scores.containsKey)) return null;

    for (final aspect in aspects) {
      final score = scores[aspect]!;
      if (score >= masteryThreshold) continue;
      final level = score < practiceThreshold ? 1 : 2;
      return _decisionForTarget(
        aspect: aspect,
        level: level,
        score: score,
        status: score < practiceThreshold
            ? 'belum_dikuasai'
            : 'sedang_berlatih',
        reason: 'Aspek pertama yang masih perlu dilatih dari hasil diagnostik.',
        materials: materials,
        attemptedMaterialIds: attemptedMaterialIds,
      );
    }
    return null;
  }

  AdaptiveDecision fromPractice({
    required AdaptivePracticeResult current,
    required List<AdaptivePracticeResult> previous,
    required Map<String, String> masteryStatuses,
    required Map<String, int> masteryLevels,
    required Map<String, int> previousAspectScores,
    required List<AdaptiveMaterial> materials,
    required Set<int> attemptedMaterialIds,
    // Completed attempts for this material, including [current].
    required int sameMaterialAttemptCount,
  }) {
    final sameBandTail = <AdaptivePracticeResult>[];
    final orderedPrevious = previous.toList()
      ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    for (final result in orderedPrevious) {
      if (result.studentId != current.studentId ||
          result.aspect != current.aspect ||
          result.level != current.level) {
        break;
      }
      sameBandTail.add(result);
    }

    final sameMaterialCount = sameMaterialAttemptCount;
    final previousAspectScore = previousAspectScores[current.aspect];
    final supportFromDrop =
        previousAspectScore != null &&
        previousAspectScore - current.score >= supportDropThreshold;
    final recentLowCount = sameBandTail
        .take(2)
        .where((result) => result.score < practiceThreshold)
        .length;
    final lowerAfterLowStreak =
        current.score < practiceThreshold &&
        recentLowCount == 2 &&
        current.level > 1;
    final supportFromLowStreak =
        current.score < practiceThreshold &&
        recentLowCount == 2 &&
        current.level == 1;

    final statuses = Map<String, String>.of(masteryStatuses);
    var level = current.level;
    var targetAspect = current.aspect;
    var targetLevel = current.level;
    var status = current.score < practiceThreshold
        ? 'belum_dikuasai'
        : 'sedang_berlatih';
    var needsSupport = supportFromDrop || supportFromLowStreak;
    var reason = 'Lanjutkan latihan sesuai hasil terbaru.';
    var preferSameMaterial = false;
    var markMastered = false;

    if (lowerAfterLowStreak) {
      level = current.level - 1;
      targetLevel = level;
      status = 'belum_dikuasai';
      reason = 'Tiga hasil berturut-turut masih di bawah 60; latihan diturunkan satu tingkat.';
    } else if (current.score >= masteryThreshold) {
      final lastWasHigh =
          sameBandTail.isNotEmpty &&
          sameBandTail.first.score >= masteryThreshold;
      if (lastWasHigh) {
        if (current.level < 3) {
          level = current.level + 1;
          targetLevel = level;
          status = 'sedang_berlatih';
          reason = 'Dua latihan berturut-turut mendapat nilai minimal 80; lanjut ke tingkat berikutnya.';
        } else {
          status = 'dikuasai';
          markMastered = true;
          reason = 'Aspek ini dikuasai setelah dua latihan tingkat 3 dengan nilai minimal 80.';
        }
      } else {
        status = masteryStatuses[current.aspect] == 'dikuasai'
            ? 'dikuasai'
            : 'sedang_berlatih';
        reason = 'Nilai sudah baik; coba materi lain pada tingkat ini untuk penguatan.';
      }
    } else if (current.score >= practiceThreshold) {
      status = 'sedang_berlatih';
      reason = 'Hasil ini menunjukkan penguatan pada tingkat yang sama akan membantu.';
    } else if (sameMaterialCount < maxSameMaterialAttempts) {
      reason = 'Ulangi materi ini agar lebih lancar.';
      preferSameMaterial = true;
    } else {
      reason = 'Materi ini sudah dicoba tiga kali; lanjutkan dengan materi lain yang setara.';
    }

    if (markMastered) statuses[current.aspect] = 'dikuasai';
    if (!markMastered && !lowerAfterLowStreak && status == 'dikuasai') {
      statuses[current.aspect] = 'dikuasai';
    } else if (!markMastered) {
      statuses[current.aspect] = status;
    }

    if (markMastered) {
      final next = aspects.firstWhere(
        (aspect) => statuses[aspect] != 'dikuasai',
        orElse: () => '',
      );
      if (next.isEmpty) {
        return AdaptiveDecision(
          aspect: current.aspect,
          level: 3,
          score: current.score,
          masteryStatus: 'dikuasai',
          reason: 'Semua aspek membaca sudah dikuasai.',
          needsSupport: needsSupport || supportFromDrop,
        );
      }
      targetAspect = next;
      targetLevel = masteryLevels[next] ?? 1;
      reason = 'Aspek sebelumnya sudah dikuasai; lanjut ke aspek berikutnya.';
    } else {
      targetAspect = current.aspect;
      targetLevel = level;
    }

    final decision = _decisionForTarget(
      aspect: targetAspect,
      level: targetLevel,
      score: current.score,
      status: status,
      reason: reason,
      materials: materials,
      attemptedMaterialIds: attemptedMaterialIds,
      preferredMaterialId: preferSameMaterial ? current.materialId : null,
      excludeMaterialId:
          current.score >= practiceThreshold ||
              sameMaterialCount >= maxSameMaterialAttempts
          ? current.materialId
          : null,
      needsSupport: needsSupport,
    );
    return decision;
  }

  AdaptiveDecision _decisionForTarget({
    required String aspect,
    required int level,
    required int score,
    required String status,
    required String reason,
    required List<AdaptiveMaterial> materials,
    required Set<int> attemptedMaterialIds,
    int? preferredMaterialId,
    int? excludeMaterialId,
    bool needsSupport = false,
  }) {
    final candidates =
        materials
            .where(
              (material) =>
                  material.aspect == aspect && material.level == level,
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    if (preferredMaterialId != null &&
        candidates.any((item) => item.id == preferredMaterialId)) {
      return AdaptiveDecision(
        aspect: aspect,
        level: level,
        score: score,
        masteryStatus: status,
        reason: reason,
        materialId: preferredMaterialId,
        needsSupport: needsSupport,
      );
    }
    final alternatives = candidates
        .where((item) => item.id != excludeMaterialId)
        .toList();
    final unseen = alternatives
        .where((item) => !attemptedMaterialIds.contains(item.id))
        .toList();
    final selected = unseen.isNotEmpty
        ? unseen.first
        : alternatives.isNotEmpty
        ? alternatives.first
        : null;
    if (selected == null) {
      return AdaptiveDecision(
        aspect: aspect,
        level: level,
        score: score,
        masteryStatus: status,
        reason: reason,
        needsSupport: needsSupport,
        materialMissing: true,
      );
    }
    return AdaptiveDecision(
      aspect: aspect,
      level: level,
      score: score,
      masteryStatus: status,
      reason: reason,
      materialId: selected.id,
      needsSupport: needsSupport,
    );
  }
}
