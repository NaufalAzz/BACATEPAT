<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StudentOverviewController
{
    public function __invoke(Request $request)
    {
        $student = DB::table('students')->where('user_id', $request->user()->id)
            ->where('status', 'aktif')->firstOrFail();
        $recommendation = DB::table('recommendations as r')->join('materials as m', 'm.id', '=', 'r.material_id')
            ->where('r.student_id', $student->id)->where('r.class_id', $student->current_class_id)
            ->where('r.status', 'active')->where('m.status', 'active')
            ->first(['m.id as materi_id', 'm.title as judul', 'm.content as konten', 'r.reason as alasan']);
        $practice = DB::table('practice_attempts')->where('student_id', $student->id)
            ->orderByDesc('started_at')->limit(10)->get(['material_title_snapshot as judul', 'score as nilai', 'started_at as tanggal']);
        $evaluations = DB::table('audio_evaluations as e')->join('voice_recordings as r', 'r.id', '=', 'e.recording_id')
            ->where('r.student_id', $student->id)->orderByDesc('e.evaluated_at')->limit(10)
            ->get(['e.accuracy_score as ketepatan', 'e.fluency_score as kelancaran', 'e.comment as komentar', 'e.advice as saran']);

        return ['data' => ['rekomendasi' => $recommendation, 'latihan' => $practice, 'evaluasi' => $evaluations]];
    }
}
