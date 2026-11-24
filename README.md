# BACATEPAT

Aplikasi pembelajaran membaca permulaan untuk siswa SD kelas 1–3.

| Folder | Isi |
| --- | --- |
| [`api/`](api/) | Lokasi proyek REST API Laravel. Saat ini berisi skema MySQL, data demo, dan panduan impor di [`api/database/sql/`](api/database/sql/README_DATABASE.md). |
| [`mobile/`](mobile/) | Aplikasi Flutter untuk Siswa dan Guru. |
| [`web/`](web/) | Folder frontend website Guru. |

Folder `api/database/migrations/` dan `api/database/seeders/` disiapkan untuk migrasi dan seeder Laravel. Flutter dan website Guru dirancang untuk memakai API Laravel yang sama melalui `/api/v1`.
