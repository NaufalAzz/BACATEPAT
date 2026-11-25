<?php

namespace App\Http\Controllers;

use Dompdf\Dompdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProgressController
{
    private function history(Request $request, ?int $studentId = null, ?int $classId = null)
    {
        $user = $request->user();
        $query = DB::table('mastery_history as h')->join('classes as c', 'c.id', '=', 'h.class_id')
            ->join('students as s', 's.id', '=', 'h.student_id')->join('users as u', 'u.id', '=', 's.user_id');
        if ($user->role === 'siswa') {
            $query->where('s.user_id', $user->id);
        } else {
            $query->where('c.teacher_id', $user->id);
            if ($classId !== null) {
                abort_unless(DB::table('classes')->where('teacher_id', $user->id)->where('id', $classId)->exists(), 404);
                $query->where('h.class_id', $classId);
            }
            if ($studentId !== null) {
                abort_unless(DB::table('students')->join('classes', 'classes.id', '=', 'students.current_class_id')
                    ->where('classes.teacher_id', $user->id)->where('students.id', $studentId)->exists(), 404);
                $query->where('s.id', $studentId);
            }
        }
        $filters = $request->validate(['aspek' => 'sometimes|exists:learning_aspects,code', 'dari' => 'sometimes|date_format:Y-m-d',
            'sampai' => array_filter(['sometimes', 'date_format:Y-m-d', $request->has('dari') ? 'after_or_equal:dari' : null])]);
        if (isset($filters['aspek'])) {
            $query->where('h.aspect_code', $filters['aspek']);
        }
        if (isset($filters['dari'])) {
            $query->whereDate('h.recorded_at', '>=', $filters['dari']);
        }
        if (isset($filters['sampai'])) {
            $query->whereDate('h.recorded_at', '<=', $filters['sampai']);
        }

        return $query->orderBy('h.recorded_at')->orderBy('h.id')->get(['u.name as nama', 'c.name as kelas', 'h.aspect_code as aspek',
            'h.id', 'h.student_id', 'h.class_id', 'h.observed_level', 'h.diagnostic_attempt_id', 'h.practice_attempt_id', 'h.audio_evaluation_revision_id', 'h.reason', 'h.recorded_at as tanggal', 'h.score as skor', 'h.mastery_status as status', 'h.source_type as sumber']);
    }

    public function student(Request $request, ?int $id = null)
    {
        return ['data' => ['aspek' => $this->history($request, $id)->groupBy('aspek')]];
    }

    public function classroom(Request $request, int $id)
    {
        return ['data' => $this->history($request, classId: $id)->groupBy('aspek')->map(fn ($rows) => [
            'jumlah_pengamatan' => $rows->count(), 'rata_rata' => round($rows->avg('skor'), 2)])];
    }

    public function report(Request $request, string $scope, int $id)
    {
        $rows = $scope === 'kelas' ? $this->history($request, classId: $id) : $this->history($request, $id);
        $pdf = new Dompdf;
        $pdf->loadHtml(view('report', ['rows' => $rows, 'scope' => $scope])->render());
        $pdf->render();

        return response($pdf->output(), 200, ['Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="laporan-'.$scope.'-'.$id.'.pdf"', 'Cache-Control' => 'private, no-store']);
    }
}
