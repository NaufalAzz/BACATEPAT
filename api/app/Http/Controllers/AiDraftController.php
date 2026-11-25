<?php

namespace App\Http\Controllers;

use App\Jobs\GenerateDrafts;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AiDraftController
{
    public function create(Request $request, string $kind)
    {
        $rules = ['aspek' => 'required|exists:learning_aspects,code', 'tingkat' => 'required|integer|between:1,3', 'tema' => 'required|string|max:100', 'jumlah' => 'required|integer|between:1,5'];
        if ($kind === 'soal') {
            $rules['tipe'] = 'required|in:pilihan_ganda,baca_lisan';
        }
        $data = $request->validate($rules);
        abort_unless(config('services.learning_ai.key') && config('services.learning_ai.model'), 503, 'Penyedia AI belum dikonfigurasi.');

        return DB::transaction(function () use ($request, $kind, $data) {
            $teacher = $request->user()->id;
            DB::table('users')->where('id', $teacher)->lockForUpdate()->firstOrFail();
            abort_if(DB::table('ai_draft_requests')->where('teacher_id', $teacher)->whereDate('created_at', today())->count() >= 20, 429, 'Kuota harian tercapai.');
            $id = DB::table('ai_draft_requests')->insertGetId(['teacher_id' => $teacher, 'kind' => $kind, 'parameters' => json_encode($data, JSON_THROW_ON_ERROR), 'created_at' => now(), 'updated_at' => now()]);
            GenerateDrafts::dispatch($id)->onConnection('database');

            return response()->json(['data' => ['id' => $id, 'status' => 'queued']], 202);
        });
    }

    public function show(Request $request, int $id)
    {
        $row = DB::table('ai_draft_requests')->where('teacher_id', $request->user()->id)->where('id', $id)->firstOrFail();

        return ['data' => ['id' => $id, 'status' => $row->status, 'result_ids' => json_decode($row->result_ids ?? '[]')]];
    }
}
