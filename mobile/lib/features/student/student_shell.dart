import 'package:flutter/material.dart';

import '../../app/navigation_plan.dart';
import '../../core/components/baca_tepat_mark.dart';
import '../../core/theme/app_tokens.dart';
import 'student_demo_store.dart';
import 'student_feature_page.dart';

class StudentShell extends StatelessWidget {
  const StudentShell({
    required this.screen,
    this.arguments,
    this.body,
    this.largerText,
    this.name,
    this.onSelect,
    super.key,
  });

  final PlannedScreen screen;
  final Object? arguments;
  final Widget? body;
  final bool? largerText;
  final String? name;
  final ValueChanged<String>? onSelect;

  static const _mainIds = ['S2', 'S4', 'S9', 'S10'];

  @override
  Widget build(BuildContext context) {
    final mainScreens = _mainIds
        .map((id) => NavigationPlan.student.firstWhere((item) => item.id == id))
        .toList();
    final selectedIndex = _selectedDestination(screen.id);

    return AnimatedBuilder(
      animation: StudentDemoStore.instance,
      builder: (context, _) {
        final systemTextScaler = MediaQuery.textScalerOf(context);
        final textScaler = (largerText ?? StudentDemoStore.instance.largerText)
            ? _StudentPreferenceTextScaler(systemTextScaler, 1.12)
            : systemTextScaler;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: Scaffold(
            appBar: AppBar(
              leading: screen.placement == NavigationPlacement.detail
                  ? IconButton(
                      tooltip: 'Kembali',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  : null,
              title: screen.placement == NavigationPlacement.primary
                  ? Row(
                      children: [
                        const BacaTepatMark(size: 30),
                        const SizedBox(width: AppTokens.space8),
                        Flexible(
                          child: Text(
                            'BacaTepat',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    )
                  : Text(_studentToolbarTitle(screen.id)),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppTokens.sunshine,
                    child: Text(
                      (name ?? StudentDemoStore.instance.studentName)
                              .characters
                              .firstOrNull
                              ?.toUpperCase() ??
                          '?',
                      style: const TextStyle(
                        color: AppTokens.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body:
                body ??
                StudentFeatureBody(screen: screen, arguments: arguments),
            bottomNavigationBar: Material(
              key: const ValueKey('student-navigation'),
              color: Colors.white,
              elevation: 8,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 62,
                  child: Row(
                    children: [
                      for (var index = 0; index < mainScreens.length; index++)
                        Expanded(
                          child: InkWell(
                            key: ValueKey(
                              'student-tab-${mainScreens[index].id}',
                            ),
                            onTap: () {
                              if (onSelect != null) {
                                onSelect!(mainScreens[index].id);
                              } else {
                                Navigator.pushReplacementNamed(
                                  context,
                                  mainScreens[index].path,
                                );
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _studentIcon(
                                    mainScreens[index].id,
                                    selected: index == selectedIndex,
                                  ),
                                  size: 21,
                                  color: index == selectedIndex
                                      ? AppTokens.primary
                                      : const Color(0xFF89918E),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _studentTabLabel(mainScreens[index].id),
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    height: 1.2,
                                    fontWeight: index == selectedIndex
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: index == selectedIndex
                                        ? AppTokens.primary
                                        : const Color(0xFF78827F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _selectedDestination(String id) => switch (id) {
    'S4' || 'S5' || 'S6' || 'S7' => 1,
    'S8' || 'S9' => 2,
    'S10' => 3,
    _ => 0,
  };
}

/// Applies the in-app preference on top of the operating system's scaler.
class _StudentPreferenceTextScaler extends TextScaler {
  const _StudentPreferenceTextScaler(this.systemScaler, this.multiplier);

  final TextScaler systemScaler;
  final double multiplier;

  @override
  double scale(double fontSize) => systemScaler.scale(fontSize) * multiplier;

  @override
  double get textScaleFactor => systemScaler.scale(14) / 14 * multiplier;

  @override
  bool operator ==(Object other) =>
      other is _StudentPreferenceTextScaler &&
      other.systemScaler == systemScaler &&
      other.multiplier == multiplier;

  @override
  int get hashCode => Object.hash(systemScaler, multiplier);
}

IconData _studentIcon(String id, {bool selected = false}) => switch (id) {
  'S2' => selected ? Icons.home_rounded : Icons.home_outlined,
  'S4' => selected ? Icons.auto_stories_rounded : Icons.menu_book_outlined,
  'S9' => selected ? Icons.show_chart_rounded : Icons.show_chart_outlined,
  'S10' => selected ? Icons.face_rounded : Icons.face_outlined,
  _ => Icons.circle_outlined,
};

String _studentTabLabel(String id) => switch (id) {
  'S2' => 'Beranda',
  'S4' => 'Latihan',
  'S9' => 'Kemajuan',
  'S10' => 'Profil',
  _ => 'Lainnya',
};

String _studentToolbarTitle(String id) => switch (id) {
  'S3' => 'Tes diagnostik',
  'S5' => 'Materi',
  'S6' => 'Latihan',
  'S7' => 'Rekaman',
  _ => 'BacaTepat',
};
