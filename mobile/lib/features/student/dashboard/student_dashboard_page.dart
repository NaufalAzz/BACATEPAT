import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../teacher/teacher_demo_store.dart';
import '../student_demo_store.dart';
import '../student_widgets.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final student = StudentDemoStore.instance;
    final teacherData = TeacherDemoStore.instance;
    return AnimatedBuilder(
      animation: student,
      builder: (context, _) {
        final id = student.recommendedMaterialId;
        final material = id == null ? null : teacherData.materialById(id);
        final active = material?.status == 'aktif' ? material : null;
        final recommendation = student.activeRecommendation;
        final hasActiveTest = teacherData.diagnostics.any(
          (item) =>
              item.classId == student.student.classId && item.status == 'aktif',
        );
        final activities = student.activities.take(2).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space16,
            AppTokens.space16,
            AppTokens.space16,
            AppTokens.space24,
          ),
          children: [
            _Greeting(name: student.studentName, className: student.className),
            const SizedBox(height: AppTokens.space20),
            if (active != null)
              _Recommendation(
                material: active,
                reason: _studentReason(
                  recommendation?.source,
                  recommendation?.reason,
                ),
                progress: student.practiceScores[active.aspect] ?? 0,
                onStart: () => Navigator.pushNamed(
                  context,
                  '/siswa/latihan/materi',
                  arguments: active.id,
                ),
              )
            else
              _NoRecommendation(
                message: student.hasCompleteDiagnosticBaseline
                    ? 'Hebat, semua aspek sudah dikuasai!'
                    : student.hasAnyDiagnostic
                    ? 'Hasil tesmu belum lengkap. Minta bantuan Gurumu ya.'
                    : 'Ayo mulai dengan tes membaca bersama Gurumu.',
                buttonLabel: student.hasAnyDiagnostic
                    ? 'Pilih latihan'
                    : 'Buka tes diagnostik',
                onOpen: () => Navigator.pushNamed(
                  context,
                  student.hasAnyDiagnostic
                      ? '/siswa/latihan'
                      : '/siswa/diagnostik',
                ),
              ),
            const SizedBox(height: AppTokens.space16),
            _DiagnosticCard(
              completed: student.diagnosticCompleted,
              active: hasActiveTest,
              onOpen: () => Navigator.pushNamed(
                context,
                student.diagnosticCompleted
                    ? '/siswa/evaluasi'
                    : '/siswa/diagnostik',
              ),
            ),
            const SizedBox(height: AppTokens.space24),
            _ActivitySection(activities: activities),
          ],
        );
      },
    );
  }
}

String _studentReason(String? source, String? reason) {
  if (source == 'guru') return 'Pilihan khusus dari Gurumu.';
  if (reason == null) return 'Latihan ini dipilih dari hasil belajarmu.';
  if (reason.contains('dua latihan berturut-turut')) {
    return 'Hebat! Saatnya mencoba tingkat berikutnya.';
  }
  if (reason.contains('Nilai sudah baik')) {
    return 'Kamu sudah bagus. Coba bacaan yang berbeda.';
  }
  if (reason.contains('penguatan')) {
    return 'Latihan ini membantu menguatkan bacaanmu.';
  }
  if (reason.contains('Ulangi materi')) return 'Kita coba lagi pelan-pelan ya.';
  if (reason.contains('diagnostik')) {
    return 'Kita mulai dari bagian yang masih perlu dilatih.';
  }
  return 'Kita lanjut berlatih membaca bersama.';
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.className});
  final String name;
  final String className;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat pagi,',
              style: TextStyle(fontSize: 15, color: AppTokens.text),
            ),
            Text(
              '${name.split(' ').first}!',
              style: const TextStyle(
                fontSize: 30,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: AppTokens.text,
              ),
            ),
            const SizedBox(height: AppTokens.space4),
            Text(
              'Kelas $className · Kamu hebat hari ini',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTokens.mutedText,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: AppTokens.space12),
      Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: Color(0xFFC3E3D7),
          shape: BoxShape.circle,
        ),
        child: const PendarIllustration(size: 72),
      ),
    ],
  );
}

class PendarIllustration extends StatelessWidget {
  const PendarIllustration({this.size = 78, super.key});
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/illustrations/student-avatar.png',
    width: size,
    height: size,
    semanticLabel: 'Ilustrasi siswa',
  );
}

class _Recommendation extends StatelessWidget {
  const _Recommendation({
    required this.material,
    required this.reason,
    required this.progress,
    required this.onStart,
  });
  final DemoMaterial material;
  final String reason;
  final int progress;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTokens.primary,
      borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
    ),
    padding: const EdgeInsets.all(AppTokens.space20),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTokens.sunshine,
                borderRadius: BorderRadius.circular(AppTokens.radiusRound),
              ),
              child: const Text(
                'PILIHAN UNTUKMU',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w900,
                  color: AppTokens.warning,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space16),
            Text(
              '${aspectLabel(material.aspect)} · Tingkat ${material.level}',
              style: const TextStyle(fontSize: 11.5, color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(right: 90),
              child: Text(
                material.title,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            Padding(
              padding: const EdgeInsets.only(right: 90),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space12),
                  Text(
                    '$progress%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space6),
            Padding(
              padding: const EdgeInsets.only(right: 90),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusRound),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 4,
                  backgroundColor: Colors.white24,
                  color: AppTokens.accent,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space16),
            FilledButton.icon(
              key: const ValueKey('home-start-practice'),
              onPressed: onStart,
              icon: const Icon(
                Icons.play_arrow_rounded,
                size: 18,
                color: AppTokens.primary,
              ),
              label: const Text(
                'Lanjut membaca',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppTokens.primary,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: -8,
          right: -4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _WordSticker(
                word: 'buku',
                background: Colors.white,
                foreground: AppTokens.text,
                angle: 0.1,
              ),
              const SizedBox(height: AppTokens.space6),
              _WordSticker(
                word: 'meja',
                background: AppTokens.accent,
                foreground: AppTokens.text,
                angle: -0.08,
              ),
              const SizedBox(height: AppTokens.space6),
              _WordSticker(
                word: 'tas',
                background: const Color(0xFFF6C6BC),
                foreground: AppTokens.coralDark,
                angle: 0.08,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WordSticker extends StatelessWidget {
  const _WordSticker({
    required this.word,
    required this.background,
    required this.foreground,
    required this.angle,
  });
  final String word;
  final Color background;
  final Color foreground;
  final double angle;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        word,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    ),
  );
}

class _NoRecommendation extends StatelessWidget {
  const _NoRecommendation({
    required this.onOpen,
    required this.message,
    required this.buttonLabel,
  });
  final VoidCallback onOpen;
  final String message;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppTokens.space20),
    decoration: BoxDecoration(
      color: AppTokens.primary,
      borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PILIHAN UNTUKMU',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 0.7,
            fontWeight: FontWeight.w900,
            color: AppTokens.accent,
          ),
        ),
        const SizedBox(height: AppTokens.space12),
        Text(
          message,
          style: const TextStyle(
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        FilledButton.icon(
          onPressed: onOpen,
          icon: const Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: AppTokens.primary,
          ),
          label: Text(
            buttonLabel,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppTokens.primary,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({
    required this.completed,
    required this.active,
    required this.onOpen,
  });
  final bool completed;
  final bool active;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTokens.surface,
    borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
          border: Border.all(color: AppTokens.outline),
        ),
        padding: const EdgeInsets.all(AppTokens.space12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTokens.sky,
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              ),
              child: Icon(
                completed
                    ? Icons.assignment_turned_in_outlined
                    : Icons.assignment_outlined,
                size: 20,
                color: AppTokens.secondary,
              ),
            ),
            const SizedBox(width: AppTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completed
                        ? 'Tes membaca selesai'
                        : active
                        ? 'Tes membaca siap'
                        : 'Belum ada tes diagnostik',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    completed
                        ? 'Lihat hasil dan rekomendasi'
                        : '10 soal · sekitar 8 menit',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTokens.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTokens.mutedText,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.activities});
  final List<StudentActivity> activities;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const StudentSectionLabel('Aktivitas terbaru'),
      const SizedBox(height: 2),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Teruskan langkahmu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTokens.text,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/siswa/evaluasi'),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'Lihat semua',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppTokens.secondary,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppTokens.space8),
      StudentPanel(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            if (activities.isEmpty)
              StudentEmptyState(
                message:
                    'Belum ada aktivitas membaca.\nMulai latihan pertama mu!',
                icon: Icons.auto_stories_outlined,
                action: StudentAction(
                  label: 'Mulai latihan',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/siswa/latihan'),
                  expanded: false,
                ),
              )
            else
              for (var i = 0; i < activities.length; i++) ...[
                _ActivityTile(activity: activities[i]),
                if (i != activities.length - 1)
                  const Divider(
                    height: 1,
                    indent: AppTokens.space14,
                    endIndent: AppTokens.space14,
                    color: AppTokens.outline,
                  ),
              ],
          ],
        ),
      ),
    ],
  );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});
  final StudentActivity activity;

  @override
  Widget build(BuildContext context) {
    final hasScore = activity.score > 0;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hasScore ? AppTokens.mint : AppTokens.sunshine,
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: Icon(
              hasScore
                  ? Icons.check_rounded
                  : Icons.menu_book_outlined,
              size: 19,
              color: hasScore ? AppTokens.primary : AppTokens.warning,
            ),
          ),
          const SizedBox(width: AppTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${aspectLabel(activity.aspect)} · ${hasScore ? 'Selesai' : 'Belum dinilai'}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTokens.mutedText,
                  ),
                ),
              ],
            ),
          ),
          if (hasScore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTokens.mint,
                borderRadius: BorderRadius.circular(AppTokens.radiusRound),
              ),
              child: Text(
                '${activity.score}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppTokens.primary,
                ),
              ),
            )
          else
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTokens.mutedText,
            ),
        ],
      ),
    );
  }
}
