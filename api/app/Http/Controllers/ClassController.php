<?php

namespace App\Http\Controllers;

use Illuminate\Database\QueryException;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ClassController
{
    private function owned(Request $request)
    {
        return DB::table('classes')->where('teacher_id', $request->user()->id);
    }

    public function index(Request $request)
    {
        return ['data' => $this->owned($request)->orderBy('name')->select(['id', 'name as nama_kelas', 'grade as tingkat', 'school_year as tahun_ajaran'])->selectSub(DB::table('students')->whereColumn('current_class_id', 'classes.id')->where('status', 'aktif')->selectRaw('COUNT(*)'), 'jumlah_siswa')->get()];
    }

    public function save(Request $request, ?int $id = null)
    {
        $data = $request->validate(['nama_kelas' => 'required|string|max:30', 'tingkat' => 'required|integer|between:1,3', 'tahun_ajaran' => ['required', 'regex:/^\d{4}\/\d{4}$/']]);
        $values = ['name' => $data['nama_kelas'], 'grade' => $data['tingkat'], 'school_year' => $data['tahun_ajaran']];
        $create = $id === null;
        try {
            if ($create) {
                $id = DB::table('classes')->insertGetId($values + ['teacher_id' => $request->user()->id]);
            } else {
                $owned = $this->owned($request)->where('id', $id);
                abort_unless($owned->exists(), 404);
                $owned->update($values);
            }
        } catch (UniqueConstraintViolationException) {
            abort(422, 'Nama kelas sudah dipakai pada tahun ajaran ini.');
        }

        return response()->json(['data' => ['id' => $id] + $data], $create ? 201 : 200);
    }

    public function destroy(Request $request, int $id)
    {
        try {
            abort_unless($this->owned($request)->where('id', $id)->delete(), 404);
        } catch (QueryException $error) {
            if (($error->errorInfo[1] ?? 0) !== 1451) {
                throw $error;
            }
            abort(409, 'Kelas memiliki siswa atau riwayat pembelajaran.');
        }

        return ['success' => true];
    }

    public function students(Request $request)
    {
        $data = $request->validate(['kelas_id' => 'sometimes|integer', 'q' => 'nullable|string|max:100']);
        $query = DB::table('students as s')->join('classes as c', 'c.id', '=', 's.current_class_id')
            ->join('users as u', 'u.id', '=', 's.user_id')->where('c.teacher_id', $request->user()->id);
        if (isset($data['kelas_id'])) {
            $query->where('c.id', $data['kelas_id']);
        }
        if (! empty($data['q'])) {
            $query->where('u.name', 'like', '%'.$data['q'].'%');
        }

        return $query->orderBy('u.name')->orderBy('s.id')->paginate(30, ['s.id', 'u.name as nama', 'c.name as kelas', 's.status']);
    }
}
