<?php

namespace App\Http\Controllers;

use App\Services\AttemptQuestions;
use App\Services\PracticeProgress;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PracticeController
{
    private function student(Request $request)
    {
        return DB::table('students')->where('user_id', $request->user()->id)->where('status', 'aktif')->lockForUpdate()->firstOrFail();
    }

    public function available(Request $request)
    {
        $student = $this->student($request);
        $teacher = DB::table('classes')->where('id', $student->current_class_id)->value('teacher_id');
        $materials = DB::table('materials as m')->where('m.teacher_id', $teacher)->where('m.status', 'active')
            ->whereExists(function ($q) {
                $q->selectRaw('1')->from('questions as q')->whereColumn('q.material_id', 'm.id')->whereColumn('q.aspect_code', 'm.aspect_code')
                    ->whereColumn('q.level', 'm.level')->where('q.review_status', 'approved')->whereIn('q.usage_scope', ['practice', 'both']);
            })->orderBy('m.title')->paginate(30, ['m.id as materi_id', 'm.title as judul', 'm.content as konten', 'm.aspect_code as aspek', 'm.level as tingkat']);

        return $materials;
    }

    public function start(Request $request)
    {
        $data = $request->validate(['materi_id' => 'required|integer']);

        return DB::transaction(function () use ($request, $data) {
            $student = $this->student($request);
            $teacher = DB::table('classes')->where('id', $student->current_class_id)->value('teacher_id');
            $material = DB::table('materials')->where('id', $data['materi_id'])->where('teacher_id', $teacher)->where('status', 'active')->firstOrFail();
            $attempts = DB::table('practice_attempts')->where('student_id', $student->id)->where('material_id', $material->id);
            $running = (clone $attempts)->where('class_id', $student->current_class_id)->where('status', 'in_progress')->value('id');
            if ($running) {
                return ['data' => AttemptQuestions::Practice->present($running, (bool) $student->parent_consent)];
            }
            $questions = DB::table('questions')->where('teacher_id', $teacher)->where('material_id', $material->id)
                ->where('aspect_code', $material->aspect_code)->where('level', $material->level)->where('review_status', 'approved')
                ->whereIn('usage_scope', ['both', 'practice'])->orderBy('id')->get();
            abort_if($questions->isEmpty(), 422, 'Belum ada soal latihan yang disetujui.');
            $recommendation = DB::table('recommendations')->where('student_id', $student->id)->where('class_id', $student->current_class_id)
                ->where('material_id', $material->id)->where('status', 'active')->value('id');
            $id = DB::table('practice_attempts')->insertGetId(['student_id' => $student->id, 'class_id' => $student->current_class_id,
                'material_id' => $material->id, 'material_title_snapshot' => $material->title, 'aspect_code' => $material->aspect_code,
                'level_snapshot' => $material->level, 'recommendation_id' => $recommendation, 'attempt_number' => 1 + (int) $attempts->max('attempt_number'),
                'started_at' => now(), 'correct_count' => 0, 'question_count' => $questions->count()]);
            AttemptQuestions::Practice->snapshot($id, $questions);

            return response()->json(['data' => AttemptQuestions::Practice->present($id, (bool) $student->parent_consent)], 201);
        });
    }

    public function answer(Request $request, int $id)
    {
        $data = $request->validate(['soal_id' => 'required|integer', 'jawaban' => 'required|string|max:500']);

        return DB::transaction(function () use ($request, $id, $data) {
            $attempt = DB::table('practice_attempts')->where('student_id', $this->student($request)->id)->where('id', $id)->lockForUpdate()->firstOrFail();
            abort_unless($attempt->status === 'in_progress', 409);
            AttemptQuestions::Practice->saveChoice($id, $data['soal_id'], $data['jawaban']);

            return ['success' => true];
        });
    }

    public function finish(Request $request, int $id)
    {
        return DB::transaction(function () use ($request, $id) {
            $attempt = DB::table('practice_attempts')->where('student_id', $this->student($request)->id)->where('id', $id)->lockForUpdate()->firstOrFail();
            abort_if($attempt->status === 'abandoned', 409);
            $answers = DB::table('practice_attempt_answers')->where('practice_attempt_id', $id)->get();
            abort_if($answers->isEmpty() || $answers->contains(fn ($a) => ! $a->answered_at), 422, 'Jawaban belum lengkap.');
            if ($attempt->status === 'in_progress') {
                $pending = $answers->contains(fn ($a) => $a->score === null);
                $attempt->score = $pending ? null : round($answers->avg('score'), 2);
                $attempt->status = $pending ? 'waiting_teacher' : 'completed';
                DB::table('practice_attempts')->where('id', $id)->update(['status' => $attempt->status, 'score' => $attempt->score, 'finished_at' => now(),
                    'correct_count' => $answers->where('is_correct', 1)->count()]);
                if (! $pending) {
                    app(PracticeProgress::class)->apply($attempt);
                }
            }

            return ['data' => ['hasil_id' => $id, 'status' => $attempt->status, 'skor' => $attempt->score]];
        });
    }
}
