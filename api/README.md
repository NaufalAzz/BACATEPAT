# API BacaTepat

Laravel 12 dan MySQL 8 menyediakan layanan untuk alur guru dan siswa melalui `/api/v1`. Autentikasi menggunakan Sanctum. Penilaian dan rekomendasi dijalankan pada server. Worker OpenAI membuat draf untuk ditinjau Guru dan transkripsi indikatif untuk rekaman yang memenuhi syarat.

## Menjalankan server lokal

Siapkan PHP 8.2+ dengan ekstensi Laravel, PDO MySQL, DOM dan mbstring, Composer 2, MySQL 8.0.19+ dan ffprobe dari FFmpeg. Buat database kosong dan akun MySQL yang dapat menjalankan migrasi pada database tersebut. Dari folder `api/`:

```sh
composer install
cp .env.example .env
php artisan key:generate
```

Atur DB_HOST, DB_DATABASE, DB_USERNAME dan DB_PASSWORD di .env. Jalankan:

```sh
php artisan migrate
php artisan serve
```

Endpoint `GET /api/v1/health` memberi respons `{"service":"bacatepat","status":"ok"}`. Gunakan `php artisan route:list --path=api/v1` untuk daftar endpoint aplikasi.

Pada database pengembangan kosong, `php artisan db:seed` memuat kelas, siswa, materi dan riwayat fiktif. Kredensial demo ada di [panduan database](../database/README_DATABASE.md). Untuk instalasi sekolah, buat akun awal melalui `php artisan guru:buat username "Nama Guru"`. Perintah meminta kata sandi secara tersembunyi. Guru kemudian dapat membuat akun siswa dari halaman kelas.

## Kontrak untuk frontend asli

Untuk memakai akun MySQL dari layar Flutter asli, jalankan API di port 8000 dan gunakan terminal kedua dari folder `mobile/`:

```powershell
flutter pub get
flutter run -d chrome --web-hostname=localhost --web-port=5173 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Set `WEB_ORIGINS=http://localhost:5173` di `api/.env`. Login, pemulihan sesi, pembacaan data akun, dan penyimpanan latihan pilihan ganda menggunakan API. Token disimpan melalui flutter_secure_storage. Perintah `flutter run` tanpa alamat API menjalankan mode demo lokal. Formulir administrasi, diagnostik, dan perekaman suara masih mengikuti alur pratinjau pada tahap ini.

Migrasi dan seeder membaca berkas SQL asli dari folder `database/` di samping `api/`. Sertakan kedua folder saat menyiapkan server.

Semua rute di bawah memakai awalan `/api/v1`. Kirim JSON dengan header `Accept: application/json`. Login dengan `POST auth/login` dan field `username`, `password`, dan `device_name`. Field opsional `role` menerima `guru` atau `siswa` sesuai portal. Gunakan `data.token` sebagai bearer token untuk permintaan berikutnya. Daftar dengan paginasi Laravel menyediakan `data`, `current_page`, dan `last_page`.

| Alur yang sudah ada di UI | Endpoint utama |
| --- | --- |
| Ringkasan guru, kelas, siswa dan profil | `guru/dashboard`, `guru/kelas`, `guru/siswa`, `guru/profil` |
| Bank materi, soal dan draf AI | `guru/materi`, `guru/soal`, `guru/ai/{kind}`, `guru/ai/permintaan/{id}` |
| Penyusunan dan hasil diagnostik | `guru/diagnostik`, `guru/diagnostik/{id}/status`, `guru/diagnostik/{id}/hasil` |
| Beranda dan tes siswa | `siswa/beranda`, `siswa/diagnostik/aktif`, `siswa/diagnostik/mulai`, `siswa/diagnostik/hasil/{id}/jawaban`, `siswa/diagnostik/hasil/{id}/selesai` |
| Latihan, hasil dan rekomendasi | `siswa/latihan`, `siswa/latihan/mulai`, `siswa/latihan/{id}/jawaban`, `siswa/latihan/{id}/selesai`, `siswa/latihan/riwayat`, `guru/siswa/{id}/rekomendasi` |
| Persetujuan wali, rekaman dan penilaian guru | `guru/siswa/{id}/persetujuan`, `siswa/rekaman`, `guru/rekaman`, `guru/rekaman/{id}/evaluasi`, `siswa/evaluasi` |
| Grafik, pendampingan, dan laporan PDF | `siswa/perkembangan`, `guru/perkembangan/kelas/{id}`, `guru/pendampingan`, `guru/laporan/{scope}/{id}` |

Contoh permintaan lengkap untuk tes dan latihan ada di [uji alur API](tests/diagnostic_flow.py). Untuk klien web lokal, `WEB_ORIGINS` memuat origin lengkap, misalnya `http://localhost:5173`.

## AI, rekaman dan laporan

Atur OPENAI_API_KEY, OPENAI_TEXT_MODEL, dan OPENAI_TRANSCRIPTION_MODEL di .env pada server. Default model teks adalah gpt-4.1-mini dan model transkripsi gpt-4o-mini-transcribe. Draf diminta melalui `POST /guru/ai/materi` atau `POST /guru/ai/soal`. Respons 202 berisi ID untuk `GET /guru/ai/permintaan/{id}`. Semua path ini memakai prefix /api/v1.

Jalankan kedua proses berikut pada terminal atau proses layanan tersendiri:

```sh
php artisan queue:work database --timeout=75
php artisan schedule:work
```

File audio berada di storage/app/private. Unggah memerlukan izin wali. Pengiriman audio ke OpenAI juga memerlukan izin AI, konteks kata atau kalimat, dan kunci pada server. Evaluasi Guru menetapkan nilai resmi. Laporan PDF berasal dari riwayat penguasaan yang bisa diakses Guru untuk kelasnya. Retensi file audio dihitung saat evaluasi dibuat berdasarkan pengaturan Guru (default 90 hari). Scheduler membersihkan file yang jatuh tempo.

## Operasional dan pengujian

Untuk deployment, arahkan document root ke public/, aktifkan HTTPS, gunakan APP_ENV=production dan APP_DEBUG=false, batasi WEB_ORIGINS, dan jalankan worker serta scheduler di bawah process manager. Simpan APP_KEY dan file rekaman di media persisten. Jadwalkan bin/backup-mysql sekali sehari dengan MYSQL_CLIENT_FILE (konfigurasi klien privat), DB_DATABASE, dan BACKUP_DIR. Dump database disimpan selama 14 hari. Uji pemulihan ke database terpisah setiap semester.

Pada database pengujian tersendiri yang telah di-seed, jalankan server dengan OPENAI_API_KEY kosong. Tetapkan BACATEPAT_TEST_URL dan BACATEPAT_DEMO_PASSWORD, kemudian jalankan `python3 tests/diagnostic_flow.py`. Uji ini menambah data sintetis dan memeriksa login, pembatasan peran, diagnostik, latihan, PDF, consent audio, evaluasi, revisi, dan logout. Untuk worker dengan respons OpenAI simulasi, jalankan `BACATEPAT_INTEGRATION_TEST=1 php tests/ai_worker.php` dalam environment database uji yang sama.

Pengujian tambahan menggunakan BACATEPAT_INTEGRATION_TEST=1 dan database pengujian yang telah di-seed:

| Perintah | Yang diperiksa |
| --- | --- |
| `php tests/class_ownership.php` | Guru kelas lain tidak bisa membaca data siswa atau mengubah evaluasinya. |
| `php tests/audio_retention.php` | File yang jatuh tempo dihapus, dan nilai evaluasi tetap dapat dibaca. |
| `php tests/ai_worker.php` | Draf tetap menunggu review, retry tidak menggandakan materi, izin AI diperiksa, dan transkrip simulasi dibandingkan dengan bacaan target. |

Untuk menambahkan tiga materi Bahasa Indonesia dari buku Pusat Perbukuan ke akun guru sekolah, jalankan `php artisan materi:kurikulum USERNAME_GURU`. Perintah ini melewati judul yang sudah ada pada katalog guru tersebut.
