import 'dart:async';

import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        const StudentPageHeading(
          title: 'Hasil Evaluasi',
          subtitle: 'Lihat hasil latihan dan saran dari Gurumu.',
        ),
        if (studentState.lastPracticeScore case final score?)
          Container(
            padding: const EdgeInsets.all(AppTokens.space16),
            decoration: BoxDecoration(
              color: AppTokens.primary,
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hebat, ${studentState.studentName.split(' ').first}!',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  '$score%',
                  style: Theme.of(context).textTheme.displaySmall
                      ?.copyWith(color: AppTokens.accent),
                ),
                Text(
                  'Skor latihan ${aspectLabel(studentState.lastPracticeAspect ?? 'kata').toLowerCase()}. Terus berlatih, ya!',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppTokens.space12),
                FilledButton.icon(
                  key: const ValueKey('evaluation-open-progress'),
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    '/siswa/perkembangan',
                  ),
                  icon: const Icon(Icons.trending_up_rounded),
                  label: const Text('Lihat kemajuanku'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTokens.primaryDark,
                    minimumSize: const Size(48, AppTokens.studentButtonHeight),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppTokens.space16),
        Text('Penilaian Guru', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppTokens.space8),
        if (studentState.submittedPracticeRecording)
          const StudentPanel(
            color: StudentColors.sky,
            child: ListTile(
              leading: Icon(Icons.hourglass_top_rounded),
              title: Text('Simulasi bacaan terkirim'),
              subtitle: Text(
                'Menunggu penilaian Guru. Tidak ada audio tersimpan.',
              ),
            ),
          ),
        if (evaluations.isEmpty && !studentState.submittedPracticeRecording)
          const StudentEmptyState(
            message: 'Belum ada penilaian. Setelah Guru menilai bacaanmu, hasilnya akan muncul di sini.',
          ),
        for (final evaluation in evaluations)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space12),
            child: StudentPanel(
              color: StudentColors.mint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFCC9B27),
                      ),
                      const SizedBox(width: AppTokens.space8),
                      Expanded(
                        child: Text(
                          'Hasil membaca ${aspectLabel(evaluation.aspect).toLowerCase()}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space12),
                  _scoreLine(
                    context,
                    'Ketepatan',
                    evaluation.accuracyScore ?? 0,
                  ),
                  _scoreLine(
                    context,
                    'Kelancaran',
                    evaluation.fluencyScore ?? 0,
                  ),
                  const Divider(height: AppTokens.space24),
                  Text(
                    'Pesan Guru',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(evaluation.comment),
                  const SizedBox(height: AppTokens.space8),
                  Text(
                    'Saran latihan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(evaluation.advice),
                  if (evaluation.aiAllowed &&
                      evaluation.aiConsent &&
                      student.aiConsent &&
                      student.parentConsent) ...[
                    const SizedBox(height: AppTokens.space12),
                    Container(
                      padding: const EdgeInsets.all(AppTokens.space12),
                      decoration: BoxDecoration(
                        color: StudentColors.sunshine,
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusSmall,
                        ),
                      ),
                      child: Text(
                        'Indikasi otomatis (bukan nilai resmi): kemiripan simulasi ${evaluation.simulatedAiSimilarity}%. Nilai dan keputusan akhir tetap dari Guru.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (evaluations.isEmpty && studentState.submittedPracticeRecording)
          const Padding(
            padding: EdgeInsets.only(top: AppTokens.space12),
            child: Text(
              'Hasil Guru akan terlihat di halaman ini setelah penilaian tersedia.',
            ),
          ),
      ],
    );
  }

  Widget _scoreLine(BuildContext context, String label, int score) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTokens.space4),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Text('$score / 100', style: Theme.of(context).textTheme.titleLarge),
      ],
    ),
  );
}

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({
    super.key,
    this.profile,
    this.largerText,
    this.onToggle,
    this.onLogout,
  });
  final Map<String, dynamic>? profile;
  final bool? largerText;
  final VoidCallback? onToggle, onLogout;

  @override
  Widget build(BuildContext context) {
    final store = StudentDemoStore.instance;
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        const StudentPageHeading(
          title: 'Profil Saya',
          subtitle: 'Ini informasi akun belajarmu.',
        ),
        StudentPanel(
          color: StudentColors.sunshine,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.face_rounded,
                  size: 54,
                  color: AppTokens.primary,
                ),
              ),
              const SizedBox(height: AppTokens.space12),
              Text(
                profile?['nama'] ?? store.student.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'Kelas ${profile?['kelas'] ?? store.className}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Divider(height: 26),
              _ProfileLine(
                label: 'Nama pengguna',
                value: profile == null
                    ? store.student.username
                    : profile!['username'] ?? '–',
              ),
              _ProfileLine(
                label: 'Wali kelas',
                value: profile == null
                    ? TeacherDemoStore.instance.teacherName
                    : profile!['wali_kelas'] ?? '–',
              ),
              _ProfileLine(
                label: 'Izin rekaman suara',
                value:
                    (profile == null
                        ? store.student.parentConsent
                        : [true, 1].contains(profile!['parent_consent']))
                    ? 'Diizinkan'
                    : 'Belum diizinkan',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        StudentPanel(
          child: SwitchListTile(
            key: const ValueKey('student-larger-text'),
            contentPadding: EdgeInsets.zero,
            value: largerText ?? store.largerText,
            onChanged: (_) => (onToggle ?? store.toggleLargerText)(),
            title: const Text('Huruf lebih besar'),
            subtitle: const Text('Buat tulisan lebih mudah dibaca.'),
            secondary: const Icon(Icons.text_fields_rounded),
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        const StudentPanel(
          color: StudentColors.sky,
          child: Text('Terus semangat membaca setiap hari! ⭐'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey('student-logout'),
          onPressed:
              onLogout ??
              () {
                AppSession.end();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/welcome',
                  (_) => false,
                );
              },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Keluar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTokens.coralDark,
            side: const BorderSide(color: AppTokens.coralDark),
          ),
        ),
      ],
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTokens.mutedText),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              color: AppTokens.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
