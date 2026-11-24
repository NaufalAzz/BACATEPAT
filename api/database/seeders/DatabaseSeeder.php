<?php

namespace Database\Seeders;

use App\Database\SqlBootstrap;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        if (! app()->environment(['local', 'testing'])) {
            throw new RuntimeException('Akun demo hanya untuk database pengembangan atau pengujian.');
        }
        if (DB::table('users')->exists()) {
            throw new RuntimeException('Gunakan database pengembangan kosong untuk mengimpor akun demo.');
        }
        SqlBootstrap::run('bacatepat_demo_seed.sql');
    }
}
