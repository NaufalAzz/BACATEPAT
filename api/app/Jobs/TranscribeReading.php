<?php

namespace App\Jobs;

use App\Services\ReadingComparison;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Throwable;

class TranscribeReading implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    public array $backoff = [5, 15];

    public int $timeout = 75;

    public function __construct(public readonly int $analysisId) {}

    public function handle(): void
    {
        $analysis = DB::table('ai_audio_analyses')->where('id', $this->analysisId)->firstOrFail();
        if (in_array($analysis->status, ['succeeded', 'skipped'], true)) {
            return;
        }
        $query = DB::table('voice_recordings as r')->join('students as s', 's.id', '=', 'r.student_id')
            ->where('r.id', $analysis->recording_id)->whereNotNull('r.private_storage_path')
            ->where('r.parent_consent_snapshot', 1)->where('r.ai_consent_snapshot', 1)->where('s.parent_consent', 1)->where('s.ai_consent', 1);
        $audio = $query->first(['r.private_storage_path', 'r.mime_type', 'r.target_text_snapshot', 'r.duration_seconds']);
        $status = DB::table('ai_audio_analyses')->where('id', $analysis->id);
        if (! $audio || ! config('services.learning_ai.audio_model') || ! config('services.learning_ai.key')) {
            $status->update(['status' => 'skipped', 'completed_at' => now()]);

            return;
        }
        $status->update(['status' => 'running']);
        $model = config('services.learning_ai.audio_model');
        $started = microtime(true);
        $extension = pathinfo($audio->private_storage_path, PATHINFO_EXTENSION);
        $stream = Storage::disk('local')->readStream($audio->private_storage_path);
        if (! $stream) {
            throw new \RuntimeException('Audio belum tersedia.');
        }
        try {
            $transcript = Http::timeout(30)->withToken(config('services.learning_ai.key'))
                ->attach('file', $stream, 'bacaan.'.$extension, ['Content-Type' => $audio->mime_type])
                ->post(rtrim(config('services.learning_ai.url'), '/').'/audio/transcriptions', ['model' => $model, 'language' => 'id'])
                ->throw()->json('text');
        } finally {
            if (is_resource($stream)) {
                fclose($stream);
            }
        }
        if (! is_string($transcript) || mb_strlen($transcript) > 10000) {
            throw new \UnexpectedValueException('Transkrip tidak valid.');
        }
        if (! $query->exists()) {
            $status->update(['status' => 'skipped', 'completed_at' => now()]);

            return;
        }
        $comparison = app(ReadingComparison::class)->compare($audio->target_text_snapshot, $transcript);
        DB::transaction(function () use ($comparison, $status, $transcript, $model, $started, $audio) {
            $updated = (clone $status)->where('status', 'running')->update($comparison + ['status' => 'succeeded', 'transcript' => $transcript, 'model_name' => $model, 'completed_at' => now()]);
            if ($updated) {
                DB::table('ai_usage_logs')->insert(['job_type' => 'audio_analysis', 'model_name' => $model, 'audio_duration_seconds' => $audio->duration_seconds,
                    'status' => 'succeeded', 'duration_ms' => (int) ((microtime(true) - $started) * 1000)]);
            }
        });
    }

    public function failed(?Throwable $error): void
    {
        $updated = DB::table('ai_audio_analyses')->where('id', $this->analysisId)->whereNotIn('status', ['skipped', 'succeeded'])
            ->update(['status' => 'failed', 'error_summary' => 'Layanan transkripsi gagal.', 'completed_at' => now()]);
        if ($updated) {
            DB::table('ai_usage_logs')->insert(['job_type' => 'audio_analysis', 'model_name' => config('services.learning_ai.audio_model'), 'status' => 'failed']);
        }
    }
}
