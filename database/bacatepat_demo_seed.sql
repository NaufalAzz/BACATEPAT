-- Fictional BacaTepat demo data for local development and review.
-- Import bacatepat_database.sql first. Never run this on production data.
-- IDs 900001-909999 are reserved by this seed. INSERT IGNORE makes reruns
-- idempotent and does not update existing rows. The target should be a fresh
-- schema containing only the four learning_aspects reference rows.

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET time_zone = '+00:00';
START TRANSACTION;

-- Local classroom accounts; credentials are listed in README_DATABASE.md.
INSERT IGNORE INTO users
  (id, name, username, email, password_hash, role, status, created_at, updated_at)
VALUES
  (900001, 'Rina Marlina', 'burina', NULL, '$2y$10$Oh8sGV9OZo//pNyM3SyFU./x.keG5DMBg/x5gw.DeWyyUSKWzhY2a', 'guru', 'aktif', '2026-11-20 08:00:00', '2026-11-20 08:00:00'),
  (900002, 'Andi Pratama', 'andi', NULL, '$2y$10$hUy4Y2ET7XU5AM4rioZbbugYzX85t.lm6K4XCne7kwBWwsHNBAFAO', 'siswa', 'aktif', '2026-11-20 08:00:00', '2026-11-20 08:00:00'),
  (900003, 'Siti Aisyah', 'siti', NULL, '$2y$10$MFz9EHlN6iR9kdg2HM9PyeWNF9V/o6yYVKhKY27gTKvfDaBr8tg0u', 'siswa', 'aktif', '2026-11-20 08:00:00', '2026-11-20 08:00:00'),
  (900004, 'Bunga Lestari', 'bunga', NULL, '$2y$10$gntEUO/tr3gVL7A9sQQDm.aKXhhYVn1uD7Kxqoxgs/UW5C5B2i7ey', 'siswa', 'aktif', '2026-11-20 08:00:00', '2026-11-20 08:00:00'),
  (900005, 'Dimas Saputra', 'dimas', NULL, '$2y$10$dLDogXw5UNN.vgkQvRWDC.HfXXYeBgKsrycH3IbU.oWlvBXICnwFW', 'siswa', 'aktif', '2026-11-20 08:00:00', '2026-11-20 08:00:00'),
  (900006, 'Raka Pranata', 'raka', NULL, '$2y$10$rFNlbPWeyjEuAwV.RdAkku5o1y7xeLSOtKkkhhI/peighIfGNTO0y', 'siswa', 'aktif', '2026-11-20 08:00:00', '2026-11-20 08:00:00'),
  (900007, 'Lina Maharani', 'lina', NULL, '$2y$10$0RZGXgX/BUmDjtREzJDyiOs3IGlfTTI66CdJ2zTWFGjfWmrgscOcG', 'siswa', 'aktif', '2026-11-20 08:00:00', '2026-11-20 08:00:00');

INSERT IGNORE INTO classes
  (id, teacher_id, name, grade, school_year, status, created_at, updated_at)
VALUES
  (900101, 900001, '1A', 1, '2026/2027', 'aktif', '2026-11-20 08:00:00', '2026-11-20 08:00:00'),
  (900102, 900001, '2A', 2, '2026/2027', 'aktif', '2026-11-20 08:00:00', '2026-11-20 08:00:00'),
  (900103, 900001, '3A', 3, '2026/2027', 'aktif', '2026-11-20 08:00:00', '2026-11-20 08:00:00');

INSERT IGNORE INTO students
  (id, user_id, current_class_id, student_number, guardian_name, parent_consent, ai_consent, consent_recorded_at, status, created_at, updated_at)
VALUES
  (900201, 900002, 900101, 'DEMO-1A-01', 'Bapak Pratama', 1, 1, '2026-11-20 08:10:00', 'aktif', '2026-11-20 08:10:00', '2026-11-20 08:10:00'),
  (900202, 900003, 900101, 'DEMO-1A-02', 'Ibu Aminah', 1, 0, '2026-11-20 08:11:00', 'aktif', '2026-11-20 08:11:00', '2026-11-20 08:11:00'),
  (900203, 900004, 900102, 'DEMO-2A-01', 'Ibu Lestari', 1, 0, '2026-11-20 08:12:00', 'aktif', '2026-11-20 08:12:00', '2026-11-20 08:12:00'),
  (900204, 900005, 900102, 'DEMO-2A-02', 'Bapak Saputra', 1, 1, '2026-11-20 08:13:00', 'aktif', '2026-11-20 08:13:00', '2026-11-20 08:13:00'),
  (900205, 900006, 900103, 'DEMO-3A-01', 'Ibu Pranata', 1, 0, '2026-11-20 08:14:00', 'aktif', '2026-11-20 08:14:00', '2026-11-20 08:14:00'),
  (900206, 900007, 900103, 'DEMO-3A-02', 'Bapak Maharani', 1, 0, '2026-11-20 08:15:00', 'aktif', '2026-11-20 08:15:00', '2026-11-20 08:15:00');

INSERT IGNORE INTO student_class_memberships
  (id, student_id, class_id, started_at, ended_at, recorded_by_teacher_id, created_at)
VALUES
  (900301, 900201, 900101, '2026-11-20 08:10:00', NULL, 900001, '2026-11-20 08:10:00'),
  (900302, 900202, 900101, '2026-11-20 08:11:00', NULL, 900001, '2026-11-20 08:11:00'),
  (900303, 900203, 900102, '2026-11-20 08:12:00', NULL, 900001, '2026-11-20 08:12:00'),
  (900304, 900204, 900102, '2026-11-20 08:13:00', NULL, 900001, '2026-11-20 08:13:00'),
  (900305, 900205, 900103, '2026-11-20 08:14:00', NULL, 900001, '2026-11-20 08:14:00'),
  (900306, 900206, 900103, '2026-11-20 08:15:00', NULL, 900001, '2026-11-20 08:15:00');

INSERT IGNORE INTO student_consent_events
  (id, student_id, recorded_by_teacher_id, guardian_name_snapshot, parent_consent, ai_consent, recorded_at, note)
VALUES
  (900401, 900201, 900001, 'Bapak Pratama', 1, 1, '2026-11-20 08:10:00', 'Persetujuan simulasi demo.'),
  (900402, 900202, 900001, 'Ibu Aminah', 1, 0, '2026-11-20 08:11:00', 'Persetujuan simulasi demo; AI tidak diizinkan.'),
  (900403, 900203, 900001, 'Ibu Lestari', 1, 0, '2026-11-20 08:12:00', 'Persetujuan simulasi demo; AI tidak diizinkan.'),
  (900404, 900204, 900001, 'Bapak Saputra', 1, 1, '2026-11-20 08:13:00', 'Persetujuan simulasi demo.'),
  (900405, 900205, 900001, 'Ibu Pranata', 1, 0, '2026-11-20 08:14:00', 'Persetujuan simulasi demo; AI tidak diizinkan.'),
  (900406, 900206, 900001, 'Bapak Maharani', 1, 0, '2026-11-20 08:15:00', 'Persetujuan simulasi demo; AI tidak diizinkan.');

INSERT IGNORE INTO materials
  (id, teacher_id, aspect_code, level, title, content, ai_generated, status, created_at, updated_at)
VALUES
  (900501, 900001, 'huruf', 1, 'Mengenal bunyi huruf', 'Kenali bunyi huruf vokal dan konsonan awal melalui contoh sederhana.', 0, 'active', '2026-11-20 09:00:00', '2026-11-20 09:00:00'),
  (900502, 900001, 'huruf', 2, 'Huruf dalam kata', 'Amati bunyi huruf awal dan akhir pada kata yang sering dijumpai.', 0, 'active', '2026-11-20 09:05:00', '2026-11-20 09:05:00'),
  (900503, 900001, 'suku_kata', 1, 'Suku kata ba bi bu be bo', 'Baca ba, bi, bu, be, bo. Contoh kata: baju, bola, buku.', 0, 'active', '2026-11-20 09:10:00', '2026-11-20 09:10:00'),
  (900504, 900001, 'suku_kata', 2, 'Suku kata ka ki ku ke ko', 'Gabungkan suku kata ka, ki, ku, ke, ko menjadi kata sederhana.', 0, 'active', '2026-11-20 09:15:00', '2026-11-20 09:15:00'),
  (900505, 900001, 'kata', 1, 'Kata di sekitar kita', 'Baca kata benda yang sering dijumpai di rumah dan sekolah.', 0, 'active', '2026-11-20 09:20:00', '2026-11-20 09:20:00'),
  (900506, 900001, 'kata', 2, 'Membaca dan melengkapi kata', 'Baca kata lebih panjang dan perhatikan bagian awal serta akhirnya.', 0, 'active', '2026-11-20 09:25:00', '2026-11-20 09:25:00'),
  (900507, 900001, 'kalimat', 1, 'Kalimat sederhana', 'Baca kalimat pendek dengan memperhatikan urutan kata.', 0, 'active', '2026-11-20 09:30:00', '2026-11-20 09:30:00'),
  (900508, 900001, 'kalimat', 2, 'Kalimat tentang kegiatan', 'Baca kalimat sederhana tentang kegiatan sehari-hari.', 0, 'active', '2026-11-20 09:35:00', '2026-11-20 09:35:00'),
  (900509, 900001, 'suku_kata', 1, 'Variasi suku kata sehari-hari', 'Latihan tambahan ba, bi, bu, be, bo dengan petunjuk kata yang berbeda.', 0, 'active', '2026-11-20 09:36:00', '2026-11-20 09:36:00'),
  (900510, 900001, 'kata', 1, 'Variasi kata benda', 'Latihan tambahan membaca kata benda di rumah dan sekolah.', 0, 'active', '2026-11-20 09:37:00', '2026-11-20 09:37:00'),
  (900511, 900001, 'kalimat', 1, 'Variasi kalimat pendek', 'Latihan tambahan memahami urutan kata dalam kalimat pendek.', 0, 'active', '2026-11-20 09:38:00', '2026-11-20 09:38:00'),
  (900512, 900001, 'huruf', 1, 'Variasi bunyi huruf', 'Latihan tambahan mengenali huruf awal pada bunyi sederhana.', 0, 'active', '2026-11-20 09:39:00', '2026-11-20 09:39:00');

INSERT IGNORE INTO materials (id, grade, teacher_id, aspect_code, level, title, content, ai_generated, status, created_at, updated_at) VALUES
(900513, 1, 900001, 'suku_kata', 1, 'Kelas 1 · Bunyi Apa?', '“Itu bola Boni. Bola Boni biru. Bola kena batu.” Baca bersama gurumu. Apa warna bola Boni?
Sumber: Kutipan dari Bahasa Indonesia Aku Bisa!, Bab 1, Pusat Perbukuan. Buku audio: https://buku.kemendikdasmen.go.id/katalog/buku-audio-bahasa-indonesia-aku-bisa-untuk-sd-mi-kelas-i-edisi-revisi', 0, 'active', NOW(), NOW()),
(900514, 2, 900001, 'kata', 1, 'Kelas 2 · Mengenal Perasaan', '“Bagaimana perasaanmu saat bertemu guru dan teman-temanmu di sekolah hari ini?” Pilih satu kata: senang, sedih, atau takut.
Sumber: Kutipan dari Bahasa Indonesia Keluargaku Unik, Bab 1. Buku siswa: https://static-sc.cloudapp.web.id/content/pdf/bukuteks/kurikulum21/Indonesia_BS_KLS_II_Rev.pdf', 0, 'active', NOW(), NOW()),
(900515, 3, 900001, 'kalimat', 2, 'Kelas 3 · Ayo, Main!', 'Sebutkan permainan kesukaanmu. Jelaskan cara bermain kepada temanmu. Minta ia mencoba mengikuti petunjukmu.
Sumber: Adaptasi dari Bahasa Indonesia Kawan Seiring, Bab I, Pusat Perbukuan (2022). Katalog: https://buku.kemendikdasmen.go.id/', 0, 'active', NOW(), NOW());

INSERT IGNORE INTO questions
  (id, teacher_id, material_id, aspect_code, level, question_type, usage_scope, prompt, stimulus_text, target_text, hint, explanation, ai_generated, review_status, reviewed_by_teacher_id, reviewed_at, created_at, updated_at)
VALUES
  (900601, 900001, 900501, 'huruf', 1, 'multiple_choice', 'both', 'Pilih huruf yang sesuai dengan bunyi awal.', 'Bunyi yang terdengar: /b/.', NULL, 'Dengarkan bunyi awalnya.', 'Huruf b mewakili bunyi /b/.', 0, 'approved', 900001, '2026-11-20 10:00:00', '2026-11-20 09:40:00', '2026-11-20 10:00:00'),
  (900602, 900001, 900501, 'huruf', 1, 'multiple_choice', 'both', 'Pilih huruf yang sesuai dengan bunyi awal.', 'Bunyi yang terdengar: /m/.', NULL, 'Ucapkan bunyinya perlahan.', 'Huruf m mewakili bunyi /m/.', 0, 'approved', 900001, '2026-11-20 10:00:00', '2026-11-20 09:41:00', '2026-11-20 10:00:00'),
  (900603, 900001, 900501, 'huruf', 1, 'multiple_choice', 'both', 'Pilih huruf vokal yang sesuai dengan bunyi.', 'Bunyi yang terdengar: /i/.', NULL, 'Ingat lima huruf vokal.', 'Huruf i adalah huruf vokal dengan bunyi /i/.', 0, 'approved', 900001, '2026-11-20 10:00:00', '2026-11-20 09:42:00', '2026-11-20 10:00:00'),
  (900604, 900001, 900501, 'huruf', 1, 'multiple_choice', 'both', 'Pilih huruf yang sesuai dengan bunyi awal.', 'Bunyi yang terdengar: /s/.', NULL, 'Dengarkan bunyi awalnya.', 'Huruf s mewakili bunyi /s/.', 0, 'approved', 900001, '2026-11-20 10:00:00', '2026-11-20 09:43:00', '2026-11-20 10:00:00'),
  (900605, 900001, 900503, 'suku_kata', 1, 'multiple_choice', 'both', 'Pilih suku kata pertama yang cocok dengan petunjuk.', 'Pakaian yang dipakai untuk menutup badan.', NULL, 'Ucapkan nama benda dari petunjuk.', 'Kata baju dimulai dengan suku kata ba.', 0, 'approved', 900001, '2026-11-20 10:01:00', '2026-11-20 09:44:00', '2026-11-20 10:01:00'),
  (900606, 900001, 900503, 'suku_kata', 1, 'multiple_choice', 'both', 'Pilih suku kata pertama yang cocok dengan petunjuk.', 'Benda bundar yang biasa ditendang saat bermain.', NULL, 'Pikirkan nama benda yang ditendang.', 'Kata bola dimulai dengan suku kata bo.', 0, 'approved', 900001, '2026-11-20 10:01:00', '2026-11-20 09:45:00', '2026-11-20 10:01:00'),
  (900607, 900001, 900503, 'suku_kata', 1, 'multiple_choice', 'both', 'Pilih suku kata pertama yang cocok dengan petunjuk.', 'Benda berisi halaman untuk dibaca.', NULL, 'Sebutkan benda yang memiliki banyak halaman.', 'Kata buku dimulai dengan suku kata bu.', 0, 'approved', 900001, '2026-11-20 10:01:00', '2026-11-20 09:46:00', '2026-11-20 10:01:00'),
  (900608, 900001, 900503, 'suku_kata', 1, 'multiple_choice', 'both', 'Pilih suku kata pertama yang cocok dengan petunjuk.', 'Buah yang jika dipotong melintang berbentuk bintang.', NULL, 'Pikirkan nama buah yang sering berwarna hijau atau kuning.', 'Kata belimbing dimulai dengan suku kata be.', 0, 'approved', 900001, '2026-11-20 10:01:00', '2026-11-20 09:47:00', '2026-11-20 10:01:00'),
  (900609, 900001, 900503, 'suku_kata', 1, 'multiple_choice', 'both', 'Pilih suku kata pertama yang cocok dengan petunjuk.', 'Buah berwarna kuning yang disukai banyak anak.', NULL, 'Pikirkan nama buahnya.', 'Kata pisang dimulai dengan suku kata pi.', 0, 'approved', 900001, '2026-11-20 10:01:00', '2026-11-20 09:48:00', '2026-11-20 10:01:00'),
  (900610, 900001, 900505, 'kata', 1, 'multiple_choice', 'both', 'Pilih kata yang sesuai dengan petunjuk.', 'Benda yang memiliki halaman dan dibaca.', NULL, 'Baca setiap pilihan sampai selesai.', 'Buku adalah benda yang memiliki halaman untuk dibaca.', 0, 'approved', 900001, '2026-11-20 10:02:00', '2026-11-20 09:49:00', '2026-11-20 10:02:00'),
  (900611, 900001, 900505, 'kata', 1, 'multiple_choice', 'both', 'Pilih kata yang sesuai dengan petunjuk.', 'Benda untuk duduk di kelas.', NULL, 'Ingat benda yang ada di dekat meja belajar.', 'Kursi digunakan untuk duduk.', 0, 'approved', 900001, '2026-11-20 10:02:00', '2026-11-20 09:50:00', '2026-11-20 10:02:00'),
  (900612, 900001, 900505, 'kata', 1, 'multiple_choice', 'both', 'Pilih kata yang sesuai dengan petunjuk.', 'Benda untuk melihat waktu.', NULL, 'Cari benda yang biasanya dipakai di pergelangan tangan.', 'Jam digunakan untuk melihat waktu.', 0, 'approved', 900001, '2026-11-20 10:02:00', '2026-11-20 09:51:00', '2026-11-20 10:02:00'),
  (900613, 900001, 900505, 'kata', 1, 'multiple_choice', 'both', 'Pilih kata yang sesuai dengan petunjuk.', 'Tempat murid belajar bersama Guru.', NULL, 'Pikirkan tempat untuk belajar.', 'Kelas adalah tempat murid belajar.', 0, 'approved', 900001, '2026-11-20 10:02:00', '2026-11-20 09:52:00', '2026-11-20 10:02:00'),
  (900614, 900001, 900507, 'kalimat', 1, 'multiple_choice', 'both', 'Pilih kalimat yang cocok dengan petunjuk.', 'Kegiatan saat seseorang membuka halaman untuk membaca.', NULL, 'Cari kalimat yang menyebut kegiatan membaca.', 'Kalimat membaca buku sesuai dengan petunjuk.', 0, 'approved', 900001, '2026-11-20 10:03:00', '2026-11-20 09:53:00', '2026-11-20 10:03:00'),
  (900615, 900001, 900507, 'kalimat', 1, 'multiple_choice', 'both', 'Pilih kalimat yang cocok dengan petunjuk.', 'Kegiatan menanam bunga di halaman.', NULL, 'Cari kalimat yang menjelaskan kegiatan tersebut.', 'Kalimat menanam bunga sesuai dengan petunjuk.', 0, 'approved', 900001, '2026-11-20 10:03:00', '2026-11-20 09:54:00', '2026-11-20 10:03:00'),
  (900616, 900001, 900507, 'kalimat', 1, 'multiple_choice', 'both', 'Pilih kalimat yang cocok dengan petunjuk.', 'Kegiatan menyiram tanaman pada pagi hari.', NULL, 'Perhatikan waktu dan kegiatan pada petunjuk.', 'Kalimat menyiram tanaman pada pagi hari sesuai.', 0, 'approved', 900001, '2026-11-20 10:03:00', '2026-11-20 09:55:00', '2026-11-20 10:03:00'),
  (900617, 900001, 900507, 'kalimat', 1, 'multiple_choice', 'both', 'Pilih kalimat yang cocok dengan petunjuk.', 'Kegiatan Ibu membuat makanan di dapur.', NULL, 'Cari kalimat tentang kegiatan di dapur.', 'Kalimat Ibu memasak di dapur sesuai.', 0, 'approved', 900001, '2026-11-20 10:03:00', '2026-11-20 09:56:00', '2026-11-20 10:03:00'),
  (900618, 900001, 900502, 'huruf', 2, 'multiple_choice', 'practice', 'Pilih huruf terakhir pada kata.', 'meja', NULL, 'Baca kata dari awal sampai akhir.', 'Huruf terakhir kata meja adalah a.', 0, 'approved', 900001, '2026-11-20 10:04:00', '2026-11-20 09:57:00', '2026-11-20 10:04:00'),
  (900619, 900001, 900504, 'suku_kata', 2, 'multiple_choice', 'practice', 'Pilih suku kata awal yang cocok dengan petunjuk.', 'Hewan yang berjalan dengan empat kaki dan dapat ditunggangi.', NULL, 'Ucapkan nama hewan itu perlahan.', 'Kata kuda dimulai dengan suku kata ku.', 0, 'approved', 900001, '2026-11-20 10:04:00', '2026-11-20 09:58:00', '2026-11-20 10:04:00'),
  (900620, 900001, 900506, 'kata', 2, 'multiple_choice', 'practice', 'Pilih kata yang melengkapi kalimat.', 'Setiap pagi, Rani menyikat ...', NULL, 'Pikirkan benda yang digunakan untuk menyikat gigi.', 'Kata gigi melengkapi kalimat dengan tepat.', 0, 'approved', 900001, '2026-11-20 10:04:00', '2026-11-20 09:59:00', '2026-11-20 10:04:00'),
  (900621, 900001, 900508, 'kalimat', 2, 'multiple_choice', 'practice', 'Pilih kalimat dengan urutan kata yang benar.', 'Konteks: anak-anak bersiap pergi ke sekolah.', NULL, 'Pastikan urutan kata terdengar wajar.', 'Kalimat dengan urutan subjek dan kegiatan tepat.', 0, 'approved', 900001, '2026-11-20 10:04:00', '2026-11-20 10:00:00', '2026-11-20 10:04:00'),
  (900622, 900001, 900505, 'kata', 1, 'oral_reading', 'practice', 'Bacalah kata dengan suara jelas.', 'Kata untuk dibaca saat latihan lisan.', 'bola', 'Baca perlahan dari awal sampai akhir.', 'Latihan membaca kata bola.', 0, 'approved', 900001, '2026-11-20 10:05:00', '2026-11-20 10:01:00', '2026-11-20 10:05:00'),
  (900623, 900001, 900507, 'kalimat', 1, 'oral_reading', 'practice', 'Bacalah kalimat dengan suara jelas.', 'Kalimat untuk latihan membaca lisan.', 'Ibu membaca buku.', 'Baca satu kata demi satu kata.', 'Latihan membaca kalimat sederhana.', 0, 'approved', 900001, '2026-11-20 10:05:00', '2026-11-20 10:02:00', '2026-11-20 10:05:00'),
  (900624, 900001, 900509, 'suku_kata', 1, 'multiple_choice', 'practice', 'Pilih suku kata awal yang cocok dengan petunjuk.', 'Hewan yang suka berenang dan berbunyi kwek-kwek.', NULL, 'Pikirkan nama hewan yang sering berada di dekat air.', 'Kata bebek dimulai dengan suku kata be.', 0, 'approved', 900001, '2026-11-20 10:06:00', '2026-11-20 10:03:00', '2026-11-20 10:06:00'),
  (900625, 900001, 900510, 'kata', 1, 'multiple_choice', 'practice', 'Pilih kata yang sesuai dengan petunjuk.', 'Benda yang dipakai untuk membawa buku ke sekolah.', NULL, 'Bayangkan benda yang dibawa di punggung.', 'Tas adalah benda untuk membawa buku.', 0, 'approved', 900001, '2026-11-20 10:06:00', '2026-11-20 10:04:00', '2026-11-20 10:06:00'),
  (900626, 900001, 900511, 'kalimat', 1, 'multiple_choice', 'practice', 'Pilih kalimat yang sesuai dengan petunjuk.', 'Kegiatan anak merapikan buku ke dalam tas.', NULL, 'Cari kalimat yang menceritakan kegiatan tersebut.', 'Kalimat anak merapikan buku sesuai petunjuk.', 0, 'approved', 900001, '2026-11-20 10:06:00', '2026-11-20 10:05:00', '2026-11-20 10:06:00'),
  (900627, 900001, 900512, 'huruf', 1, 'multiple_choice', 'practice', 'Pilih huruf yang cocok dengan bunyi awal.', 'Bunyi yang terdengar: /p/.', NULL, 'Dengarkan bunyi awalnya.', 'Huruf p mewakili bunyi /p/.', 0, 'approved', 900001, '2026-11-20 10:06:00', '2026-11-20 10:06:00', '2026-11-20 10:06:00');

-- Three plausible distractors per multiple-choice question, one key each.
INSERT IGNORE INTO question_options (id, question_id, position, option_text, is_correct)
WITH option_bank AS (
  SELECT 900601 q, 'b' a, 'd' b, 'm' c, 1 k UNION ALL
  SELECT 900602, 'n', 'm', 'r', 2 UNION ALL
  SELECT 900603, 'a', 'i', 'u', 2 UNION ALL
  SELECT 900604, 'c', 's', 't', 2 UNION ALL
  SELECT 900605, 'ba', 'bi', 'bu', 1 UNION ALL
  SELECT 900606, 'ba', 'bo', 'bu', 2 UNION ALL
  SELECT 900607, 'be', 'bo', 'bu', 3 UNION ALL
  SELECT 900608, 'ba', 'be', 'bo', 2 UNION ALL
  SELECT 900609, 'pi', 'pa', 'pu', 1 UNION ALL
  SELECT 900610, 'baju', 'buku', 'bola', 2 UNION ALL
  SELECT 900611, 'meja', 'kursi', 'lemari', 2 UNION ALL
  SELECT 900612, 'jam', 'tas', 'topi', 1 UNION ALL
  SELECT 900613, 'rumah', 'kelas', 'pasar', 2 UNION ALL
  SELECT 900614, 'Ibu membaca buku.', 'Ibu menutup jendela.', 'Ibu menyapu lantai.', 1 UNION ALL
  SELECT 900615, 'Dina mencuci piring.', 'Dina menanam bunga.', 'Dina membaca koran.', 2 UNION ALL
  SELECT 900616, 'Paman tidur siang.', 'Paman menyiram tanaman pagi hari.', 'Paman membeli sepatu.', 2 UNION ALL
  SELECT 900617, 'Ibu memasak di dapur.', 'Ibu bermain bola.', 'Ibu pergi ke sekolah.', 1 UNION ALL
  SELECT 900618, 'a', 'j', 'm', 1 UNION ALL
  SELECT 900619, 'ka', 'ku', 'ko', 2 UNION ALL
  SELECT 900620, 'gigi', 'mata', 'buku', 1 UNION ALL
  SELECT 900621, 'Pergi anak sekolah ke.', 'Anak-anak pergi ke sekolah.', 'Sekolah anak-anak ke pergi.', 2 UNION ALL
  SELECT 900624, 'ba', 'be', 'bo', 2 UNION ALL
  SELECT 900625, 'tas', 'topi', 'buku', 1 UNION ALL
  SELECT 900626, 'Anak merapikan buku ke dalam tas.', 'Tas buku anak merapikan dalam ke.', 'Buku dalam anak tas merapikan ke.', 1 UNION ALL
  SELECT 900627, 'b', 'p', 'd', 2
), positions AS (
  SELECT 1 AS p UNION ALL SELECT 2 UNION ALL SELECT 3
)
SELECT 900701 + ((o.q - 900601) * 3) + (p.p - 1), o.q, p.p,
       CASE p.p WHEN 1 THEN o.a WHEN 2 THEN o.b ELSE o.c END,
       CASE WHEN p.p = o.k THEN 1 ELSE 0 END
FROM option_bank o CROSS JOIN positions p;

INSERT IGNORE INTO diagnostic_tests
  (id, teacher_id, class_id, title, status, activated_at, created_at, updated_at)
VALUES
  (900801, 900001, 900101, 'Diagnostik awal kelas 1A', 'active', '2026-11-20 10:10:00', '2026-11-20 10:05:00', '2026-11-20 10:10:00'),
  (900802, 900001, 900102, 'Diagnostik awal kelas 2A', 'active', '2026-11-20 10:10:00', '2026-11-20 10:05:00', '2026-11-20 10:10:00'),
  (900803, 900001, 900103, 'Diagnostik awal kelas 3A', 'active', '2026-11-20 10:10:00', '2026-11-20 10:05:00', '2026-11-20 10:10:00');

INSERT IGNORE INTO diagnostic_test_questions (diagnostic_test_id, question_id, position)
SELECT t.id, q.id, ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY q.id)
FROM diagnostic_tests t
CROSS JOIN questions q
WHERE t.id BETWEEN 900801 AND 900803
  AND (q.id BETWEEN 900601 AND 900608 OR q.id BETWEEN 900610 AND 900617)
ORDER BY t.id, q.id;

INSERT IGNORE INTO diagnostic_attempts
  (id, student_id, diagnostic_test_id, class_id, status, started_at, finished_at, created_at, updated_at)
VALUES
  (900901, 900201, 900801, 900101, 'completed', '2026-11-20 10:20:00', '2026-11-20 10:30:00', '2026-11-20 10:20:00', '2026-11-20 10:30:00'),
  (900902, 900202, 900801, 900101, 'completed', '2026-11-20 10:35:00', '2026-11-20 10:46:00', '2026-11-20 10:35:00', '2026-11-20 10:46:00'),
  (900903, 900203, 900802, 900102, 'completed', '2026-11-20 10:20:00', '2026-11-20 10:31:00', '2026-11-20 10:20:00', '2026-11-20 10:31:00'),
  (900904, 900204, 900802, 900102, 'completed', '2026-11-20 10:35:00', '2026-11-20 10:48:00', '2026-11-20 10:35:00', '2026-11-20 10:48:00'),
  (900905, 900205, 900803, 900103, 'completed', '2026-11-20 10:20:00', '2026-11-20 10:33:00', '2026-11-20 10:20:00', '2026-11-20 10:33:00'),
  (900906, 900206, 900803, 900103, 'completed', '2026-11-20 10:35:00', '2026-11-20 10:49:00', '2026-11-20 10:35:00', '2026-11-20 10:49:00');

-- Four questions per aspect produce exact percentage bands in 25-point steps.
INSERT IGNORE INTO diagnostic_attempt_answers
  (id, diagnostic_attempt_id, question_id, aspect_code, level_snapshot, question_type, prompt_snapshot, stimulus_text_snapshot, selected_answer, correct_answer_snapshot, is_correct, score, answered_at)
WITH profiles AS (
  SELECT 900201 student_id, 900901 attempt_id, 900101 class_id, 4 huruf, 1 suku, 0 kata, 0 kalimat UNION ALL
  SELECT 900202, 900902, 900101, 4, 2, 3, 3 UNION ALL
  SELECT 900203, 900903, 900102, 4, 3, 2, 3 UNION ALL
  SELECT 900204, 900904, 900102, 4, 4, 2, 1 UNION ALL
  SELECT 900205, 900905, 900103, 4, 4, 4, 1 UNION ALL
  SELECT 900206, 900906, 900103, 4, 4, 4, 4
), diag_questions AS (
  SELECT q.*,
         ROW_NUMBER() OVER (PARTITION BY q.aspect_code ORDER BY q.id) AS aspect_position,
         ROW_NUMBER() OVER (ORDER BY q.id) AS test_position
  FROM questions q
  WHERE q.id BETWEEN 900601 AND 900608 OR q.id BETWEEN 900610 AND 900617
), scored AS (
  SELECT p.*, q.id question_id, q.aspect_code, q.level, q.question_type, q.prompt, q.stimulus_text, q.aspect_position, q.test_position,
         CASE q.aspect_code WHEN 'huruf' THEN p.huruf WHEN 'suku_kata' THEN p.suku WHEN 'kata' THEN p.kata ELSE p.kalimat END AS correct_count
  FROM profiles p CROSS JOIN diag_questions q
)
SELECT 901001 + ((s.student_id - 900201) * 100) + (s.question_id - 900601),
       s.attempt_id, s.question_id, s.aspect_code, s.level, s.question_type, s.prompt, s.stimulus_text,
       CASE WHEN s.aspect_position <= s.correct_count THEN correct_option.option_text ELSE wrong_option.option_text END,
       correct_option.option_text, (s.aspect_position <= s.correct_count),
       CASE WHEN s.aspect_position <= s.correct_count THEN 100 ELSE 0 END,
       DATE_ADD('2026-11-20 10:20:00', INTERVAL (
         CASE WHEN s.student_id IN (900202, 900204, 900206) THEN 15 ELSE 0 END
         + FLOOR((s.test_position - 1) * 9 / 15)
       ) MINUTE)
FROM scored s
JOIN question_options correct_option ON correct_option.question_id = s.question_id AND correct_option.is_correct = 1
JOIN question_options wrong_option ON wrong_option.question_id = s.question_id
  AND wrong_option.position = (
    SELECT MIN(other_option.position) FROM question_options other_option
    WHERE other_option.question_id = s.question_id AND other_option.is_correct = 0
  );

INSERT IGNORE INTO diagnostic_answer_options
  (id, diagnostic_answer_id, position, option_text_snapshot, option_asset_key_snapshot, is_correct_snapshot)
SELECT 902001 + ((a.id - 901001) * 3) + o.position - 1,
       a.id, o.position, o.option_text, o.option_asset_key, o.is_correct
FROM diagnostic_attempt_answers a
JOIN question_options o ON o.question_id = a.question_id
WHERE a.id BETWEEN 901001 AND 901616;

UPDATE diagnostic_attempts a
JOIN (
  SELECT diagnostic_attempt_id, ROUND(AVG(score), 2) overall_score
  FROM diagnostic_attempt_answers WHERE id BETWEEN 901001 AND 901616
  GROUP BY diagnostic_attempt_id
) scores ON scores.diagnostic_attempt_id = a.id
SET a.overall_score = scores.overall_score
WHERE a.id BETWEEN 900901 AND 900906;

INSERT IGNORE INTO mastery_history
  (id, student_id, class_id, aspect_code, observed_level, target_aspect_code, target_level, score, mastery_status, needs_teacher_support, source_type, diagnostic_attempt_id, reason, recorded_at)
SELECT 905001 + ((a.id - 900901) * 10) + la.sequence_no,
       a.student_id, a.class_id, ans.aspect_code, 1, NULL, NULL, ROUND(AVG(ans.score), 2),
       CASE WHEN AVG(ans.score) >= 80 THEN 'mastered' WHEN AVG(ans.score) >= 60 THEN 'practicing' ELSE 'not_mastered' END,
       0, 'diagnostic', a.id,
       CONCAT('Hasil diagnostik demo: ', ROUND(AVG(ans.score), 2), ' pada aspek ', la.label, '.'),
       a.finished_at
FROM diagnostic_attempts a
JOIN diagnostic_attempt_answers ans ON ans.diagnostic_attempt_id = a.id
JOIN learning_aspects la ON la.code = ans.aspect_code
WHERE a.id BETWEEN 900901 AND 900906
GROUP BY a.id, a.student_id, a.class_id, ans.aspect_code, la.sequence_no, la.label, a.finished_at;

-- Initial recommendation: first aspect in prerequisite order below 80.
INSERT IGNORE INTO recommendations
  (id, student_id, class_id, material_id, aspect_code, target_level, source, reason, status, created_at)
SELECT 903001 + (s.id - 900201), s.id, s.current_class_id, m.id, m.aspect_code, m.level, 'system',
       CONCAT('Aspek pertama yang belum mencapai 80 adalah ', la.label, '; materi aktif tingkat ', m.level, '.'),
       'active', '2026-11-20 11:00:00'
FROM students s
JOIN (
  SELECT mh.student_id, MIN(la.sequence_no) sequence_no
  FROM mastery_history mh JOIN learning_aspects la ON la.code = mh.aspect_code
  WHERE mh.diagnostic_attempt_id BETWEEN 900901 AND 900906 AND mh.score < 80
  GROUP BY mh.student_id
) first_gap ON first_gap.student_id = s.id
JOIN learning_aspects la ON la.sequence_no = first_gap.sequence_no
JOIN materials m ON m.id = (
  SELECT MIN(candidate.id) FROM materials candidate
  WHERE candidate.aspect_code = la.code AND candidate.level = 1 AND candidate.status = 'active'
)
WHERE s.id BETWEEN 900201 AND 900206;

INSERT IGNORE INTO practice_attempts
  (id, student_id, class_id, material_id, recommendation_id, material_title_snapshot, aspect_code, level_snapshot, attempt_number, status, score, correct_count, question_count, completion_token, started_at, finished_at, created_at, updated_at)
VALUES
  (904001, 900201, 900101, 900503, 903001, 'Suku kata ba bi bu be bo', 'suku_kata', 1, 1, 'completed', 40, 2, 5, 'demo-practice-andi-01', '2026-11-21 09:00:00', '2026-11-21 09:08:00', '2026-11-21 09:00:00', '2026-11-21 09:08:00'),
  (904002, 900202, 900101, 900503, 903002, 'Suku kata ba bi bu be bo', 'suku_kata', 1, 1, 'completed', 60, 3, 5, 'demo-practice-siti-01', '2026-11-21 09:10:00', '2026-11-21 09:18:00', '2026-11-21 09:10:00', '2026-11-21 09:18:00'),
  (904003, 900203, 900102, 900503, 903003, 'Suku kata ba bi bu be bo', 'suku_kata', 1, 1, 'completed', 80, 4, 5, 'demo-practice-bunga-01', '2026-11-21 09:20:00', '2026-11-21 09:27:00', '2026-11-21 09:20:00', '2026-11-21 09:27:00'),
  (904004, 900204, 900102, 900505, 903004, 'Kata di sekitar kita', 'kata', 1, 1, 'completed', 100, 4, 4, 'demo-practice-dimas-01', '2026-11-21 09:30:00', '2026-11-21 09:38:00', '2026-11-21 09:30:00', '2026-11-21 09:38:00'),
  (904005, 900205, 900103, 900507, 903005, 'Kalimat sederhana', 'kalimat', 1, 1, 'completed', 100, 4, 4, 'demo-practice-raka-01', '2026-11-21 09:40:00', '2026-11-21 09:49:00', '2026-11-21 09:40:00', '2026-11-21 09:49:00'),
  (904006, 900201, 900101, 900505, NULL, 'Kata di sekitar kita', 'kata', 1, 1, 'completed', 70, NULL, NULL, 'demo-practice-andi-oral-01', '2026-11-20 11:10:00', '2026-11-20 12:00:00', '2026-11-20 11:10:00', '2026-11-20 12:00:00'),
  (904007, 900202, 900101, 900507, NULL, 'Kalimat sederhana', 'kalimat', 1, 1, 'completed', 60, NULL, NULL, 'demo-practice-siti-oral-01', '2026-11-20 11:15:00', '2026-11-20 12:05:00', '2026-11-20 11:15:00', '2026-11-20 12:05:00');

INSERT IGNORE INTO practice_attempt_answers
  (id, practice_attempt_id, question_id, aspect_code, level_snapshot, question_type, prompt_snapshot, stimulus_text_snapshot, selected_answer, correct_answer_snapshot, is_correct, score, answered_at)
WITH profiles AS (
  SELECT 904001 attempt_id, 900201 student_id, 900503 material_id, 2 correct_count UNION ALL
  SELECT 904002, 900202, 900503, 3 UNION ALL
  SELECT 904003, 900203, 900503, 4 UNION ALL
  SELECT 904004, 900204, 900505, 4 UNION ALL
  SELECT 904005, 900205, 900507, 4
), ordered_questions AS (
  SELECT q.*, ROW_NUMBER() OVER (PARTITION BY q.material_id ORDER BY q.id) AS item_no
  FROM questions q WHERE q.id BETWEEN 900605 AND 900617
)
SELECT 906001 + ((p.attempt_id - 904001) * 100) + (q.id - 900605),
       p.attempt_id, q.id, q.aspect_code, q.level, q.question_type, q.prompt, q.stimulus_text,
       CASE WHEN q.item_no <= p.correct_count THEN correct_option.option_text ELSE wrong_option.option_text END,
       correct_option.option_text, (q.item_no <= p.correct_count),
       CASE WHEN q.item_no <= p.correct_count THEN 100 ELSE 0 END,
       DATE_ADD('2026-11-21 09:00:00', INTERVAL ((p.attempt_id - 904001) * 10 + q.item_no) MINUTE)
FROM profiles p JOIN ordered_questions q ON q.material_id = p.material_id
JOIN question_options correct_option ON correct_option.question_id = q.id AND correct_option.is_correct = 1
JOIN question_options wrong_option ON wrong_option.question_id = q.id
  AND wrong_option.position = (
    SELECT MIN(other_option.position) FROM question_options other_option
    WHERE other_option.question_id = q.id AND other_option.is_correct = 0
  );

INSERT IGNORE INTO practice_attempt_answers
  (id, practice_attempt_id, question_id, aspect_code, level_snapshot, question_type, prompt_snapshot, stimulus_text_snapshot, target_text_snapshot, correct_answer_snapshot, is_correct, score, answered_at)
VALUES
  (906501, 904006, 900622, 'kata', 1, 'oral_reading', 'Bacalah kata dengan suara jelas.', 'Kata untuk dibaca saat latihan lisan.', 'bola', 'bola', 1, 70, '2026-11-20 12:00:00'),
  (906502, 904007, 900623, 'kalimat', 1, 'oral_reading', 'Bacalah kalimat dengan suara jelas.', 'Kalimat untuk latihan membaca lisan.', 'Ibu membaca buku.', 'Ibu membaca buku.', 0, 60, '2026-11-20 12:05:00');

INSERT IGNORE INTO practice_answer_options
  (id, practice_answer_id, position, option_text_snapshot, option_asset_key_snapshot, is_correct_snapshot)
SELECT 907001 + ((a.id - 906001) * 3) + o.position - 1,
       a.id, o.position, o.option_text, o.option_asset_key, o.is_correct
FROM practice_attempt_answers a
JOIN question_options o ON o.question_id = a.question_id
WHERE a.id BETWEEN 906001 AND 906513;

INSERT IGNORE INTO mastery_history
  (id, student_id, class_id, aspect_code, observed_level, target_aspect_code, target_level, score, mastery_status, needs_teacher_support, source_type, practice_attempt_id, reason, recorded_at)
SELECT 905101 + (p.id - 904001), p.student_id, p.class_id, p.aspect_code, p.level_snapshot,
       p.aspect_code, p.level_snapshot, p.score,
       CASE WHEN p.score < 60 THEN 'not_mastered' ELSE 'practicing' END, 0, 'practice', p.id,
       CASE WHEN p.score < 60 THEN 'Skor di bawah 60: ulangi materi yang sama.'
            WHEN p.score < 80 THEN 'Skor 60-79: penguatan dengan materi lain pada tingkat yang sama.'
            ELSE 'Satu hasil minimal 80: variasi materi pada tingkat yang sama; belum naik tingkat.' END,
       p.finished_at
FROM practice_attempts p WHERE p.id BETWEEN 904001 AND 904005;

-- Close the recommendation consumed by each completed attempt and add exactly
-- one current recommendation per learner, following the score rules in BRD §11.2.
UPDATE recommendations r
JOIN practice_attempts p ON p.recommendation_id = r.id
SET r.status = 'completed', r.completed_by_practice_attempt_id = p.id,
    r.closed_at = p.finished_at
WHERE r.id BETWEEN 903001 AND 903005 AND p.id BETWEEN 904001 AND 904005;

INSERT IGNORE INTO recommendations
  (id, student_id, class_id, material_id, aspect_code, target_level, source, reason, created_by_teacher_id, status, created_at)
VALUES
  (903101, 900201, 900101, 900503, 'suku_kata', 1, 'system', 'Skor latihan 40: ulangi materi yang sama pada tingkat 1.', NULL, 'active', '2026-11-21 10:00:00'),
  (903102, 900202, 900101, 900509, 'suku_kata', 1, 'system', 'Skor latihan 60: penguatan pada tingkat yang sama dengan materi variasi.', NULL, 'active', '2026-11-21 10:00:00'),
  (903103, 900203, 900102, 900509, 'suku_kata', 1, 'system', 'Satu skor latihan 80: materi variasi pada tingkat yang sama; menunggu skor latihan berikutnya untuk kenaikan.', NULL, 'active', '2026-11-21 10:00:00'),
  (903104, 900204, 900102, 900510, 'kata', 1, 'system', 'Satu skor latihan 100: materi variasi pada tingkat yang sama; menunggu skor latihan berikutnya untuk kenaikan.', NULL, 'active', '2026-11-21 10:00:00'),
  (903105, 900205, 900103, 900511, 'kalimat', 1, 'system', 'Satu skor latihan 100: materi variasi pada tingkat yang sama; menunggu skor latihan berikutnya untuk kenaikan.', NULL, 'active', '2026-11-21 10:00:00'),
  (903106, 900206, 900103, 900508, 'kalimat', 2, 'teacher', 'Override demo oleh Guru untuk pengayaan setelah hasil diagnostik mencapai 100 pada semua aspek.', 900001, 'active', '2026-11-21 10:00:00');

-- Simulated recording metadata only: no audio file is included, so paths stay
-- NULL. Retention dates are examples; the sample records have teacher scores.
INSERT IGNORE INTO voice_recordings
  (id, student_id, question_id, diagnostic_attempt_id, practice_attempt_id, target_text_snapshot, storage_disk, private_storage_path, mime_type, size_bytes, duration_seconds, parent_consent_snapshot, ai_consent_snapshot, status, submitted_at, delete_after, file_deleted_at, created_at, updated_at)
VALUES
  (908001, 900201, 900622, NULL, 904006, 'bola', 'private', NULL, 'audio/mp4', 182340, 6, 1, 1, 'evaluated', '2026-11-20 11:20:00', '2027-02-18', NULL, '2026-11-20 11:20:00', '2026-11-20 12:00:00'),
  (908002, 900202, 900623, NULL, 904007, 'Ibu membaca buku.', 'private', NULL, 'audio/mp4', 305120, 9, 1, 0, 'evaluated', '2026-11-20 11:25:00', '2027-02-18', NULL, '2026-11-20 11:25:00', '2026-11-20 12:05:00');

INSERT IGNORE INTO audio_evaluations
  (id, recording_id, teacher_id, accuracy_score, fluency_score, comment, advice, evaluated_at, created_at, updated_at)
VALUES
  (908101, 908001, 900001, 75, 65, 'Contoh evaluasi simulasi. Bacaan cukup tepat.', 'Latih membaca kata tanpa terburu-buru.', '2026-11-20 12:00:00', '2026-11-20 12:00:00', '2026-11-20 12:00:00'),
  (908102, 908002, 900001, 60, 60, 'Contoh evaluasi simulasi. Perlu latihan kelancaran.', 'Baca kalimat pendek kata demi kata.', '2026-11-20 12:05:00', '2026-11-20 12:05:00', '2026-11-20 12:05:00');

INSERT IGNORE INTO audio_evaluation_revisions
  (id, evaluation_id, revision_no, teacher_id, accuracy_score, fluency_score, comment, advice, revised_at)
VALUES
  (908201, 908101, 1, 900001, 75, 65, 'Contoh evaluasi simulasi. Bacaan cukup tepat.', 'Latih membaca kata tanpa terburu-buru.', '2026-11-20 12:00:00'),
  (908202, 908102, 1, 900001, 60, 60, 'Contoh evaluasi simulasi. Perlu latihan kelancaran.', 'Baca kalimat pendek kata demi kata.', '2026-11-20 12:05:00');

INSERT IGNORE INTO mastery_history
  (id, student_id, class_id, aspect_code, observed_level, target_aspect_code, target_level, score, mastery_status, needs_teacher_support, source_type, audio_evaluation_revision_id, reason, recorded_at)
VALUES
  (905201, 900201, 900101, 'kata', 1, 'kata', 1, 70, 'practicing', 0, 'audio_evaluation', 908201, 'Nilai Guru simulasi: rata-rata ketepatan 75 dan kelancaran 65 = 70.', '2026-11-20 12:00:00'),
  (905202, 900202, 900101, 'kalimat', 1, 'kalimat', 1, 60, 'practicing', 0, 'audio_evaluation', 908202, 'Nilai Guru simulasi: rata-rata ketepatan 60 dan kelancaran 60 = 60.', '2026-11-20 12:05:00');

COMMIT;

