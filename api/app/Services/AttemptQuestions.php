<?php

namespace App\Services;

use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

enum AttemptQuestions: string
{
    case Diagnostic = 'diagnostic';
    case Practice = 'practice';

    public function snapshot(int $id, Collection $questions): void
    {
        foreach ($questions as $q) {
            $options = DB::table('question_options')->where('question_id', $q->id)->orderBy('position')->get();
            $answer = DB::table($this->value.'_attempt_answers')->insertGetId([
                $this->value.'_attempt_id' => $id, 'question_id' => $q->id, 'aspect_code' => $q->aspect_code,
                'level_snapshot' => $q->level, 'question_type' => $q->question_type, 'prompt_snapshot' => $q->prompt,
                'stimulus_text_snapshot' => $q->stimulus_text, 'stimulus_asset_key_snapshot' => $q->stimulus_asset_key,
                'target_text_snapshot' => $q->target_text, 'correct_answer_snapshot' => $options->firstWhere('is_correct', 1)?->option_text,
            ]);
            foreach ($options as $option) {
                DB::table($this->value.'_answer_options')->insert([$this->value.'_answer_id' => $answer,
                    'position' => $option->position, 'option_text_snapshot' => $option->option_text,
                    'option_asset_key_snapshot' => $option->option_asset_key, 'is_correct_snapshot' => $option->is_correct]);
            }
        }
    }

    public function saveChoice(int $id, int $questionId, string $choice): void
    {
        $row = DB::table($this->value.'_attempt_answers')->where($this->value.'_attempt_id', $id)->where('question_id', $questionId)->firstOrFail();
        abort_unless($row->question_type === 'multiple_choice', 422, 'Jawaban lisan membutuhkan rekaman.');
        $option = DB::table($this->value.'_answer_options')->where($this->value.'_answer_id', $row->id)
            ->where('option_text_snapshot', $choice)->first();
        abort_unless($option, 422, 'Pilihan tidak tersedia.');
        DB::table($this->value.'_attempt_answers')->where('id', $row->id)->update(['selected_answer' => $option->option_text_snapshot,
            'score' => $option->is_correct_snapshot ? 100 : 0, 'is_correct' => $option->is_correct_snapshot, 'answered_at' => now()]);

    }

    public function present(int $id, bool $audioAllowed): array
    {
        $answers = DB::table($this->value.'_attempt_answers')->where($this->value.'_attempt_id', $id)->orderBy('id')
            ->get(['id', 'question_id as soal_id', 'prompt_snapshot as pertanyaan', 'target_text_snapshot as teks_target', 'stimulus_text_snapshot as stimulus', 'question_type as tipe', 'selected_answer as jawaban', 'answered_at']);
        $options = DB::table($this->value.'_answer_options')->whereIn($this->value.'_answer_id', $answers->pluck('id'))
            ->orderBy('position')->get([$this->value.'_answer_id', 'option_text_snapshot'])->groupBy($this->value.'_answer_id');
        foreach ($answers as $answer) {
            $answer->terkirim = $answer->answered_at !== null;
            unset($answer->answered_at);
            $answer->opsi = $options->get($answer->id, collect())->pluck('option_text_snapshot');
        }

        return ['hasil_id' => $id, 'izin_rekaman' => $audioAllowed, 'soal' => $answers];
    }
}
