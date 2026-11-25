import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../teacher/teacher_demo_store.dart';
import '../student_demo_store.dart';

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
        return StudentOverview(
          name: student.studentName,
          className: student.className,
          active: active,
          reason: _studentReason(
            recommendation?.source,
            recommendation?.reason,
          ),
          hasActiveTest: hasActiveTest,
          hasAnyDiagnostic: student.hasAnyDiagnostic,
          completed: student.diagnosticCompleted,
          completeBaseline: student.hasCompleteDiagnosticBaseline,
          activities: activities,
          onStart: () => Navigator.pushNamed(
            context,
            '/siswa/latihan/materi',
            arguments: active?.id,
          ),
          onHistory: () => Navigator.pushNamed(context, '/siswa/evaluasi'),
          onPractice: () => Navigator.pushNamed(context, '/siswa/latihan'),
          onDiagnostic: () => Navigator.pushNamed(context, '/siswa/diagnostik'),
        );
      },
    );
  }
}

class StudentOverview extends StatelessWidget {
  const StudentOverview({
    super.key,
    required this.name,
    required this.className,
    required this.active,
    required this.reason,
    required this.hasActiveTest,
    required this.hasAnyDiagnostic,
    required this.completed,
    required this.completeBaseline,
    required this.activities,
    required this.onStart,
    required this.onHistory,
    required this.onPractice,
    required this.onDiagnostic,
  });
  final String name, className, reason;
  final DemoMaterial? active;
  final bool hasActiveTest, hasAnyDiagnostic, completed, completeBaseline;
  final List<StudentActivity> activities;
  final VoidCallback onStart, onHistory, onPractice, onDiagnostic;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
      children: [
        _Greeting(name: name, className: className),
        const SizedBox(height: 14),
        if (active != null)
          _Recommendation(material: active!, reason: reason, onStart: onStart)
        else
          _NoRecommendation(
            message: completeBaseline
                ? 'Hebat, semua aspek sudah dikuasai!'
                : hasAnyDiagnostic
                ? 'Hasil tesmu belum lengkap. Minta bantuan Gurumu ya.'
                : 'Ayo mulai dengan tes membaca bersama Gurumu.',
            buttonLabel: hasAnyDiagnostic
                ? 'Pilih latihan'
                : 'Buka tes diagnostik',
            onOpen: hasAnyDiagnostic ? onPractice : onDiagnostic,
          ),
        const SizedBox(height: 10),
        _DiagnosticRow(
          completed: completed,
          active: hasActiveTest,
          onOpen: completed ? onHistory : onDiagnostic,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: _SectionLabel('AKTIVITAS TERBARU')),
            TextButton(
              onPressed: onHistory,
              child: const Text(
                'Lihat semua',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const Text(
          'Teruskan langkahmu',
          style: TextStyle(fontSize: 18, height: 1.25, color: AppTokens.text),
        ),
        const SizedBox(height: 10),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTokens.outline),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (var i = 0; i < activities.length; i++) ...[
                _ActivityTile(activity: activities[i]),
                if (i != activities.length - 1)
                  const Divider(height: 1, indent: 58),
              ],
              if (activities.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Belum ada aktivitas membaca.'),
                ),
            ],
          ),
        ),
      ],
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
  Widget build(BuildContext context) => SizedBox(
    height: 112,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Selamat pagi,',
                style: TextStyle(fontSize: 14, color: AppTokens.text),
              ),
              Text(
                name.split(' ').first,
                style: const TextStyle(
                  fontSize: 34,
                  height: 1.12,
                  color: AppTokens.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Kelas $className · Kamu hebat hari ini',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTokens.mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const PendarIllustration(size: 78),
      ],
    ),
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
    required this.onStart,
  });
  final DemoMaterial material;
  final String reason;
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTokens.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppTokens.sunshine,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'PILIHAN UNTUKMU',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Color(0xFF806211),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${aspectLabel(material.aspect)} · Tingkat ${material.level}',
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          const SizedBox(height: 3),
          Text(
            material.title,
            style: const TextStyle(
              fontSize: 21,
              height: 1.2,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            reason,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            children: [
              _WordSticker('buku', Colors.white, AppTokens.text),
              _WordSticker('meja', AppTokens.accent, AppTokens.text),
              _WordSticker('tas', AppTokens.coralSoft, AppTokens.text),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('home-start-practice'),
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Lanjut membaca'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTokens.primary,
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordSticker extends StatelessWidget {
  const _WordSticker(this.word, this.background, this.foreground);
  final String word;
  final Color background;
  final Color foreground;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(9),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 5,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      word,
      style: TextStyle(
        fontSize: 12,
        color: foreground,
        fontWeight: FontWeight.w900,
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
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTokens.primary,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PILIHAN UNTUKMU',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: AppTokens.sunshine,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(onPressed: onOpen, child: Text(buttonLabel)),
      ],
    ),
  );
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({
    required this.completed,
    required this.active,
    required this.onOpen,
  });
  final bool completed;
  final bool active;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppTokens.outline),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTokens.sky,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 20,
                color: AppTokens.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completed
                        ? 'Tes membaca selesai'
                        : active
                        ? 'Tes membaca siap'
                        : 'Tes membaca siap',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.text,
                    ),
                  ),
                  const Text(
                    '10 soal · sekitar 8 menit',
                    style: TextStyle(fontSize: 10, color: AppTokens.mutedText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTokens.text),
          ],
        ),
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 9,
      letterSpacing: 1,
      fontWeight: FontWeight.w900,
      color: AppTokens.primary,
    ),
  );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});
  final StudentActivity activity;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTokens.mint,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 19,
            color: AppTokens.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTokens.text,
                ),
              ),
              Text(
                '${aspectLabel(activity.aspect)} · Selesai',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTokens.mutedText,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: const BoxDecoration(
            color: AppTokens.mint,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${activity.score}',
            style: const TextStyle(
              fontSize: 9,
              color: AppTokens.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}
