-- Only for an existing BacaTepat development seed.
START TRANSACTION;
UPDATE users SET username = 'burina', password_hash = CASE WHEN password_hash = '$2y$10$VHAybfj1VylQOnlwIuoPgeAh/QdTexk.q8jynPIR5GL0sJQmwESx6' THEN '$2y$10$Oh8sGV9OZo//pNyM3SyFU./x.keG5DMBg/x5gw.DeWyyUSKWzhY2a' ELSE password_hash END WHERE id = 900001 AND username = 'demo.guru.rina';
UPDATE users SET username = 'andi', password_hash = CASE WHEN password_hash = '$2y$10$VHAybfj1VylQOnlwIuoPgeAh/QdTexk.q8jynPIR5GL0sJQmwESx6' THEN '$2y$10$hUy4Y2ET7XU5AM4rioZbbugYzX85t.lm6K4XCne7kwBWwsHNBAFAO' ELSE password_hash END WHERE id = 900002 AND username = 'demo.siswa.andi';
UPDATE users SET username = 'siti', password_hash = CASE WHEN password_hash = '$2y$10$VHAybfj1VylQOnlwIuoPgeAh/QdTexk.q8jynPIR5GL0sJQmwESx6' THEN '$2y$10$MFz9EHlN6iR9kdg2HM9PyeWNF9V/o6yYVKhKY27gTKvfDaBr8tg0u' ELSE password_hash END WHERE id = 900003 AND username = 'demo.siswa.siti';
UPDATE users SET username = 'bunga', password_hash = CASE WHEN password_hash = '$2y$10$VHAybfj1VylQOnlwIuoPgeAh/QdTexk.q8jynPIR5GL0sJQmwESx6' THEN '$2y$10$gntEUO/tr3gVL7A9sQQDm.aKXhhYVn1uD7Kxqoxgs/UW5C5B2i7ey' ELSE password_hash END WHERE id = 900004 AND username = 'demo.siswa.bunga';
UPDATE users SET username = 'dimas', password_hash = CASE WHEN password_hash = '$2y$10$VHAybfj1VylQOnlwIuoPgeAh/QdTexk.q8jynPIR5GL0sJQmwESx6' THEN '$2y$10$dLDogXw5UNN.vgkQvRWDC.HfXXYeBgKsrycH3IbU.oWlvBXICnwFW' ELSE password_hash END WHERE id = 900005 AND username = 'demo.siswa.dimas';
UPDATE users SET username = 'raka', password_hash = CASE WHEN password_hash = '$2y$10$VHAybfj1VylQOnlwIuoPgeAh/QdTexk.q8jynPIR5GL0sJQmwESx6' THEN '$2y$10$rFNlbPWeyjEuAwV.RdAkku5o1y7xeLSOtKkkhhI/peighIfGNTO0y' ELSE password_hash END WHERE id = 900006 AND username = 'demo.siswa.raka';
UPDATE users SET username = 'lina', password_hash = CASE WHEN password_hash = '$2y$10$VHAybfj1VylQOnlwIuoPgeAh/QdTexk.q8jynPIR5GL0sJQmwESx6' THEN '$2y$10$0RZGXgX/BUmDjtREzJDyiOs3IGlfTTI66CdJ2zTWFGjfWmrgscOcG' ELSE password_hash END WHERE id = 900007 AND username = 'demo.siswa.lina';
INSERT IGNORE INTO materials (id, teacher_id, aspect_code, level, title, content, ai_generated, status, created_at, updated_at) VALUES
(900513, 900001, 'suku_kata', 1, 'Kelas 1 · Bunyi Apa?', '“Itu bola Boni. Bola Boni biru. Bola kena batu.” Baca bersama gurumu. Apa warna bola Boni?
Sumber: Kutipan dari Bahasa Indonesia Aku Bisa!, Bab 1, Pusat Perbukuan. Buku audio: https://buku.kemendikdasmen.go.id/katalog/buku-audio-bahasa-indonesia-aku-bisa-untuk-sd-mi-kelas-i-edisi-revisi', 0, 'active', NOW(), NOW()),
(900514, 900001, 'kata', 1, 'Kelas 2 · Mengenal Perasaan', '“Bagaimana perasaanmu saat bertemu guru dan teman-temanmu di sekolah hari ini?” Pilih satu kata: senang, sedih, atau takut.
Sumber: Kutipan dari Bahasa Indonesia Keluargaku Unik, Bab 1. Buku siswa: https://static-sc.cloudapp.web.id/content/pdf/bukuteks/kurikulum21/Indonesia_BS_KLS_II_Rev.pdf', 0, 'active', NOW(), NOW()),
(900515, 900001, 'kalimat', 2, 'Kelas 3 · Ayo, Main!', 'Sebutkan permainan kesukaanmu. Jelaskan cara bermain kepada temanmu. Minta ia mencoba mengikuti petunjukmu.
Sumber: Adaptasi dari Bahasa Indonesia Kawan Seiring, Bab I, Pusat Perbukuan (2022). Katalog: https://buku.kemendikdasmen.go.id/', 0, 'active', NOW(), NOW());
COMMIT;
