<?php

use App\Database\SqlBootstrap;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        SqlBootstrap::run('bacatepat_database.sql');
    }

    public function down(): void
    {
        throw new RuntimeException('Skema dasar berisi riwayat siswa. Pulihkan database dari backup untuk membatalkannya.');
    }
};
