<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class AuthController
{
    public function login(Request $request)
    {
        $data = $request->validate([
            'username' => 'required|string|max:50',
            'password' => 'required|string|min:8|max:255',
            'device_name' => 'required|string|max:100',
            'role' => 'sometimes|in:guru,siswa',
        ]);
        $user = User::where('username', $data['username'])->first();
        abort_unless($user && Hash::check($data['password'], $user->password_hash), 401, 'Nama pengguna atau kata sandi salah.');
        abort_if(isset($data['role']) && $user->role !== $data['role'], 403, 'Peran akun tidak sesuai.');
        abort_unless($user->status === 'aktif', 403, 'Akun nonaktif.');

        return DB::transaction(function () use ($user, $data) {
            $user->forceFill(['last_login_at' => now()])->save();
            $token = $user->createToken($data['device_name'], ['*'], now()->addDays(30));

            return ['success' => true, 'data' => ['token' => $token->plainTextToken, 'user' => $this->profile($user)]];
        });
    }

    public function me(Request $request)
    {
        abort_unless($request->user()->status === 'aktif', 403);

        return ['success' => true, 'data' => $this->profile($request->user())];
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return ['success' => true];
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $data = $request->validate(['retensi_audio_hari' => 'sometimes|integer|between:1,180', 'nama' => 'required|string|max:100', 'email' => ['nullable', 'email', 'max:100', Rule::unique('users')->ignore($user->id)]]);
        $user->forceFill(['name' => $data['nama'], 'email' => $data['email'] ?? $user->email, 'audio_retention_days' => $data['retensi_audio_hari'] ?? $user->audio_retention_days])->save();

        return ['data' => $this->profile($user)];
    }

    public function password(Request $request)
    {
        $data = $request->validate(['password_lama' => 'required|string', 'password_baru' => 'required|string|min:8|max:72|different:password_lama']);
        $user = $request->user();
        if (! Hash::check($data['password_lama'], $user->password_hash)) {
            throw ValidationException::withMessages(['password_lama' => 'Kata sandi lama salah.']);
        }
        DB::transaction(function () use ($user, $data) {
            $user->forceFill(['password_hash' => Hash::make($data['password_baru'])])->save();
            $user->tokens()->where('id', '!=', $user->currentAccessToken()->id)->delete();
        });

        return ['success' => true];
    }

    private function profile(User $user): array
    {
        $profile = ['id' => $user->id, 'nama' => $user->name, 'role' => $user->role];
        if ($user->role === 'guru') {
            $profile += ['email' => $user->email, 'retensi_audio_hari' => $user->audio_retention_days];
        }
        if ($user->role === 'siswa') {
            $student = DB::table('students')->join('classes', 'classes.id', '=', 'students.current_class_id')
                ->where('students.user_id', $user->id)->where('students.status', 'aktif')
                ->first(['students.id as siswa_id', 'classes.name as kelas']);
            abort_unless($student, 403);
            $profile += (array) $student;
        }

        return $profile;
    }
}
