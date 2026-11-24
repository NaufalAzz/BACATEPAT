<?php

// Run inside the disposable integration database after importing the demo seed.
use App\Jobs\GenerateDrafts;
use App\Jobs\TranscribeReading;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();
if (getenv('BACATEPAT_INTEGRATION_TEST') !== '1') {
    throw new RuntimeException('Use the disposable integration database.');
}
Http::preventStrayRequests();
config(['services.learning_ai.key' => 'test-only', 'services.learning_ai.model' => 'test-model', 'services.learning_ai.audio_model' => 'test-speech']);
DB::beginTransaction();
try {
    $teacher = DB::table('users')->where('username', 'demo.guru.rina')->value('id');
    $request = DB::table('ai_draft_requests')->insertGetId(['teacher_id' => $teacher, 'kind' => 'materi', 'parameters' => json_encode(['aspek' => 'huruf', 'tingkat' => 1, 'tema' => 'buah', 'jumlah' => 1]), 'created_at' => now(), 'updated_at' => now()]);
    Http::fake(['*/chat/completions' => Http::response(['choices' => [['message' => ['content' => json_encode(['items' => [['judul' => 'A', 'konten' => 'Apel']]])]]]])]);
    $job = new GenerateDrafts($request);
    $job->handle();
    $job->handle();
    $row = DB::table('ai_draft_requests')->where('id', $request)->first();
    $draft = DB::table('materials')->find(json_decode($row->result_ids)[0]);
    if ($row->status !== 'succeeded' || $draft->status !== 'draft' || ! $draft->ai_generated) {
        throw new RuntimeException('Expected one unpublished generated material.');
    }
    $record = DB::table('voice_recordings')->where('ai_consent_snapshot', 0)->value('id');
    $analysis = DB::table('ai_audio_analyses')->insertGetId(['recording_id' => $record, 'status' => 'queued', 'requested_at' => now()]);
    (new TranscribeReading($analysis))->handle();
    if (DB::table('ai_audio_analyses')->where('id', $analysis)->value('status') !== 'skipped' || Http::recorded()->count() !== 1) {
        throw new RuntimeException('Consent or duplicate request check failed.');
    }
    // Exercise a permitted recording with synthetic bytes and a fake provider.
    $recording = DB::table('voice_recordings as r')->join('students as s', 's.id', '=', 'r.student_id')
        ->where('r.parent_consent_snapshot', 1)->where('r.ai_consent_snapshot', 1)
        ->where('s.parent_consent', 1)->where('s.ai_consent', 1)->firstOrFail(['r.id']);
    $files = Storage::fake('local');
    $files->put('recordings/test.wav', 'synthetic-integration-audio');
    DB::table('voice_recordings')->where('id', $recording->id)->update(['private_storage_path' => 'recordings/test.wav', 'target_text_snapshot' => 'Budi baca buku']);
    $allowed = DB::table('ai_audio_analyses')->insertGetId(['recording_id' => $recording->id, 'status' => 'queued', 'requested_at' => now()]);
    Http::fake(['*/audio/transcriptions' => Http::response(['text' => 'Budi baca bola'])]);
    (new TranscribeReading($allowed))->handle();
    $row = DB::table('ai_audio_analyses')->find($allowed);
    if ($row->status !== 'succeeded' || json_decode($row->changed_words, true) !== [['target' => 'buku', 'terdengar' => 'bola']] ||
        (float) $row->similarity_score !== 66.67) {
        throw new RuntimeException('Expected an indicative transcript comparison.');
    }
    echo "AI draft and consent checks passed.\n";
} finally {
    DB::rollBack();
}
