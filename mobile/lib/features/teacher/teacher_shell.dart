import 'package:flutter/material.dart';

import '../../app/navigation_plan.dart';
import '../../core/components/baca_tepat_mark.dart';
import '../../core/theme/app_tokens.dart';
import 'teacher_demo_store.dart';
import 'teacher_feature_page.dart';

class TeacherShell extends StatelessWidget {
  const TeacherShell({required this.screen, this.arguments, super.key});

  final PlannedScreen screen;
  final Object? arguments;

  static const _canvas = Color(0xFFF4F7F6);

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      scaffoldBackgroundColor: _canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppTokens.text,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
    ),
    child: Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (screen.placement == NavigationPlacement.detail)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text('Kembali ke ${_parentTitle(screen.parentId)}'),
                ),
              ),
            Expanded(
              child: TeacherPageBody(screen: screen, arguments: arguments),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _TeacherBottomNavigation(
        selected: screen,
        onMore: () => _showMore(context),
      ),
    ),
  );

  PreferredSizeWidget _appBar(BuildContext context) => AppBar(
    title: Row(
      children: [
        const BacaTepatMark(size: 28),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'BacaTepat',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
    actions: [
      if (screen.id == 'G14')
        IconButton(
          tooltip: 'Ubah data siswa',
          onPressed: () => Navigator.pushNamed(
            context,
            '/guru/siswa/form',
            arguments: arguments is int ? arguments : 1,
          ),
          icon: const Icon(Icons.edit_outlined),
        ),
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppTokens.sky,
          child: Text(
            TeacherDemoStore.instance.teacherName.characters.first
                .toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    ],
  );

  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.primaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .43,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MENU GURU',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.1,
                              color: Color(0xFFB8D7D2),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Menu lainnya',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'Tutup menu',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.35,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final destination in [
                        NavigationPlan.teacher.firstWhere(
                          (item) => item.id == 'G9',
                        ),
                        NavigationPlan.teacher.firstWhere(
                          (item) => item.id == 'G11',
                        ),
                        NavigationPlan.teacher.firstWhere(
                          (item) => item.id == 'G13',
                        ),
                        NavigationPlan.teacher.firstWhere(
                          (item) => item.id == 'G15',
                        ),
                        NavigationPlan.teacher.firstWhere(
                          (item) => item.id == 'G16',
                        ),
                        NavigationPlan.teacher.firstWhere(
                          (item) => item.id == 'G17',
                        ),
                      ])
                        _MoreMenuTile(
                          label: switch (destination.id) {
                            'G9' => 'Soal',
                            'G11' => 'Diagnostik',
                            'G13' => 'Evaluasi',
                            'G15' => 'Perkembangan',
                            'G16' => 'Laporan',
                            _ => 'Profil',
                          },
                          icon: _teacherIcon(destination.id),
                          badge: destination.id == 'G13'
                              ? TeacherDemoStore.instance.pendingRecordingCount
                              : null,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            Navigator.pushReplacementNamed(
                              context,
                              destination.path,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: Color(0xFFB8D7D2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Data siswa terlindungi',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB8D7D2)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _parentTitle(String? parentId) {
  if (parentId == null) return 'sebelumnya';
  return NavigationPlan.teacher
      .firstWhere((item) => item.id == parentId)
      .title
      .toLowerCase();
}

class _TeacherBottomNavigation extends StatelessWidget {
  const _TeacherBottomNavigation({
    required this.selected,
    required this.onMore,
  });
  final PlannedScreen selected;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    const ids = ['G2', 'G3', 'G5', 'G6'];
    final selectedId = selected.parentId ?? selected.id;
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (final id in ids)
                Expanded(child: _item(context, id, selectedId == id)),
              Expanded(
                child: InkWell(
                  onTap: onMore,
                  child: _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Lainnya',
                    selected: !ids.contains(selected.parentId ?? selected.id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, String id, bool isSelected) {
    final page = NavigationPlan.teacher.firstWhere((item) => item.id == id);
    return InkWell(
      onTap: () => Navigator.pushReplacementNamed(context, page.path),
      child: _NavItem(
        icon: _teacherIcon(id),
        label: switch (id) {
          'G2' => 'Ringkasan',
          'G3' => 'Siswa',
          'G5' => 'Kelas',
          'G6' => 'Materi',
          _ => 'Lainnya',
        },
        selected: isSelected,
      ),
    );
  }
}

class _MoreMenuTile extends StatelessWidget {
  const _MoreMenuTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.badge,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF214F4D),
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFD8E7E3)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (badge != null && badge! > 0)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: AppTokens.coral,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
  });
  final IconData icon;
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        icon,
        size: 21,
        color: selected ? AppTokens.primary : const Color(0xFF83908D),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: 10,
          height: 1.2,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          color: selected ? AppTokens.primary : const Color(0xFF71807D),
        ),
      ),
    ],
  );
}

IconData _teacherIcon(String id) => switch (id) {
  'G2' => Icons.home_outlined,
  'G3' => Icons.people_alt_outlined,
  'G5' => Icons.class_outlined,
  'G6' => Icons.menu_book_outlined,
  'G9' => Icons.quiz_outlined,
  'G11' => Icons.fact_check_outlined,
  'G13' => Icons.mic_none_rounded,
  'G15' => Icons.show_chart_rounded,
  'G16' => Icons.description_outlined,
  'G17' => Icons.account_circle_outlined,
  _ => Icons.circle_outlined,
};
