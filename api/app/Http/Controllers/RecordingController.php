<?php

namespace App\Http\Controllers;

use App\Jobs\TranscribeReading;
use App\Services\DiagnosticPlacement;
use App\Services\PracticeProgress;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\Process\Process;

class RecordingController
{
    public function upload(Request $request)
    {
        $data = $request->validate([
            'file' => 'required|file|max:5120|extensions:m4a,aac,wav,mp3|mimetypes:audio/mp4,video/mp4,audio/aac,audio/x-aac,audio/mpeg,audio/wav,audio/x-wav',
            'soal_id' => 'required|integer',
            'hasil_diagnostik_id' => 'required_without:hasil_latihan_id|prohibits:hasil_latihan_id|integer',
            'hasil_latihan_id' => 'required_without:hasil_diagnostik_id|prohibits:hasil_diagnostik_id|integer',
        ]);
        $studentQuery = DB::table('students')->where('user_id', $request->user()->id)->where('status', 'aktif');
        abort_unless((clone $studentQuery)->value('parent_consent'), 403, 'Persetujuan wali diperlukan.');
        $file = $request->file('file');
        $probe = new Process(['ffprobe', '-v', 'error', '-protocol_whitelist', 'file', '-show_entries', 'stream=codec_type:format=duration', '-of', 'json', $file->getRealPath()]);
        $probe->setTimeout(8)->run();
        abort_if($probe->getExitCode() === 127, 503, 'Layanan pemeriksaan audio belum tersedia.');
        $info = json_decode($probe->getOutput(), true);
        $duration = (float) ($info['format']['duration'] ?? 0);
        abort_if(! $probe->isSuccessful() || array_column($info['streams'] ?? [], 'codec_type') !== ['audio'] || $duration < 1 || $duration > 60, 422, 'Unggah audio dengan durasi 1–60 detik.');
        $kind = isset($data['hasil_diagnostik_id']) ? 'diagnostic' : 'practice';
        $attemptId = $data['hasil_diagnostik_id'] ?? $data['hasil_latihan_id'];
        $path = null;
        try {
            return DB::transaction(function () use ($studentQuery, $kind, $attemptId, $data, $file, $duration, &$path) {
                $student = $studentQuery->lockForUpdate()->firstOrFail();
                abort_unless($student->parent_consent, 403);
                $attempt = DB::table($kind.'_attempts')->where('student_id', $student->id)->where('id', $attemptId)->lockForUpdate()->firstOrFail();
                abort_unless($attempt->status === 'in_progress', 409);
                $answer = DB::table($kind.'_attempt_answers')->where($kind.'_attempt_id', $attemptId)
                    ->where('question_id', $data['soal_id'])->where('question_type', 'oral_reading')->firstOrFail();
                abort_if($answer->answered_at !== null, 409, 'Rekaman sudah terkirim.');
                $path = $file->store('recordings', 'local');
                abort_unless($path, 503, 'Gagal menyimpan audio.');
                $id = DB::table('voice_recordings')->insertGetId(['student_id' => $student->id, 'question_id' => $data['soal_id'],
                    $kind.'_attempt_id' => $attemptId, 'target_text_snapshot' => $answer->target_text_snapshot, 'private_storage_path' => $path,
                    'mime_type' => $file->getMimeType(), 'size_bytes' => $file->getSize(), 'duration_seconds' => (int) round($duration),
                    'parent_consent_snapshot' => true, 'ai_consent_snapshot' => $student->ai_consent, 'submitted_at' => now()]);
                DB::table($kind.'_attempt_answers')->where('id', $answer->id)->update(['answered_at' => now()]);
                if ($student->ai_consent && in_array($answer->aspect_code, ['kata', 'kalimat'], true) &&
                    config('services.learning_ai.audio_model') && config('services.learning_ai.key')) {
                    $analysis = DB::table('ai_audio_analyses')->insertGetId(['recording_id' => $id, 'status' => 'queued', 'requested_at' => now()]);
                    TranscribeReading::dispatch($analysis)->onConnection('database');
                }

                return response()->json(['data' => ['rekaman_id' => $id, 'durasi_detik' => (int) round($duration)]], 201);
            });
        } catch (\Throwable $error) {
            if ($path) {
                Storage::disk('local')->delete($path);
            }
            throw $error;
        }
    }

    private function owned(Request $request)
    {
        return DB::table('voice_recordings as r')
            ->join('students as s', 's.id', '=', 'r.student_id')->join('users as u', 'u.id', '=', 's.user_id')
            ->leftJoin('diagnostic_attempts as d', 'd.id', '=', 'r.diagnostic_attempt_id')
            ->leftJoin('practice_attempts as p', 'p.id', '=', 'r.practice_attempt_id')
            ->join('classes as c', 'c.id', '=', DB::raw('COALESCE(d.class_id,p.class_id)'))
            ->where('c.teacher_id', $request->user()->id);
    }

    public function index(Request $request)
    {
        return $this->owned($request)
            ->leftJoin('audio_evaluations as e', 'e.recording_id', '=', 'r.id')
            ->select(['e.id as evaluasi_id', 'e.accuracy_score', 'e.fluency_score', 'e.comment', 'e.advice', 'r.id', 'u.name as nama', 'r.student_id', 'r.status', 'r.target_text_snapshot', 'r.submitted_at'])
            ->selectSub(DB::table('audio_evaluation_revisions')->selectRaw('MAX(revision_no)')->whereColumn('evaluation_id', 'e.id'), 'revision')
            ->orderByDesc('r.submitted_at')->orderByDesc('r.id')->paginate(30);
    }

    public function detail(Request $request, int $id)
    {
        $record = $this->owned($request)->where('r.id', $id)->firstOrFail(['r.id', 'r.status', 'r.target_text_snapshot', 'r.duration_seconds']);
        $analysis = DB::table('ai_audio_analyses')->where('recording_id', $id)->orderByDesc('id')->first(['status', 'transcript', 'similarity_score', 'missed_words', 'changed_words', 'repeated_words']);

        return ['data' => ['rekaman' => $record, 'analisis' => $analysis]];
    }

    public function retryAnalysis(Request $request, int $id)
    {
        abort_unless(config('services.learning_ai.key') && config('services.learning_ai.audio_model'), 503);

        return DB::transaction(function () use ($request, $id) {
            $row = $this->owned($request)->where('r.id', $id)->lockForUpdate()->firstOrFail(['r.*', 's.parent_consent', 's.ai_consent']);
            abort_unless($row->parent_consent_snapshot && $row->ai_consent_snapshot && $row->parent_consent && $row->ai_consent, 403);
            abort_unless($row->private_storage_path, 409);
            $previous = DB::table('ai_audio_analyses')->where('recording_id', $id)->orderByDesc('id')->first();
            abort_unless($previous && $previous->status === 'failed', 409);
            $analysis = DB::table('ai_audio_analyses')->insertGetId(['recording_id' => $id, 'status' => 'queued', 'requested_at' => now()]);
            TranscribeReading::dispatch($analysis)->onConnection('database');

            return response()->json(['data' => ['id' => $analysis, 'status' => 'queued']], 202);
        });
    }

    public function destroy(Request $request, int $id)
    {
        return DB::transaction(function () use ($request, $id) {
            $row = $this->owned($request)->where('r.id', $id)->lockForUpdate()->firstOrFail(['r.*']);
            if ($row->private_storage_path) {
                $disk = Storage::disk('local');
                abort_if($disk->exists($row->private_storage_path) && ! $disk->delete($row->private_storage_path), 503);
                DB::table('voice_recordings')->where('id', $id)->update(['private_storage_path' => null, 'file_deleted_at' => now(), 'status' => 'file_deleted']);
            }

            return ['success' => true];
        });
    }

    public function stream(Request $request, int $id)
    {
        $path = $this->owned($request)->where('r.id', $id)->value('r.private_storage_path');
        abort_unless($path && Storage::disk('local')->exists($path), 404);

        return response()->file(Storage::disk('local')->path($path), ['Cache-Control' => 'private, no-store']);
    }

    private function scores(Request $request): array
    {
        return $request->validate(['nilai_ketepatan' => 'required|integer|between:0,100', 'nilai_kelancaran' => 'required|integer|between:0,100',
            'komentar' => 'required|string|max:4000', 'saran' => 'required|string|max:4000']);
    }

    public function revise(Request $request, int $id)
    {
        $data = $this->scores($request);

        return DB::transaction(function () use ($request, $id, $data) {
            $evaluation = DB::table('audio_evaluations')->where('id', $id)->where('teacher_id', $request->user()->id)->lockForUpdate()->firstOrFail();
            $record = $this->owned($request)->where('r.id', $evaluation->recording_id)->firstOrFail(['r.*']);
            $values = ['accuracy_score' => (int) $data['nilai_ketepatan'], 'fluency_score' => (int) $data['nilai_kelancaran'],
                'comment' => $data['komentar'], 'advice' => $data['saran']];
            $revisions = DB::table('audio_evaluation_revisions')->where('evaluation_id', $id);
            $version = (int) $revisions->max('revision_no');
            if (! array_diff_assoc($values, (array) $evaluation)) {
                return ['data' => ['evaluasi_id' => $id, 'revision' => $version]];
            }
            abort_if($request->has('revision') && $request->integer('revision') !== $version, 409, 'Evaluasi telah direvisi. Muat ulang sebelum menyimpan.');
            DB::table('audio_evaluations')->where('id', $id)->update($values);
            $revision = DB::table('audio_evaluation_revisions')->insertGetId($values + ['teacher_id' => $request->user()->id,
                'evaluation_id' => $id, 'revision_no' => $version + 1, 'revised_at' => now()]);
            $kind = $record->diagnostic_attempt_id ? 'diagnostic' : 'practice';
            $attemptId = $record->diagnostic_attempt_id ?? $record->practice_attempt_id;
            $attempt = DB::table($kind.'_attempts')->where('id', $attemptId)->lockForUpdate()->firstOrFail();
            $answers = DB::table($kind.'_attempt_answers')->where($kind.'_attempt_id', $attemptId);
            $oral = (clone $answers)->where('question_id', $record->question_id)->where('question_type', 'oral_reading');
            $aspect = (clone $oral)->firstOrFail()->aspect_code;
            $score = ($values['accuracy_score'] + $values['fluency_score']) / 2;
            $oral->update(['score' => $score]);
            if ($attempt->status === 'completed' && ($evaluation->accuracy_score + $evaluation->fluency_score) / 2 != $score) {
                $scores = $answers->get()->groupBy('aspect_code')->map(fn ($rows) => round($rows->avg('score'), 2));
                $attempt->score = $scores->avg();
                DB::table($kind.'_attempts')->where('id', $attemptId)->update([($kind === 'practice' ? 'score' : 'overall_score') => $attempt->score]);
                if ($kind === 'practice') {
                    app(PracticeProgress::class)->apply($attempt, $revision);
                } else {
                    app(DiagnosticPlacement::class)->apply($attempt, $scores, $revision, $aspect);
                }
            }

            return ['data' => ['evaluasi_id' => $id, 'revision' => $version + 1]];
        }, 3);
    }

    public function evaluate(Request $request, int $id)
    {
        $data = $this->scores($request);

        return DB::transaction(function () use ($request, $id, $data) {
            $row = $this->owned($request)->where('r.id', $id)->lockForUpdate()->firstOrFail(['r.*']);
            abort_unless($row->private_storage_path && $row->status === 'uploaded', 409, 'Rekaman tidak tersedia untuk evaluasi baru.');
            $kind = $row->diagnostic_attempt_id ? 'diagnostic' : 'practice';
            $attemptId = $row->diagnostic_attempt_id ?? $row->practice_attempt_id;
            $attempt = DB::table($kind.'_attempts')->where('id', $attemptId)->lockForUpdate()->firstOrFail();
            $values = ['teacher_id' => $request->user()->id, 'accuracy_score' => $data['nilai_ketepatan'], 'fluency_score' => $data['nilai_kelancaran'],
                'comment' => $data['komentar'], 'advice' => $data['saran']];
            $evaluation = DB::table('audio_evaluations')->insertGetId($values + ['recording_id' => $id, 'evaluated_at' => now()]);
            DB::table('audio_evaluation_revisions')->insert($values + ['evaluation_id' => $evaluation, 'revision_no' => 1, 'revised_at' => now()]);
            $score = ($values['accuracy_score'] + $values['fluency_score']) / 2;
            $answers = DB::table($kind.'_attempt_answers')->where($kind.'_attempt_id', $attemptId);
            (clone $answers)->where('question_id', $row->question_id)->update(['score' => $score]);
            DB::table('voice_recordings')->where('id', $id)->update(['status' => 'evaluated', 'delete_after' => today()->addDays((int) $request->user()->audio_retention_days)]);
            if ($attempt->status === 'waiting_teacher' && ! (clone $answers)->whereNull('score')->exists()) {
                $scores = $answers->get()->groupBy('aspect_code')->map(fn ($rows) => round($rows->avg('score'), 2));
                if ($kind === 'diagnostic') {
                    app(DiagnosticPlacement::class)->apply($attempt, $scores);
                }
                if ($kind === 'practice') {
                    $attempt->score = $scores->avg();
                    app(PracticeProgress::class)->apply($attempt);
                }
                DB::table($kind.'_attempts')->where('id', $attemptId)->update(['status' => 'completed',
                    ($kind === 'diagnostic' ? 'overall_score' : 'score') => $scores->avg(), 'finished_at' => now()]);
            }

            return response()->json(['data' => ['evaluasi_id' => $evaluation, 'skor_soal' => $score]], 201);
        }, 3);
    }
}
