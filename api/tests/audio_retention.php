<?php

use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();
if (getenv('BACATEPAT_INTEGRATION_TEST') !== '1') {
    throw new RuntimeException('Use the disposable integration database.');
}
$disk = Storage::fake('local');
DB::beginTransaction();
try {
    $audio = DB::table('audio_evaluations as e')->join('voice_recordings as r', 'r.id', '=', 'e.recording_id')
        ->firstOrFail(['r.id', 'e.id as evaluation_id', 'e.accuracy_score']);
    $path = 'recordings/retention-test.wav';
    $disk->put($path, 'synthetic');
    $row = DB::table('voice_recordings')->where('id', $audio->id);
    $row->update(['private_storage_path' => $path, 'delete_after' => today()->addDay(), 'status' => 'evaluated']);
    Artisan::call('rekaman:retensi');
    if (! $disk->exists($path)) {
        throw new RuntimeException('Premature deletion.');
    }
    $row->update(['delete_after' => today()]);
    Artisan::call('rekaman:retensi');
    Artisan::call('rekaman:retensi');
    $score = DB::table('audio_evaluations')->where('id', $audio->evaluation_id)->value('accuracy_score');
    if ($disk->exists($path) || $row->value('private_storage_path') !== null || $score !== $audio->accuracy_score) {
        throw new RuntimeException('Retention or score preservation failed.');
    }
    echo "Audio retention passed.\n";
} finally {
    DB::rollBack();
}
