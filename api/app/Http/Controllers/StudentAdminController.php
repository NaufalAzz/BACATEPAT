<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class StudentAdminController
{
    private function owned(Request $request, int $id)
    {
        return DB::table('students as s')->join('classes as c', 'c.id', '=', 's.current_class_id')
            ->where('s.id', $id)->where('c.teacher_id', $request->user()->id)->lockForUpdate()->firstOrFail(['s.*']);
    }

    private function ownedClass(Request $request, int $id)
    {
        return DB::table('classes')->where('id', $id)->where('teacher_id', $request->user()->id)
            ->where('status', 'aktif')->lockForUpdate()->firstOrFail();
    }

    public function create(Request $request)
    {
        $data = $request->validate(['nama' => 'required|string|max:100', 'username' => 'required|string|max:50|unique:users',
            'password' => 'required|string|min:8|max:72', 'kelas_id' => 'required|integer', 'nis' => 'nullable|string|max:20|unique:students,student_number', 'nama_wali' => 'required|string|max:100']);
        try {
            return DB::transaction(function () use ($request, $data) {
                $class = $this->ownedClass($request, $data['kelas_id']);
                $user = DB::table('users')->insertGetId(['name' => $data['nama'], 'username' => $data['username'],
                    'password_hash' => Hash::make($data['password']), 'role' => 'siswa']);
                $student = DB::table('students')->insertGetId(['user_id' => $user, 'current_class_id' => $class->id,
                    'guardian_name' => $data['nama_wali'], 'student_number' => $data['nis'] ?? null]);
                $this->addMembership($student, $class->id, $request->user()->id);

                return response()->json(['data' => ['siswa_id' => $student, 'user_id' => $user, 'nama' => $data['nama'], 'kelas' => $class->name]], 201);
            });
        } catch (UniqueConstraintViolationException) {
            abort(422, 'Nama pengguna atau NIS sudah dipakai.');
        }
    }

    public function detail(Request $request, int $id)
    {
        $student = $this->owned($request, $id);
        $user = DB::table('users')->where('id', $student->user_id)->first(['name as nama', 'username']);

        return ['data' => (array) $student + (array) $user];
    }

    public function edit(Request $request, int $id)
    {
        $data = $request->validate(['nama' => 'required|string|max:100', 'username' => 'required|string|max:50',
            'nama_wali' => 'required|string|max:100', 'nis' => 'nullable|string|max:20']);
        try {
            return DB::transaction(function () use ($request, $id, $data) {
                $student = $this->owned($request, $id);
                DB::table('users')->where('id', $student->user_id)->update(['name' => $data['nama'], 'username' => $data['username']]);
                $profile = ['guardian_name' => $data['nama_wali'], 'student_number' => $data['nis'] ?? $student->student_number];
                if ($student->guardian_name !== $data['nama_wali']) {
                    $profile += ['parent_consent' => false, 'ai_consent' => false, 'consent_recorded_at' => now()];
                    DB::table('student_consent_events')->insert(['student_id' => $id, 'guardian_name_snapshot' => $data['nama_wali'],
                        'parent_consent' => false, 'ai_consent' => false, 'recorded_at' => now(), 'recorded_by_teacher_id' => $request->user()->id]);
                }
                DB::table('students')->where('id', $id)->update($profile);

                return ['success' => true];
            });
        } catch (UniqueConstraintViolationException) {
            abort(422, 'Username atau NIS sudah dipakai.');
        }
    }

    public function resetPassword(Request $request, int $id)
    {
        $data = $request->validate(['password_baru' => 'required|string|min:8|max:72']);

        return DB::transaction(function () use ($request, $id, $data) {
            $student = $this->owned($request, $id);
            $user = User::findOrFail($student->user_id);
            $user->forceFill(['password_hash' => Hash::make($data['password_baru'])])->save();
            $user->tokens()->delete();

            return ['success' => true];
        });
    }

    private function addMembership(int $student, int $class, int $teacher): void
    {
        DB::table('student_class_memberships')->insert(['student_id' => $student, 'class_id' => $class,
            'started_at' => now(), 'recorded_by_teacher_id' => $teacher]);
    }

    public function transfer(Request $request, int $id)
    {
        $data = $request->validate(['kelas_id' => 'required|integer']);

        return DB::transaction(function () use ($request, $data, $id) {
            $student = $this->owned($request, $id);
            $class = $this->ownedClass($request, $data['kelas_id']);
            if ($student->current_class_id !== $class->id) {
                DB::table('student_class_memberships')->where('student_id', $id)->whereNull('ended_at')->update(['ended_at' => now()]);
                $this->addMembership($id, $class->id, $request->user()->id);
                DB::table('students')->where('id', $id)->update(['current_class_id' => $class->id]);
            }

            return ['success' => true];
        });
    }

    public function consent(Request $request, int $id)
    {
        $data = $request->validate(['persetujuan_wali' => 'required|boolean', 'persetujuan_ai' => 'required|boolean']);
        abort_if($data['persetujuan_ai'] && ! $data['persetujuan_wali'], 422, 'Izin AI memerlukan persetujuan wali.');

        return DB::transaction(function () use ($request, $data, $id) {
            $student = $this->owned($request, $id);
            $flags = ['parent_consent' => $data['persetujuan_wali'], 'ai_consent' => $data['persetujuan_ai']];
            DB::table('students')->where('id', $id)->update($flags + ['consent_recorded_at' => now()]);
            DB::table('student_consent_events')->insert($flags + ['student_id' => $id, 'recorded_by_teacher_id' => $request->user()->id,
                'recorded_at' => now(), 'guardian_name_snapshot' => $student->guardian_name]);

            return ['success' => true];
        });
    }

    public function status(Request $request, int $id)
    {
        $data = $request->validate(['aktif' => 'required|boolean']);

        return DB::transaction(function () use ($request, $data, $id) {
            $student = $this->owned($request, $id);
            $status = $data['aktif'] ? 'aktif' : 'nonaktif';
            DB::table('students')->where('id', $id)->update(['status' => $status]);
            $user = User::findOrFail($student->user_id);
            $user->forceFill(['status' => $status])->save();
            if (! $data['aktif']) {
                $user->tokens()->delete();
            }

            return ['success' => true];
        });
    }
}
