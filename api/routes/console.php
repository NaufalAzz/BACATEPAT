<?php

use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schedule;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

Artisan::command('rekaman:retensi', function () {
    DB::table('voice_recordings')->whereNotNull('private_storage_path')
        ->whereDate('delete_after', '<=', today())->chunkById(100, function ($records) {
            foreach ($records as $record) {
                DB::transaction(function () use ($record) {
                    $query = DB::table('voice_recordings')->where('id', $record->id)
                        ->whereDate('delete_after', '<=', today())->whereNotNull('private_storage_path');
                    $row = $query->lockForUpdate()->first();
                    if (! $row) {
                        return;
                    }
                    $disk = Storage::disk('local');
                    if ($disk->exists($row->private_storage_path) && ! $disk->delete($row->private_storage_path)) {
                        throw new RuntimeException('Penghapusan file rekaman gagal.');
                    }
                    $query->update(['private_storage_path' => null, 'status' => 'file_deleted', 'file_deleted_at' => now()]);
                });
            }
        });
})->purpose('Hapus berkas audio privat yang melewati tanggal retensi.');

Schedule::command('rekaman:retensi')->daily()->withoutOverlapping();

Artisan::command('guru:buat {username} {nama}', function () {
    $password = $this->secret('Kata sandi awal (minimal 8 karakter)');
    $input = ['username' => $this->argument('username'), 'name' => $this->argument('nama'), 'password' => $password];
    $validator = Validator::make($input, [
        'username' => 'required|string|max:50|unique:users', 'name' => 'required|string|max:100', 'password' => 'required|string|min:8|max:72',
    ]);
    if ($validator->fails()) {
        $this->error($validator->errors()->first());

        return 1;
    }
    if ($password !== $this->secret('Ulangi kata sandi awal')) {
        $this->error('Kata sandi berbeda.');

        return 1;
    }
    DB::table('users')->insert(['username' => $input['username'], 'name' => $input['name'], 'role' => 'guru',
        'password_hash' => Hash::make($password)]);
    $this->info('Akun guru dibuat.');

    return 0;
})->purpose('Buat akun guru melalui terminal server.');

Artisan::command('materi:kurikulum {username}', function () {
    $catalog = json_decode(file_get_contents(resource_path('materi-kurikulum.json')), true, flags: JSON_THROW_ON_ERROR);
    return DB::transaction(function () use ($catalog) {
        $teacher = DB::table('users')->where('username', $this->argument('username'))
            ->where('role', 'guru')->lockForUpdate()->first();
        if (! $teacher) {
            $this->error('Akun guru tidak ditemukan.');
            return 1;
        }
        $added = 0;
        foreach ($catalog as $material) {
            if (DB::table('materials')->where('teacher_id', $teacher->id)->where('title', $material['title'])->exists()) {
                continue;
            }
            DB::table('materials')->insert($material + ['teacher_id' => $teacher->id,
                'status' => 'active', 'ai_generated' => false, 'created_at' => now(), 'updated_at' => now()]);
            $added++;
        }
        $this->info("Materi ditambahkan: {$added}.");
        return 0;
    });
})->purpose('Tambahkan bacaan Bahasa Indonesia kelas 1–3 ke katalog guru.');
