<?php

namespace App\Http\Controllers;

use App\Services\AttemptQuestions;
use App\Services\DiagnosticPlacement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DiagnosticController
{
    private function student(Request $request)
    {
        return DB::table('students')->where('user_id', $request->user()->id)->where('status', 'aktif')->firstOrFail();
    }

    public function active(Request $request)
    {
        $student = $this->student($request);

        return ['data' => DB::table('diagnostic_tests')->where('class_id', $student->current_class_id)
            ->where('status', 'active')->orderBy('id')->get(['id', 'title as judul'])];
    }

    public function start(Request $request)
    {
        $data = $request->validate(['tes_id' => 'required|integer']);

        return DB::transaction(function () use ($request, $data) {
            $student = $this->student($request);
            $test = DB::table('diagnostic_tests')->where('id', $data['tes_id'])
                ->where('class_id', $student->current_class_id)->where('status', 'active')->lockForUpdate()->firstOrFail();
            $existing = DB::table('diagnostic_attempts')->where('diagnostic_test_id', $test->id)->where('student_id', $student->id)->first();
            if ($existing) {
                abort_unless($existing->status === 'in_progress', 409, 'Tes sudah dikerjakan.');

                return ['data' => AttemptQuestions::Diagnostic->present($existing->id, (bool) $student->parent_consent)];
            }
            $questions = DB::table('diagnostic_test_questions as t')->join('questions as q', 'q.id', '=', 't.question_id')
                ->where('t.diagnostic_test_id', $test->id)->orderBy('t.position')->get(['q.*']);
            abort_if($questions->isEmpty(), 409, 'Tes belum memiliki soal.');
            $id = DB::table('diagnostic_attempts')->insertGetId(['student_id' => $student->id, 'class_id' => $test->class_id, 'diagnostic_test_id' => $test->id, 'started_at' => now()]);
            AttemptQuestions::Diagnostic->snapshot($id, $questions);

            return response()->json(['data' => AttemptQuestions::Diagnostic->present($id, (bool) $student->parent_consent)], 201);
        });
    }

    private function attempt(Request $request, int $id)
    {
        return DB::table('diagnostic_attempts')->where('id', $id)->where('student_id', $this->student($request)->id)
            ->lockForUpdate()->firstOrFail();
    }

    public function answer(Request $request, int $id)
    {
        $data = $request->validate(['soal_id' => 'required|integer', 'jawaban' => 'required|string|max:500']);

        return DB::transaction(function () use ($request, $data, $id) {
            abort_unless($this->attempt($request, $id)->status === 'in_progress', 409);
            AttemptQuestions::Diagnostic->saveChoice($id, $data['soal_id'], $data['jawaban']);

            return ['success' => true];
        });
    }

    public function finish(Request $request, int $id)
    {
        return DB::transaction(function () use ($request, $id) {
            $attempt = $this->attempt($request, $id);
            abort_if($attempt->status === 'abandoned', 409);
            $answers = DB::table('diagnostic_attempt_answers')->where('diagnostic_attempt_id', $id)->get();
            abort_if($answers->isEmpty() || $answers->contains(fn ($a) => ! $a->answered_at), 422, 'Jawaban belum lengkap.');
            $scores = $answers->groupBy('aspect_code')->map(fn ($rows) => $rows->contains(fn ($a) => $a->score === null) ? null : round($rows->avg('score'), 2));
            $status = $scores->containsStrict(null) ? 'waiting_teacher' : 'completed';
            if ($attempt->status === 'in_progress') {
                if ($status === 'completed') {
                    app(DiagnosticPlacement::class)->apply($attempt, $scores);
                }
                DB::table('diagnostic_attempts')->where('id', $id)->update(['status' => $status, 'finished_at' => now(),
                    'overall_score' => $status === 'completed' ? $scores->avg() : null]);
            }

            return ['data' => ['hasil_id' => $id, 'status' => $status, 'skor' => $scores]];
        });
    }

    public function results(Request $request)
    {
        return DB::table('diagnostic_attempts')->where('student_id', $this->student($request)->id)
            ->orderByDesc('started_at')->paginate(25, ['id', 'status', 'overall_score as skor', 'started_at', 'finished_at']);
    }
}
