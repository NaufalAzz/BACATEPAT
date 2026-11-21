# Rencana struktur website BacaTepat

Folder ini disiapkan untuk website Laravel Blade + Tailwind CSS. Belum ada proyek Laravel atau konfigurasi backend/API di tahap fondasi ini.

Rencana area Blade:

```text
resources/views/
  layouts/       # kerangka bersama dan navigasi
  components/    # komponen Blade yang dipakai ulang
  auth/          # tampilan login Guru
  guru/          # dashboard, siswa, kelas, materi, soal, diagnostik,
                 # evaluasi rekaman, perkembangan, laporan, profil
```

Rencana aset dan frontend:

```text
resources/css/       # entry point Tailwind dan gaya global
resources/js/        # interaksi kecil antarmuka bila dibutuhkan
public/images/       # gambar dan ilustrasi website
public/icons/        # ikon dan favicon
```

Website difokuskan pada alur Guru; kegiatan belajar siswa direncanakan berlangsung di aplikasi Flutter. Struktur final disesuaikan saat proyek Laravel dibuat.
