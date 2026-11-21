import 'package:flutter/material.dart';

import '../../app/navigation_plan.dart';
import '../theme/app_tokens.dart';
import 'baca_button.dart';
import 'baca_card.dart';

class RouteMessagePage extends StatelessWidget {
  const RouteMessagePage({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.screen,
    super.key,
  });

  factory RouteMessagePage.forScreen(PlannedScreen screen) {
    return RouteMessagePage._(
      screen: screen,
      title: screen.title,
      message: _screenDescription(screen),
      actionLabel: 'Kembali',
      onAction: (context) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            screen.role == AppRole.teacher ? '/guru' : '/siswa',
            (_) => false,
          );
        }
      },
    );
  }

  const RouteMessagePage._({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.screen,
  });

  final String title;
  final String message;
  final String actionLabel;
  final ValueChanged<BuildContext> onAction;
  final PlannedScreen? screen;

  @override
  Widget build(BuildContext context) {
    final currentScreen = screen;
    final children = currentScreen == null
        ? const <PlannedScreen>[]
        : _relatedScreens(currentScreen);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => onAction(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(AppTokens.space24),
              children: [
                Text(
                  screen?.id ?? 'Pratinjau',
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: AppTokens.primary),
                ),
                const SizedBox(height: AppTokens.space16),
                BacaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        screen?.role == AppRole.student
                            ? Icons.auto_stories_rounded
                            : Icons.dashboard_customize_outlined,
                        size: 40,
                        color: AppTokens.primary,
                      ),
                      const SizedBox(height: AppTokens.space16),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppTokens.space12),
                      Text(
                        'Bagian ini disiapkan sebagai tujuan navigasi. Isi fitur akan dibuat pada tahap berikutnya.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (children.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.space24),
                  Text(
                    'Lanjut ke',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTokens.space12),
                  for (final child in children) ...[
                    BacaButton(
                      label: child.title,
                      icon: _screenIcon(child.id),
                      onPressed: () => Navigator.pushNamed(context, child.path),
                    ),
                    const SizedBox(height: AppTokens.space12),
                  ],
                ],
                if (screen == null) ...[
                  const SizedBox(height: AppTokens.space24),
                  BacaButton(
                    label: actionLabel,
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => onAction(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _screenDescription(PlannedScreen screen) {
  const descriptions = <String, String>{
    'G4': 'Form siswa dan pengaturan kelas serta persetujuan wali.',
    'G7': 'Form untuk menyiapkan materi membaca.',
    'G8': 'Ruang pratinjau generator draf materi untuk Guru.',
    'G10': 'Ruang pratinjau generator draf soal untuk Guru.',
    'G12': 'Ringkasan hasil diagnostik siswa.',
    'G14': 'Ringkasan kegiatan dan perkembangan seorang siswa.',
    'S3': 'Tes diagnostik akan menampilkan satu soal pada setiap langkah.',
    'S5': 'Materi membaca akan ditampilkan dengan teks yang mudah dibaca.',
    'S6': 'Latihan akan menampilkan satu soal pada setiap langkah.',
    'S7': 'Ruang untuk membaca teks dan merekam suara dalam pratinjau.',
  };
  return descriptions[screen.id] ??
      'Tujuan halaman ${screen.id} dalam alur BacaTepat.';
}

List<PlannedScreen> _relatedScreens(PlannedScreen screen) {
  final results = <PlannedScreen>[
    ...NavigationPlan.teacher.where((item) => item.parentId == screen.id),
    ...NavigationPlan.student.where((item) => item.parentId == screen.id),
  ];
  if (screen.id == 'G12') {
    results.add(NavigationPlan.teacher.firstWhere((item) => item.id == 'G14'));
  }
  return results;
}

IconData _screenIcon(String id) => switch (id) {
  'G4' => Icons.person_add_alt_1_rounded,
  'G7' || 'G8' => Icons.menu_book_rounded,
  'G10' => Icons.quiz_outlined,
  'G12' => Icons.assessment_outlined,
  'G14' => Icons.person_search_rounded,
  'S3' => Icons.fact_check_outlined,
  'S5' => Icons.auto_stories_rounded,
  'S6' => Icons.edit_note_rounded,
  'S7' => Icons.mic_none_rounded,
  _ => Icons.arrow_forward_rounded,
};
