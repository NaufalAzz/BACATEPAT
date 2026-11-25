<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TeacherReviewController
{
    public function results(Request $request, int $id)
    {
        abort_unless(DB::table('diagnostic_tests')->where('id', $id)->where('teacher_id', $request->user()->id)->exists(), 404);

        return DB::table('diagnostic_attempts as a')->join('students as s', 's.id', '=', 'a.student_id')->join('users as u', 'u.id', '=', 's.user_id')
            ->where('a.diagnostic_test_id', $id)->orderBy('u.name')->paginate(30, ['u.name as nama', 'a.status', 'a.overall_score as skor', 'a.finished_at']);
    }

    private function pendingSupport(int $teacher)
    {
        $latest = DB::table('mastery_history')->selectRaw('MAX(id) as id')->groupBy('student_id', 'aspect_code');

        return DB::table('mastery_history as h')->joinSub($latest, 'latest', 'h.id', '=', 'latest.id')
            ->join('students as s', 's.id', '=', 'h.student_id')->join('classes as c', 'c.id', '=', 's.current_class_id')
            ->join('users as u', 'u.id', '=', 's.user_id')->leftJoin('support_followups as f', 'f.history_id', '=', 'h.id')
            ->whereColumn('h.class_id', 'c.id')->where('c.teacher_id', $teacher)->where('h.needs_teacher_support', true)->whereNull('f.history_id');
    }

    public function support(Request $request)
    {
        $query = $this->pendingSupport($request->user()->id);
        if ($request->filled('kelas_id')) {
            $query->where('c.id', $request->integer('kelas_id'));
        }

        return $query->orderBy('u.name')->orderBy('h.id')->paginate(30, ['s.id as siswa_id', 'u.name as nama', 'c.name as kelas', 'h.aspect_code as aspek', 'h.reason as alasan']);
    }

    public function followUp(Request $request, int $id)
    {
        $request->validate(['perlu_pendampingan' => 'required|boolean']);
        abort_if($request->boolean('perlu_pendampingan'), 422, 'Tindak lanjut menutup penanda pendampingan.');

        return DB::transaction(function () use ($request, $id) {
            $teacher = $request->user()->id;
            DB::table('students as s')->join('classes as c', 'c.id', '=', 's.current_class_id')->where('s.id', $id)
                ->where('c.teacher_id', $teacher)->lockForUpdate()->firstOrFail(['s.id']);
            $ids = $this->pendingSupport($teacher)->where('s.id', $id)->pluck('h.id');
            foreach ($ids as $history) {
                DB::table('support_followups')->insert(['history_id' => $history, 'teacher_id' => $teacher, 'reviewed_at' => now()]);
            }

            return ['success' => true];
        });
    }

    public function recommend(Request $request, int $id)
    {
        $data = $request->validate(['materi_id' => 'required|integer', 'alasan' => 'required|string|max:500']);

        return DB::transaction(function () use ($request, $id, $data) {
            $teacher = $request->user()->id;
            $student = DB::table('students as s')->join('classes as c', 'c.id', '=', 's.current_class_id')->where('c.teacher_id', $teacher)->where('s.id', $id)->lockForUpdate()->firstOrFail(['s.*']);
            $material = DB::table('materials')->where('teacher_id', $teacher)->where('status', 'active')->where('id', $data['materi_id'])->firstOrFail();
            DB::table('recommendations')->where('student_id', $id)->where('status', 'active')->update(['status' => 'superseded', 'closed_at' => now()]);
            $rec = DB::table('recommendations')->insertGetId(['student_id' => $id, 'class_id' => $student->current_class_id, 'material_id' => $material->id,
                'aspect_code' => $material->aspect_code, 'target_level' => $material->level, 'source' => 'teacher', 'created_by_teacher_id' => $teacher, 'reason' => $data['alasan'], 'created_at' => now()]);

            return ['data' => ['id' => $rec]];
        });
    }
}
