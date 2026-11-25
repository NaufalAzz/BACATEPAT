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
        if ($table === 'diagnostic_attempts') {
            $query->join('diagnostic_tests as t', 't.id', '=', 'a.diagnostic_test_id');
            $title = 't.title';
        } else {
            $title = 'a.material_title_snapshot';
        }
        $score = $table === 'diagnostic_attempts' ? 'a.overall_score' : 'a.score';

        return $query->orderByDesc('a.started_at')->orderByDesc('a.id')->paginate(30, [$title.' as judul', 'a.id', 'a.status', 'a.started_at', 'a.finished_at', $score.' as skor']);
    }

    public function practice(Request $request, ?int $id = null)
    {
        return $this->history($request, 'practice_attempts', $id);
    }

    public function diagnostic(Request $request, int $id)
    {
        return $this->history($request, 'diagnostic_attempts', $id);
    }

    public function evaluations(Request $request, ?int $id = null)
    {
        $query = DB::table('audio_evaluations as e')->join('voice_recordings as r', 'r.id', '=', 'e.recording_id')
            ->join('students as s', 's.id', '=', 'r.student_id');
        if ($id === null) {
            $query->where('s.user_id', $request->user()->id);
        } else {
            $query->join('classes as c', 'c.id', '=', 's.current_class_id')->where('c.teacher_id', $request->user()->id)
                ->where('e.teacher_id', $request->user()->id)->where('s.id', $id);
        }

        return $query->orderByDesc('e.evaluated_at')->orderByDesc('e.id')->paginate(30, ['e.id', 'r.target_text_snapshot as bacaan', 'e.accuracy_score', 'e.fluency_score', 'e.comment', 'e.advice', 'e.evaluated_at']);
    }

    public function dashboard(Request $request)
    {
        $classes = DB::table('classes')->where('teacher_id', $request->user()->id)->pluck('id');

        $students = DB::table('students')->whereIn('current_class_id', $classes)->where('status', 'aktif')->select('id');
        $mastery = DB::table('mastery_history')->whereIn('class_id', $classes)->whereIn('student_id', $students)
            ->selectRaw('aspect_code, score, ROW_NUMBER() OVER (PARTITION BY student_id, aspect_code ORDER BY recorded_at DESC, id DESC) AS ranking');
        $namedRows = fn ($table) => DB::table($table.' as r')->join('students as s', 's.id', '=', 'r.student_id')
            ->join('users as u', 'u.id', '=', 's.user_id')->whereIn('r.class_id', $classes);
        $recordings = DB::table('voice_recordings as r')->join('students as s', 's.id', '=', 'r.student_id')
            ->join('users as u', 'u.id', '=', 's.user_id')->leftJoin('diagnostic_attempts as d', 'd.id', '=', 'r.diagnostic_attempt_id')
            ->leftJoin('practice_attempts as p', 'p.id', '=', 'r.practice_attempt_id')->whereIn(DB::raw('COALESCE(d.class_id,p.class_id)'), $classes)
            ->where('r.status', 'uploaded');

        return ['data' => [
            'kelas' => $classes->count(), 'siswa' => DB::table('students')->whereIn('current_class_id', $classes)->count(),
            'aktif' => (clone $students)->count(),
            'diagnosed' => DB::table('diagnostic_attempts')->whereIn('class_id', $classes)->whereIn('student_id', $students)->where('status', 'completed')->distinct()->count('student_id'),
            'tes_aktif' => DB::table('diagnostic_tests')->whereIn('class_id', $classes)->where('status', 'active')->count(),
            'averages' => DB::query()->fromSub($mastery, 'latest')->where('ranking', 1)->groupBy('aspect_code')->selectRaw('aspect_code, ROUND(AVG(score)) AS score')->get(),
            'recommendations' => $namedRows('recommendations')->join('materials as m', 'm.id', '=', 'r.material_id')->where('r.status', 'active')->orderByDesc('r.id')->get(['u.name', 'm.title', 'r.aspect_code', 'r.target_level', 'r.reason']),
            'gaps' => $namedRows('material_gaps')->whereNull('r.resolved_at')->orderByDesc('r.id')->get(['u.name', 'r.aspect_code', 'r.target_level', 'r.reason']),
            'pending' => (clone $recordings)->count(),
            'recordings' => $recordings->orderBy('r.submitted_at')->limit(10)->get(['u.name', 'r.target_text_snapshot', 'r.duration_seconds']),
        ]];
    }
}
