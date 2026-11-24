<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ActivityController
{
    private function history(Request $request, string $table, ?int $id)
    {
        $query = DB::table($table.' as a')->join('classes as c', 'c.id', '=', 'a.class_id')->join('students as s', 's.id', '=', 'a.student_id');
        if ($id === null) {
            $query->where('s.user_id', $request->user()->id);
        } else {
            $query->where('a.student_id', $id)->where('c.teacher_id', $request->user()->id);
        }
        $score = $table === 'diagnostic_attempts' ? 'a.overall_score' : 'a.score';

        return $query->orderByDesc('a.started_at')->paginate(30, ['a.id', 'a.status', 'a.started_at', 'a.finished_at', $score.' as skor']);
    }

    public function practice(Request $request, ?int $id = null)
    {
        return $this->history($request, 'practice_attempts', $id);
    }

    public function diagnostic(Request $request, int $id)
    {
        return $this->history($request, 'diagnostic_attempts', $id);
    }

    public function evaluations(Request $request)
    {
        return DB::table('audio_evaluations as e')->join('voice_recordings as r', 'r.id', '=', 'e.recording_id')
            ->join('students as s', 's.id', '=', 'r.student_id')->where('s.user_id', $request->user()->id)
            ->orderByDesc('e.evaluated_at')->paginate(30, ['e.id', 'r.target_text_snapshot as bacaan', 'e.accuracy_score', 'e.fluency_score', 'e.comment', 'e.advice', 'e.evaluated_at']);
    }

    public function dashboard(Request $request)
    {
        $classes = DB::table('classes')->where('teacher_id', $request->user()->id)->pluck('id');

        return ['data' => ['kelas' => $classes->count(), 'siswa' => DB::table('students')->whereIn('current_class_id', $classes)->count(),
            'tes_aktif' => DB::table('diagnostic_tests')->whereIn('class_id', $classes)->where('status', 'active')->count()]];
    }
}
