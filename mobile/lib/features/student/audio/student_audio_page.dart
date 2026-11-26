import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/learning_session.dart';
import '../../../core/api/bacatepat_api.dart';

import '../../../app/app_session.dart';
import '../../../core/theme/app_tokens.dart';
import '../../teacher/teacher_demo_store.dart';
import '../student_demo_store.dart';
import '../student_widgets.dart';

class StudentRecordingPage extends StatefulWidget {
  const StudentRecordingPage({this.targetText, super.key});
  final String? targetText;

  @override
  State<StudentRecordingPage> createState() => _StudentRecordingPageState();
}

class _StudentRecordingPageState extends State<StudentRecordingPage> {
  Timer? _timer;
  int _seconds = 0;
  bool _recording = false;
  bool _readyToPlay = false;
  bool _playing = false;
  bool _sent = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = StudentDemoStore.instance.student;
    final target = widget.targetText ?? 'Ibu baca buku.';
    const blush = Color(0xFFFFF7F4);
    return ColoredBox(
      color: blush,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD5E0DD)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                _ConsentState(label: 'Siap', selected: student.parentConsent),
                _ConsentState(label: 'Izin ditolak', selected: false),
                _ConsentState(
                  label: 'Belum disetujui',
                  selected: !student.parentConsent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                student.parentConsent
                    ? Icons.lock_outline
                    : Icons.lock_open_outlined,
                size: 15,
                color: student.parentConsent
                    ? AppTokens.primary
                    : AppTokens.accent,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  student.parentConsent
                      ? 'Rekaman diizinkan oleh wali'
                      : 'Persetujuan wali belum tersedia',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: student.parentConsent
                        ? AppTokens.primary
                        : AppTokens.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF0D8D2)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Text(
                  'Baca kalimat ini',
                  style: TextStyle(fontSize: 13, color: AppTokens.mutedText),
                ),
                const SizedBox(height: 5),
                Text(
                  target,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    color: AppTokens.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                Material(
                  color: const Color(0xFFE8F3F9),
                  borderRadius: BorderRadius.circular(25),
                  child: InkWell(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Contoh suara tidak tersedia pada simulasi ini.',
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(25),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xFF3878A4),
                            size: 19,
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Dengarkan contoh',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF3878A4),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 38),
          Center(
            child: Column(
              children: [
                Text(
                  _recording
                      ? 'Sedang merekam…'
                      : _readyToPlay
                      ? 'Rekaman siap'
                      : 'Siap merekam?',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTokens.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'maks. 60 detik${_seconds > 0 ? ' · $_seconds detik' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTokens.mutedText,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 88,
                  height: 88,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTokens.coral.withValues(alpha: .13),
                  ),
                  child: FilledButton(
                    key: const ValueKey('record-start'),
                    onPressed: !student.parentConsent
                        ? null
                        : _recording
                        ? _stop
                        : _readyToPlay
                        ? _reset
                        : _start,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.coral,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: Icon(
                      _recording
                          ? Icons.stop_rounded
                          : _readyToPlay
                          ? Icons.refresh_rounded
                          : Icons.mic_none_rounded,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('record-submit'),
              onPressed: student.parentConsent && _readyToPlay ? _send : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF93BDB5),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _sent ? 'Rekaman terkirim' : 'Kirim rekaman',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (_readyToPlay && !_sent) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              key: const ValueKey('record-play'),
              onPressed: _togglePlayback,
              icon: Icon(
                _playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(
                _playing ? 'Hentikan pratinjau' : 'Putar pratinjau simulasi',
              ),
            ),
          ],
          if (_sent)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Simulasi rekaman terkirim kepada Guru.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTokens.primary),
              ),
            ),
          if (!student.parentConsent)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Minta Guru mengaktifkan persetujuan wali terlebih dahulu.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTokens.mutedText),
              ),
            ),
          if (!student.aiConsent)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Analisis AI tidak tersedia. Guru dapat memberi penilaian manual.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTokens.mutedText),
              ),
            ),
        ],
      ),
    );
  }

  void _start() {
    setState(() {
      _recording = true;
      _readyToPlay = false;
      _seconds = 0;
      _sent = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_seconds >= 59) {
        _stop();
        return;
      }
      setState(() => _seconds++);
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _recording = false;
      _readyToPlay = _seconds > 0;
      _playing = false;
    });
  }

  void _togglePlayback() {
    if (_playing) {
      setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _playing = false);
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _recording = false;
      _readyToPlay = false;
      _playing = false;
      _sent = false;
    });
  }

  void _send() {
    StudentDemoStore.instance.submitRecordingPreview();
    setState(() => _sent = true);
  }
}

class _ConsentState extends StatelessWidget {
  const _ConsentState({required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF183B4D) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppTokens.mutedText,
        ),
      ),
    ),
  );
}

class StudentEvaluationPage extends StatelessWidget {
  const StudentEvaluationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final studentState = StudentDemoStore.instance;
    final student = studentState.student;
    final evaluations = store.recordings
        .where(
          (item) =>
              item.studentId == StudentDemoStore.instance.currentStudentId &&
              item.status == 'dievaluasi',
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        AppTokens.space16,
        AppTokens.space16,
        AppTokens.space24,
      ),
      children: [
        const StudentSectionLabel('Penilaian guru'),
        const SizedBox(height: AppTokens.space4),
        const Text(
          'Lihat hasil bacaanmu',
          style: TextStyle(
            fontSize: 22,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: AppTokens.text,
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        const Text(
          'Pesan dari guru untuk membantumu berkembang.',
          style: TextStyle(fontSize: 12.5, color: AppTokens.mutedText),
        ),
        const SizedBox(height: AppTokens.space16),
        if (evaluations.isEmpty && !studentState.submittedPracticeRecording)
          const StudentEmptyState(
            message:
                'Belum ada penilaian. Setelah Guru menilai bacaanmu, hasilnya akan muncul di sini.',
          ),
        for (final evaluation in evaluations)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space12),
            child: _EvaluationCard(evaluation: evaluation, student: student),
          ),
        if (studentState.submittedPracticeRecording)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space12),
            child: Container(
              padding: const EdgeInsets.all(AppTokens.space12),
              decoration: BoxDecoration(
                color: AppTokens.sunshine,
                borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                border: Border.all(color: const Color(0xFFEBD78D)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    size: 18,
                    color: AppTokens.warning,
                  ),
                  SizedBox(width: AppTokens.space10),
                  Expanded(
                    child: Text(
                      'Simulasi bacaan terkirim. Menunggu penilaian Guru. Tidak ada audio tersimpan.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppTokens.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (studentState.lastPracticeScore case final score?)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space12),
            child: Container(
              padding: const EdgeInsets.all(AppTokens.space14),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
                border: Border.all(color: AppTokens.outline),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTokens.mint,
                      borderRadius: BorderRadius.circular(
                        AppTokens.radiusSmall,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_stories_outlined,
                      size: 19,
                      color: AppTokens.primary,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Latihan terakhirmu',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.text,
                          ),
                        ),
                        Text(
                          'Skor latihan ${aspectLabel(studentState.lastPracticeAspect ?? 'kata').toLowerCase()}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTokens.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.text,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppTokens.mutedText,
                  ),
                ],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(AppTokens.space12),
          decoration: BoxDecoration(
            color: AppTokens.sunshine,
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            border: Border.all(color: const Color(0xFFEBD78D)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 18,
                color: AppTokens.warning,
              ),
              SizedBox(width: AppTokens.space10),
              Expanded(
                child: Text(
                  'Nilai ini berasal dari Guru dan latihan objektif, bukan keputusan AI.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppTokens.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: TextButton(
            key: const ValueKey('evaluation-open-progress'),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/siswa/perkembangan'),
            child: const Text(
              'Lihat kemajuanku',
              style: TextStyle(
                fontSize: 12,
                color: AppTokens.secondary,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({required this.evaluation, required this.student});

  final DemoRecording evaluation;
  final DemoStudent student;

  @override
  Widget build(BuildContext context) {
    final score = ((evaluation.accuracyScore ?? 0) +
            (evaluation.fluencyScore ?? 0)) /
        2;
    final mastered = score >= 80;
    final title = 'Hasil membaca ${aspectLabel(evaluation.aspect).toLowerCase()}';
    return Material(
      color: AppTokens.surface,
      borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.space14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
            border: Border.all(color: AppTokens.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 40,
                decoration: BoxDecoration(
                  color: mastered ? AppTokens.mint : AppTokens.sunshine,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  size: 19,
                  color: mastered ? AppTokens.primary : AppTokens.warning,
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                      'Dinilai ${TeacherDemoStore.instance.teacherName}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTokens.mutedText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: mastered
                            ? AppTokens.mint
                            : AppTokens.sunshine,
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusRound,
                        ),
                      ),
                      child: Text(
                        mastered ? 'Dikuasai' : 'Terus berlatih',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: mastered
                              ? AppTokens.primary
                              : AppTokens.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${score.round()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.text,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTokens.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusXLarge),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hasil membaca ${aspectLabel(evaluation.aspect).toLowerCase()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.text,
                ),
              ),
              const SizedBox(height: AppTokens.space16),
              _scoreLine(
                sheetContext,
                'Ketepatan',
                evaluation.accuracyScore ?? 0,
              ),
              _scoreLine(
                sheetContext,
                'Kelancaran',
                evaluation.fluencyScore ?? 0,
              ),
              const Divider(height: AppTokens.space24),
              const StudentSectionLabel('Pesan guru'),
              const SizedBox(height: 4),
              Text(
                evaluation.comment,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTokens.text,
                ),
              ),
              const SizedBox(height: AppTokens.space12),
              const StudentSectionLabel('Saran latihan'),
              const SizedBox(height: 4),
              Text(
                evaluation.advice,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTokens.text,
                ),
              ),
              if (evaluation.aiAllowed &&
                  evaluation.aiConsent &&
                  student.aiConsent &&
                  student.parentConsent) ...[
                const SizedBox(height: AppTokens.space12),
                Text(
                  'Indikasi otomatis (bukan nilai resmi): kemiripan simulasi ${evaluation.simulatedAiSimilarity}%. Nilai dan keputusan akhir tetap dari Guru.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: AppTokens.mutedText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreLine(BuildContext context, String label, int score) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTokens.space4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTokens.text),
          ),
        ),
        Text(
          '$score / 100',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTokens.text,
          ),
        ),
      ],
    ),
  );
}

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StudentDemoStore.instance;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        AppTokens.space24,
        AppTokens.space16,
        AppTokens.space24,
      ),
      children: [
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFFFBE7B5),
            child: Text(
              store.student.name.characters.first.toUpperCase(),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTokens.text,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space12),
        Text(
          store.student.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTokens.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Kelas ${store.className} · SD Pelita Bangsa',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppTokens.mutedText),
        ),
        const SizedBox(height: AppTokens.space20),
        StudentPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ProfileLine(
                icon: Icons.person_outline_rounded,
                tint: AppTokens.mint,
                label: 'Nama pengguna',
                value: store.student.username,
              ),
              const Divider(height: 1, color: AppTokens.outline),
              _ProfileLine(
                icon: Icons.school_outlined,
                tint: AppTokens.sky,
                label: 'Guru kelas',
                value: TeacherDemoStore.instance.teacherName,
              ),
              const Divider(height: 1, color: AppTokens.outline),
              _ProfileLine(
                icon: Icons.lock_outline_rounded,
                tint: AppTokens.sunshine,
                label: 'Rekaman suara',
                value: store.student.parentConsent
                    ? 'Diizinkan wali'
                    : 'Belum diizinkan',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space12),
        StudentPanel(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            key: const ValueKey('student-larger-text'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space14,
              vertical: 2,
            ),
            value: store.largerText,
            onChanged: (_) => store.toggleLargerText(),
            title: const Text(
              'Huruf lebih besar',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Buat tulisan lebih mudah dibaca.',
              style: TextStyle(fontSize: 11.5, color: AppTokens.mutedText),
            ),
            secondary: const Icon(
              Icons.text_fields_rounded,
              size: 20,
              color: AppTokens.primary,
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        OutlinedButton.icon(
          key: const ValueKey('student-logout'),
          onPressed: () async {
            if (LearningSession.enabled) {
              try {
                await LearningSession.logout();
              } on ApiError catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
                return;
              }
              if (!context.mounted) return;
            } else {
              AppSession.end();
            }

            Navigator.pushNamedAndRemoveUntil(
              context,
              '/welcome',
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Keluar'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppTokens.studentButtonHeight),
            foregroundColor: AppTokens.primary,
            side: const BorderSide(color: AppTokens.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppTokens.space14),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
          child: Icon(icon, size: 18, color: AppTokens.text),
        ),
        const SizedBox(width: AppTokens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTokens.mutedText,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.text,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
