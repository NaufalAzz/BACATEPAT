/// BRD screen inventory and proposed menu hierarchy; no routes are wired yet.
enum AppRole { teacher, student }

enum NavigationPlacement { primary, detail }

class PlannedScreen {
  const PlannedScreen({
    required this.id,
    required this.title,
    required this.path,
    required this.role,
    required this.group,
    required this.placement,
    this.parentId,
  });

  final String id;
  final String title;
  final String path;
  final AppRole role;
  final String group;
  final NavigationPlacement placement;
  final String? parentId;
}

abstract final class NavigationPlan {
  static const teacher = <PlannedScreen>[
    PlannedScreen(
      id: 'G1',
      title: 'Login Guru',
      path: '/guru/login',
      role: AppRole.teacher,
      group: 'Akun',
      placement: NavigationPlacement.detail,
    ),
    PlannedScreen(
      id: 'G2',
      title: 'Dashboard',
      path: '/guru',
      role: AppRole.teacher,
      group: 'Ringkasan',
      placement: NavigationPlacement.primary,
    ),
    PlannedScreen(
      id: 'G3',
      title: 'Data Siswa',
      path: '/guru/siswa',
      role: AppRole.teacher,
      group: 'Siswa',
      placement: NavigationPlacement.primary,
    ),
    PlannedScreen(
      id: 'G4',
      title: 'Tambah/Ubah Siswa',
      path: '/guru/siswa/form',
      role: AppRole.teacher,
      group: 'Siswa',
      placement: NavigationPlacement.detail,
      parentId: 'G3',
    ),
    PlannedScreen(
      id: 'G5',
      title: 'Data Kelas',
      path: '/guru/kelas',
      role: AppRole.teacher,
      group: 'Kelas',
      placement: NavigationPlacement.primary,
    ),
    PlannedScreen(
      id: 'G6',
      title: 'Bank Materi',
      path: '/guru/materi',
      role: AppRole.teacher,
      group: 'Materi',
      placement: NavigationPlacement.primary,
    ),
    PlannedScreen(
      id: 'G7',
      title: 'Tambah Materi',
      path: '/guru/materi/tambah',
      role: AppRole.teacher,
      group: 'Materi',
      placement: NavigationPlacement.detail,
      parentId: 'G6',
    ),
    PlannedScreen(
      id: 'G8',
      title: 'Generator Materi AI',
      path: '/guru/materi/generator',
      role: AppRole.teacher,
      group: 'Materi',
      placement: NavigationPlacement.detail,
      parentId: 'G6',
    ),
    PlannedScreen(
      id: 'G9',
      title: 'Bank Soal',
      path: '/guru/soal',
      role: AppRole.teacher,
      group: 'Soal',
      placement: NavigationPlacement.primary,
    ),
    PlannedScreen(
      id: 'G10',
      title: 'Generator Soal AI',
      path: '/guru/soal/generator',
      role: AppRole.teacher,
      group: 'Soal',
      placement: NavigationPlacement.detail,
      parentId: 'G9',
    ),
    PlannedScreen(
      id: 'G11',
      title: 'Tes Diagnostik',
      path: '/guru/diagnostik',
      role: AppRole.teacher,
      group: 'Diagnostik',
      placement: NavigationPlacement.primary,
    ),
    PlannedScreen(
      id: 'G12',
      title: 'Hasil Diagnostik',
      path: '/guru/diagnostik/hasil',
      role: AppRole.teacher,
      group: 'Diagnostik',
      placement: NavigationPlacement.detail,
      parentId: 'G11',
    ),
    PlannedScreen(
      id: 'G13',
      title: 'Evaluasi Rekaman',
      path: '/guru/rekaman',
      role: AppRole.teacher,
      group: 'Evaluasi',
      placement: NavigationPlacement.primary,
    ),
    PlannedScreen(
      id: 'G14',
      title: 'Detail Siswa',
      path: '/guru/siswa/detail',
      role: AppRole.teacher,
      group: 'Siswa',
      placement: NavigationPlacement.detail,
      parentId: 'G3',
    ),
    PlannedScreen(
      id: 'G15',
      title: 'Grafik Perkembangan',
      path: '/guru/perkembangan',
      role: AppRole.teacher,
      group: 'Laporan',
      placement: NavigationPlacement.primary,
    ),
    PlannedScreen(
      id: 'G16',
      title: 'Laporan',
      path: '/guru/laporan',
      role: AppRole.teacher,
      group: 'Laporan',
      placement: NavigationPlacement.primary,
    ),
    PlannedScreen(
      id: 'G17',
      title: 'Profil',
      path: '/guru/profil',
      role: AppRole.teacher,
      group: 'Akun',
      placement: NavigationPlacement.primary,
    ),
  ];

  static const student = <PlannedScreen>[
    PlannedScreen(
      id: 'S1',
      title: 'Login Siswa',
      path: '/siswa/login',
      role: AppRole.student,
      group: 'Akun',
      placement: NavigationPlacement.detail,
    ),
    PlannedScreen(
      id: 'S2',
      title: 'Beranda',
      path: '/siswa',
      role: AppRole.student,
      group: 'Beranda',
      placement: NavigationPlacement.primary,
    ),
    PlannedScreen(
      id: 'S3',
      title: 'Tes Diagnostik',
      path: '/siswa/diagnostik',
      role: AppRole.student,
      group: 'Belajar',
      placement: NavigationPlacement.detail,
      parentId: 'S2',
    ),
    PlannedScreen(
      id: 'S4',
      title: 'Latihan Membaca',
      path: '/siswa/latihan',
      role: AppRole.student,
      group: 'Belajar',
      placement: NavigationPlacement.primary,
    ),
    PlannedScreen(
      id: 'S5',
      title: 'Detail Materi',
      path: '/siswa/latihan/materi',
      role: AppRole.student,
      group: 'Belajar',
      placement: NavigationPlacement.detail,
      parentId: 'S4',
    ),
    PlannedScreen(
      id: 'S6',
      title: 'Pengerjaan Latihan',
      path: '/siswa/latihan/kerjakan',
      role: AppRole.student,
      group: 'Belajar',
      placement: NavigationPlacement.detail,
      parentId: 'S5',
    ),
    PlannedScreen(
      id: 'S7',
      title: 'Rekaman Suara',
      path: '/siswa/rekaman',
      role: AppRole.student,
      group: 'Belajar',
      placement: NavigationPlacement.detail,
      parentId: 'S6',
    ),
    PlannedScreen(
      id: 'S8',
      title: 'Hasil Evaluasi',
      path: '/siswa/evaluasi',
      role: AppRole.student,
      group: 'Perkembangan',
      placement: NavigationPlacement.primary,
    ),
    PlannedScreen(
      id: 'S9',
      title: 'Perkembangan Saya',
      path: '/siswa/perkembangan',
      role: AppRole.student,
      group: 'Perkembangan',
      placement: NavigationPlacement.primary,
    ),
    PlannedScreen(
      id: 'S10',
      title: 'Profil',
      path: '/siswa/profil',
      role: AppRole.student,
      group: 'Akun',
      placement: NavigationPlacement.primary,
    ),
  ];
}
