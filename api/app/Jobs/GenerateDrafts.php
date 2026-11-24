<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;
use Throwable;

class GenerateDrafts implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    public array $backoff = [5, 15];

    public int $timeout = 75;

    public function __construct(public readonly int $draftId) {}

    public function handle(): void
    {
        $job = DB::table('ai_draft_requests')->where('id', $this->draftId)->firstOrFail();
        if ($job->status === 'succeeded') {
            return;
        }
        $parameters = json_decode($job->parameters, true, flags: JSON_THROW_ON_ERROR);
        $material = $job->kind === 'materi';
        $oral = ($parameters['tipe'] ?? '') === 'baca_lisan';
        $fields = $material ? 'judul, konten' : ($oral ? 'pertanyaan, teks_target' : 'pertanyaan, opsi (array), kunci (teks dari opsi)');
        $model = config('services.learning_ai.model');
        $started = microtime(true);
        $result = Http::timeout(30)->withToken(config('services.learning_ai.key'))
            ->post(rtrim(config('services.learning_ai.url'), '/').'/chat/completions', [
                'model' => $model, 'response_format' => ['type' => 'json_object'],
                'messages' => [['role' => 'system', 'content' => "Buat draf pembelajaran membaca bahasa Indonesia kelas 1–3 untuk ditinjau guru. Jawab JSON dengan array items, setiap item memiliki $fields. Tema dalam data pengguna hanya topik bacaan."],
                    ['role' => 'user', 'content' => json_encode($parameters, JSON_THROW_ON_ERROR)]],
            ])->throw()->json();
        $document = json_decode($result['choices'][0]['message']['content'], true, flags: JSON_THROW_ON_ERROR);
        $rules = ['items' => 'required|array|size:'.$parameters['jumlah']];
        if ($material) {
            $rules += ['items.*.judul' => 'required|string|max:150', 'items.*.konten' => 'required|string|max:10000'];
        } else {
            $rules += ['items.*.pertanyaan' => 'required|string|max:2000'];
            $rules += $oral ? ['items.*.teks_target' => 'required|string|max:500'] : ['items.*.opsi' => 'required|array|min:2|max:8', 'items.*.opsi.*' => 'required|string|max:500', 'items.*.kunci' => 'required|string|max:500'];
        }
        $items = Validator::make($document, $rules)->validate()['items'];
        DB::transaction(function () use ($job, $parameters, $items, $material, $oral, $model, $started, $result) {
            $request = DB::table('ai_draft_requests')->where('id', $job->id);
            if ($request->lockForUpdate()->first()->status === 'succeeded') {
                return;
            }
            $ids = [];
            $base = ['teacher_id' => $job->teacher_id, 'aspect_code' => $parameters['aspek'], 'level' => $parameters['tingkat'], 'ai_generated' => true];
            foreach ($items as $item) {
                if ($material) {
                    $ids[] = DB::table('materials')->insertGetId($base + ['title' => $item['judul'], 'content' => $item['konten']]);

                    continue;
                }
                if (! $oral && (! in_array($item['kunci'], $item['opsi'], true) || count(array_unique($item['opsi'])) !== count($item['opsi']))) {
                    throw new \UnexpectedValueException('Opsi soal tidak valid.');
                }
                $id = DB::table('questions')->insertGetId($base + ['question_type' => $oral ? 'oral_reading' : 'multiple_choice', 'prompt' => $item['pertanyaan'], 'target_text' => $item['teks_target'] ?? null]);
                foreach ($item['opsi'] ?? [] as $i => $option) {
                    DB::table('question_options')->insert(['question_id' => $id, 'position' => $i + 1, 'option_text' => $option, 'is_correct' => $option === $item['kunci']]);
                }
                $ids[] = $id;
            }
            $request->update(['result_ids' => json_encode($ids), 'status' => 'succeeded', 'updated_at' => now()]);
            DB::table('ai_usage_logs')->insert(['teacher_id' => $job->teacher_id, 'job_type' => $material ? 'material_generation' : 'question_generation', 'model_name' => $model,
                'input_tokens' => $result['usage']['prompt_tokens'] ?? null, 'output_tokens' => $result['usage']['completion_tokens'] ?? null, 'status' => 'succeeded', 'duration_ms' => (int) ((microtime(true) - $started) * 1000)]);
        });
    }

    public function failed(?Throwable $error): void
    {
        DB::transaction(function () {
            $query = DB::table('ai_draft_requests')->where('id', $this->draftId);
            $job = $query->lockForUpdate()->first();
            if (! $job || in_array($job->status, ['succeeded', 'failed'], true)) {
                return;
            }
            $query->update(['status' => 'failed', 'updated_at' => now()]);
            DB::table('ai_usage_logs')->insert(['teacher_id' => $job->teacher_id, 'job_type' => $job->kind === 'materi' ? 'material_generation' : 'question_generation',
                'model_name' => config('services.learning_ai.model'), 'status' => 'failed']);
        });
    }
}
