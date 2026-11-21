# Final Visual Review — BacaTepat Mobile

Tanggal pemeriksaan: 21 November 2026. Seluruh 38 PNG di `design-pages/` dibuka dan diperiksa melalui lembar kontak, lalu dibandingkan dengan screenshot aplikasi yang berjalan. Aplikasi dijalankan dengan Flutter Web di Microsoft Edge headless. Screenshot diambil pada viewport 320 × 844 dp dan 390 × 844 dp.

AVD `Medium_Phone_API_37.0` tidak dapat dipakai. ADB berhenti sebelum menemukan perangkat karena mencoba membuat direktori `\.android` dan gagal dengan `Permission denied`. Karena itu, pemeriksaan ini membuktikan hasil Flutter Web pada ukuran viewport tersebut, bukan hasil render native Android.

## Screenshot

Screenshot aktual tersedia pada `review/screenshots/final/`. Setiap halaman route Siswa S1–S10 dan Guru G1–G17 ditangkap pada 320 dp dan 390 dp. Menu Guru (desain 38) juga ditangkap pada kedua lebar. Lembar kontak membantu meninjau seluruh hasil:

- Siswa 390 dp: `screenshots/final/S-review.png`
- Siswa 320 dp: `screenshots/final/S-review-320.png`
- Guru 390 dp: `screenshots/final/G-review-01.png`, `G-review-02.png`, `G-review-03.png`
- Guru 320 dp: `screenshots/final/G-review-320-01.png`, `G-review-320-02.png`, `G-review-320-03.png`
- Welcome 390 dp: `screenshots/final/welcome-final-390.png`
- Rekaman S7 320 dp: `screenshots/final/S7-final-320.png`
- Perkembangan S9 390 dp: `screenshots/final/S9-final-390.png`
- Hasil diagnostik G12 320 dp: `screenshots/final/G12-final-320.png`

## Sesuai template

- Welcome, S1, S2, S3, S4, S5, S7, S10.
- G1–G11 dan G13–G17.
- Menu Guru G18.

Kesesuaian dinilai dari susunan halaman, header, komponen utama, warna, dan navigasi pada viewport yang ditinjau. Welcome sekarang memakai buku yang terbuka dengan halaman berganti, identitas BacaTepat, tile huruf, indikator singkat, tombol “Lewati”, lalu otomatis masuk ke Login. Login memuat form sesuai role; pilihan Siswa/Guru ada di bagian bawah dan mengubah form serta warna sesuai role.

## Perlu perbaikan kecil

- **S5 — Materi:** susunan buku, teks bacaan, tips, dan tombol latihan sudah mengikuti desain. Kontrol audio yang tampak di template belum tersedia; aksi dengar contoh saat ini memberi keterangan bahwa audio tidak tersedia pada simulasi.
- **S6 — Pengerjaan latihan:** progres, ilustrasi, dan tiga pilihan sejajar sudah mendekati komposisi template. Ilustrasi yang digunakan adalah buku terbuka, sementara contoh template memakai ilustrasi objek sesuai kata.
- **S9 — Perkembangan:** banner, tahapan, dan grafik batang sudah disusun ulang. Grafik merangkum skor empat aspek yang tersedia; template menampilkan empat minggu. Data lokal tidak menyimpan tanggal per aktivitas untuk membuat tren mingguan yang valid.
- **G12 pada 320 dp:** tabel hasil tetap muat tanpa overflow; judul kolom yang sempit dipendekkan dengan ellipsis.

## Berbeda signifikan

- **S8 — Hasil Evaluasi:** data lokal belum memiliki penilaian Guru untuk siswa demo yang sedang masuk. Screenshot menunjukkan empty state, sedangkan template menampilkan daftar evaluasi. Halaman ini belum dapat disamakan secara visual tanpa data evaluasi.

## State template yang belum ditangkap terpisah

Berikut ini merupakan state tambahan di dalam route yang sama atau dialog, bukan route terpisah dalam `NavigationPlan`. Template-nya sudah diperiksa, tetapi screenshot aktual state berikut belum diambil; statusnya tidak dianggap lolos pemeriksaan visual:

- Desain 06: ringkasan setelah tes diagnostik selesai.
- Desain 10: ringkasan setelah latihan selesai.
- Desain 18: form ubah siswa (desain 17 form tambah ditangkap melalui G4).
- Desain 20: dialog/form kelas dari G5.
- Desain 23: mode ubah materi pada form G7.
- Desain 26–27: dialog tambah dan ubah soal dari G9.
- Desain 30: builder tes diagnostik dari G11.

Desain rekomendasi Guru (34) tampil sebagai bagian halaman detail siswa G14, bukan sebagai screenshot halaman terpisah. Halaman evaluasi S8 sudah ditangkap, tetapi isinya empty state seperti dijelaskan di atas.

## Aset visual

Implementasi memakai crop dari PNG desain: `reading-book.png`, `student-avatar.png`, `welcome-book-left.png`, `welcome-book-right.png`, `welcome-letter-a.png`, `welcome-letter-b.png`, dan `welcome-letter-ca.png`. Font Nunito Sans lokal tetap digunakan. Ilustrasi tidak diregangkan dan tidak ada screenshot penuh yang dijadikan background.

## Pemeriksaan kode

- `dart format lib test`: selesai; 39 file diformat, tidak ada perubahan format pada pass final.
- `flutter analyze`: **No issues found**.
- `flutter test --reporter expanded`: **All tests passed** (4 test; termasuk render route pada 320, 390, dan 1280 dp).

Widget test mencakup alur Welcome ke Login, pemilihan role di Login, login siswa, navigasi, dan render semua route. Pemeriksaan interaksi rekaman tetap simulasi lokal; aplikasi tidak mengakses mikrofon atau mengirim berkas audio.
