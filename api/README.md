# API BacaTepat

Laravel 12 dan MySQL 8 melayani aplikasi Flutter melalui `/api/v1`. Autentikasi menggunakan Sanctum. Penilaian dan rekomendasi dijalankan pada server. Worker OpenAI membuat draf untuk ditinjau Guru dan transkripsi indikatif untuk rekaman yang memenuhi syarat.

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

Pada database pengembangan kosong, `php artisan db:seed` memuat kelas, siswa, materi dan riwayat fiktif. Kredensial demo ada di [panduan database](database/sql/README_DATABASE.md). Untuk instalasi sekolah, buat akun awal melalui `php artisan guru:buat username "Nama Guru"`. Perintah meminta kata sandi secara tersembunyi. Guru kemudian dapat membuat akun siswa dari halaman kelas.

## Flutter

Dari folder `mobile/`, jalankan `flutter pub get` lalu `flutter run`. Android Emulator mengakses `http://10.0.2.2:8000/api/v1`. Flutter web memakai origin halaman yang sedang dibuka. Untuk perangkat fisik atau web dengan origin berbeda, berikan alamat server:

```sh
flutter run --dart-define=API_BASE_URL=https://alamat-server/api/v1
```

Untuk origin web berbeda, isi WEB_ORIGINS di server dengan daftar origin yang dipisah koma. Flutter menyimpan token memakai flutter_secure_storage dan memeriksa profil saat aplikasi dibuka ulang. Mode pratinjau data lokal tersedia melalui `--dart-define=DEMO_MODE=true`.

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
