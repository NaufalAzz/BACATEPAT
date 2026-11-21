import 'package:flutter/material.dart';

import '../../app/navigation_plan.dart';
import '../theme/app_tokens.dart';
import 'baca_button.dart';
import 'baca_card.dart';

class PlannedPageContent extends StatelessWidget {
  const PlannedPageContent({required this.screen, super.key});

  final PlannedScreen screen;

  @override
  Widget build(BuildContext context) {
    final actions = _actionsFor(screen);
    final isStudent = screen.role == AppRole.student;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.space24),
          children: [
            Text(
              screen.id,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: AppTokens.primary),
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              isStudent ? _studentGreeting(screen) : 'Ringkasan pratinjau Guru',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTokens.space16),
            BacaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _summary(screen),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppTokens.space12),
                  Text(
                    'Belum ada data pada pratinjau ini. Halaman ini adalah kerangka navigasi.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppTokens.space24),
              Text(
                isStudent ? 'Mau melakukan apa?' : 'Akses cepat',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTokens.space12),
              for (final target in actions) ...[
                BacaButton(
                  label: target.title,
                  icon: _iconFor(target.id),
                  onPressed: () => Navigator.pushNamed(context, target.path),
                ),
                const SizedBox(height: AppTokens.space12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

String _studentGreeting(PlannedScreen screen) => switch (screen.id) {
  'S2' => 'Halo, teman membaca! 👋',
  'S4' => 'Pilih latihan membaca',
  'S8' => 'Hasil dari Guru',
  'S9' => 'Lihat perkembanganmu',
  'S10' => 'Profil saya',
  _ => screen.title,
};

String _summary(PlannedScreen screen) => switch (screen.id) {
  'G2' =>
    'Ringkasan kelas, diagnostik, rekaman, dan siswa yang perlu didampingi.',
  'G3' => 'Cari siswa, buka detail, atau siapkan data siswa.',
  'G5' => 'Kelola kelas dan lihat jumlah siswa di setiap kelas.',
  'G6' => 'Jelajahi materi membaca yang tersedia.',
  'G9' => 'Jelajahi soal dan status peninjauannya.',
  'G11' => 'Siapkan tes diagnostik untuk kelas.',
  'G13' => 'Lihat antrean rekaman untuk ditinjau Guru.',
  'G15' => 'Pantau grafik perkembangan membaca.',
  'G16' => 'Pilih laporan siswa atau kelas untuk pratinjau.',
  'G17' => 'Informasi profil Guru.',
  'S2' => 'Latihan dan tes yang disiapkan Guru akan muncul di sini.',
  'S4' => 'Latihan membaca akan dikelompokkan sesuai kebutuhanmu.',
  'S8' => 'Komentar dan penilaian Guru akan tampil di sini.',
  'S9' => 'Perjalanan belajarmu akan ditampilkan dengan sederhana.',
  'S10' => 'Lihat informasi nama dan kelas.',
  _ => 'Pratinjau halaman ${screen.title}.',
};

List<PlannedScreen> _actionsFor(PlannedScreen screen) {
  if (screen.id == 'S2') {
    return [
      NavigationPlan.student.firstWhere((item) => item.id == 'S3'),
      NavigationPlan.student.firstWhere((item) => item.id == 'S4'),
      NavigationPlan.student.firstWhere((item) => item.id == 'S8'),
    ];
  }
  final children = [
    ...NavigationPlan.teacher.where((item) => item.parentId == screen.id),
    ...NavigationPlan.student.where((item) => item.parentId == screen.id),
  ];
  if (screen.id == 'G12') {
    children.add(NavigationPlan.teacher.firstWhere((item) => item.id == 'G14'));
  }
  return children;
}

IconData _iconFor(String id) => switch (id) {
  'G4' => Icons.person_add_alt_1_rounded,
  'G7' || 'G8' => Icons.menu_book_rounded,
  'G10' => Icons.quiz_outlined,
  'G12' => Icons.assessment_outlined,
  'G14' => Icons.person_search_rounded,
  'S3' => Icons.fact_check_outlined,
  'S4' => Icons.auto_stories_rounded,
  'S5' => Icons.menu_book_rounded,
  'S6' => Icons.edit_note_rounded,
  'S7' => Icons.mic_none_rounded,
  'S8' => Icons.chat_bubble_outline_rounded,
  _ => Icons.arrow_forward_rounded,
};
