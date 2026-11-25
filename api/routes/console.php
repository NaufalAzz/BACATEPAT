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
