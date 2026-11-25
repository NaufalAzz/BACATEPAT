<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ContentController
{
    private function owned(string $table, Request $request)
    {
        return DB::table($table)->where('teacher_id', $request->user()->id);
    }

    public function materialDetail(Request $request, int $id)
    {
        return ['data' => $this->owned('materials', $request)->where('id', $id)->firstOrFail()];
    }

    public function deleteQuestion(Request $request, int $id)
    {
        return DB::transaction(function () use ($request, $id) {
            $owned = $this->owned('questions', $request)->where('id', $id);
            $owned->lockForUpdate()->firstOrFail();
            foreach (['diagnostic_test_questions', 'diagnostic_attempt_answers', 'practice_attempt_answers'] as $table) {
                abort_if(DB::table($table)->where('question_id', $id)->exists(), 409, 'Soal ini sudah dipakai.');
            }
            $owned->delete();

            return ['success' => true];
        });
    }

    public function materials(Request $request)
    {
        $query = $this->owned('materials', $request);
        $filters = $request->validate(['status' => 'sometimes|in:aktif,arsip,draft', 'aspek' => 'sometimes|exists:learning_aspects,code', 'tingkat' => 'sometimes|integer|between:1,3']);
        if (isset($filters['status'])) {
            $query->where('status', ['aktif' => 'active', 'arsip' => 'archived', 'draft' => 'draft'][$filters['status']]);
        }
        foreach (['aspek' => 'aspect_code', 'tingkat' => 'level'] as $key => $column) {
            if (isset($filters[$key])) {
                $query->where($column, $filters[$key]);
            }
        }

        return $query->orderByDesc('id')->paginate(30);
    }

    public function material(Request $request, ?int $id = null)
    {
        $data = $request->validate(['judul' => 'required|string|max:150', 'aspek' => 'required|exists:learning_aspects,code',
            'tingkat_kesulitan' => 'required|integer|between:1,3', 'konten' => 'required|string|max:100000']);
        $values = ['title' => $data['judul'], 'aspect_code' => $data['aspek'], 'level' => $data['tingkat_kesulitan'], 'content' => $data['konten']];
        if ($id === null) {
            $id = DB::table('materials')->insertGetId($values + ['teacher_id' => $request->user()->id]);

            return response()->json(['data' => ['id' => $id]], 201);
        }
        $owned = $this->owned('materials', $request)->where('id', $id);
        abort_unless($owned->exists(), 404);
        $owned->update($values);

        return ['data' => ['id' => $id]];
    }

    public function materialStatus(Request $request, int $id)
    {
        $data = $request->validate(['status' => 'required|in:aktif,arsip']);
        $owned = $this->owned('materials', $request)->where('id', $id);
        abort_unless($owned->exists(), 404);
        $owned->update(['status' => $data['status'] === 'aktif' ? 'active' : 'archived']);

        return ['success' => true];
    }

    public function questions(Request $request)
    {
        $query = $this->owned('questions', $request);
        if ($request->filled('status_review')) {
            $query->where('review_status', $request->query('status_review'));
        }
        if ($request->filled('penggunaan')) {
            $query->whereIn('usage_scope', [$request->query('penggunaan'), 'both']);
        }
        $questions = $query->orderByDesc('id')->paginate(30);
        $options = DB::table('question_options')->whereIn('question_id', $questions->pluck('id'))->orderBy('position')
            ->get(['question_id', 'option_text', 'is_correct'])->groupBy('question_id');
        foreach ($questions as $question) {
            $question->options = $options->get($question->id, collect());
        }

        return $questions;
    }

    public function question(Request $request, ?int $id = null)
    {
        $data = $request->validate(['aspek' => 'required|exists:learning_aspects,code', 'tingkat_kesulitan' => 'required|integer|between:1,3',
            'tipe' => 'required|in:pilihan_ganda,baca_lisan', 'penggunaan' => 'required|in:diagnostik,latihan,keduanya',
            'pertanyaan' => 'required|string|max:10000', 'opsi_jawaban' => 'required_if:tipe,pilihan_ganda|array|min:2|max:10',
            'opsi_jawaban.*' => 'required|string|max:500|distinct', 'kunci_jawaban' => 'required_if:tipe,pilihan_ganda|string|max:500',
            'teks_target' => 'required_if:tipe,baca_lisan|string|max:500',
            'materi_id' => ['nullable', 'integer', Rule::exists('materials', 'id')->where('teacher_id', $request->user()->id)]]);
        $oral = $data['tipe'] === 'baca_lisan';
        abort_if(! $oral && ! in_array($data['kunci_jawaban'], $data['opsi_jawaban'], true), 422, 'Kunci harus ada di opsi.');

        return DB::transaction(function () use ($data, $request, $oral, $id) {
            $create = $id === null;
            $values = ['teacher_id' => $request->user()->id, 'aspect_code' => $data['aspek'],
                'material_id' => $data['materi_id'] ?? null, 'level' => $data['tingkat_kesulitan'], 'prompt' => $data['pertanyaan'],
                'question_type' => $oral ? 'oral_reading' : 'multiple_choice', 'target_text' => $oral ? $data['teks_target'] : null,
                'usage_scope' => ['diagnostik' => 'diagnostic', 'latihan' => 'practice', 'keduanya' => 'both'][$data['penggunaan']]];
            if ($create) {
                $id = DB::table('questions')->insertGetId($values);
            } else {
                $owned = $this->owned('questions', $request)->where('id', $id);
                $owned->lockForUpdate()->firstOrFail();
                abort_if(DB::table('diagnostic_test_questions as t')->join('diagnostic_tests as d', 'd.id', '=', 't.diagnostic_test_id')
                    ->where('t.question_id', $id)->where('d.status', 'active')->exists(), 409, 'Soal dipakai tes aktif.');
                $owned->update($values + ['review_status' => 'draft', 'reviewed_at' => null, 'reviewed_by_teacher_id' => null]);
                DB::table('question_options')->where('question_id', $id)->delete();
            }
            if (! $oral) {
                foreach (array_values($data['opsi_jawaban']) as $index => $text) {
                    DB::table('question_options')->insert(['question_id' => $id, 'position' => $index + 1, 'option_text' => $text, 'is_correct' => $text === $data['kunci_jawaban']]);
                }
            }

            return response()->json(['data' => ['id' => $id]], $create ? 201 : 200);
        });
    }

    public function review(Request $request, int $id)
    {
        $data = $request->validate(['status_review' => 'required|in:disetujui,ditolak']);
        $question = $this->owned('questions', $request)->where('id', $id);
        abort_unless($question->exists(), 404);
        $question->update(['review_status' => $data['status_review'] === 'disetujui' ? 'approved' : 'rejected',
            'reviewed_at' => now(), 'reviewed_by_teacher_id' => $request->user()->id]);

        return ['success' => true];
    }

    public function tests(Request $request)
    {
        $query = $this->owned('diagnostic_tests', $request);
        if ($request->filled('kelas_id')) {
            $query->where('class_id', $request->integer('kelas_id'));
        }

        return $query->orderByDesc('id')->paginate(30);
    }

    public function testDetail(Request $request, int $id)
    {
        $test = $this->owned('diagnostic_tests', $request)->where('id', $id)->firstOrFail();
        $test->soal = DB::table('diagnostic_test_questions as t')->join('questions as q', 'q.id', '=', 't.question_id')
            ->where('t.diagnostic_test_id', $id)->orderBy('t.position')->get(['t.question_id', 'q.aspect_code']);

        return ['data' => $test];
    }

    public function createTest(Request $request, ?int $id = null)
    {
        $data = $request->validate(['judul' => 'required|string|max:150', 'kelas_id' => ['required', 'integer',
            Rule::exists('classes', 'id')->where('teacher_id', $request->user()->id)], 'soal' => 'required|array|min:1|max:100',
            'soal.*.soal_id' => 'required|integer|distinct', 'soal.*.urutan' => 'required|integer|between:1,100|distinct']);

        return DB::transaction(function () use ($data, $request, $id) {
            $create = $id === null;
            $ids = array_column($data['soal'], 'soal_id');
            $questions = $this->owned('questions', $request)->whereIn('id', $ids)->where('review_status', 'approved')
                ->whereIn('usage_scope', ['diagnostic', 'both'])->lockForUpdate()->get();
            abort_if($questions->count() !== count($ids), 422, 'Pilih soal diagnostik yang sudah disetujui.');
            $values = ['teacher_id' => $request->user()->id, 'class_id' => $data['kelas_id'], 'title' => $data['judul']];
            if ($create) {
                $id = DB::table('diagnostic_tests')->insertGetId($values);
            } else {
                $owned = $this->owned('diagnostic_tests', $request)->where('id', $id);
                abort_unless($owned->lockForUpdate()->firstOrFail()->status === 'draft', 409, 'Hanya draf dapat diubah.');
                $owned->update($values);
                DB::table('diagnostic_test_questions')->where('diagnostic_test_id', $id)->delete();
            }
            foreach ($data['soal'] as $item) {
                DB::table('diagnostic_test_questions')->insert(['diagnostic_test_id' => $id, 'question_id' => $item['soal_id'], 'position' => $item['urutan']]);
            }

            return response()->json(['data' => ['id' => $id]], $create ? 201 : 200);
        });
    }

    public function testStatus(Request $request, int $id)
    {
        $data = $request->validate(['status' => 'required|in:aktif,selesai']);

        return DB::transaction(function () use ($request, $id, $data) {
            $owned = $this->owned('diagnostic_tests', $request)->where('id', $id);
            $test = $owned->lockForUpdate()->firstOrFail();
            if ($data['status'] === 'aktif') {
                abort_unless($test->status === 'draft', 409);
                $questions = DB::table('diagnostic_test_questions as t')->join('questions as q', 'q.id', '=', 't.question_id')
                    ->where('t.diagnostic_test_id', $id)->get(['q.aspect_code', 'q.review_status']);
                abort_if($questions->pluck('aspect_code')->unique()->count() !== 4 || $questions->contains(fn ($q) => $q->review_status !== 'approved'), 422, 'Tes membutuhkan soal disetujui untuk keempat aspek.');
                $owned->update(['status' => 'active', 'activated_at' => now()]);
            } else {
                abort_unless($test->status === 'active', 409);
                $owned->update(['status' => 'finished', 'finished_at' => now()]);
            }

            return ['success' => true];
        });
    }
}
