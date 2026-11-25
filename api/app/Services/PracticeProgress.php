<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

class PracticeProgress
{
    public function apply(object $attempt, ?int $revisionId = null): void
    {
        $student = DB::table('students')->where('id', $attempt->student_id)->lockForUpdate()->firstOrFail();
        $aspect = $attempt->aspect_code;
        $level = $attempt->level_snapshot;
        $score = $attempt->score;
        $previous = DB::table('mastery_history')->where('student_id', $student->id)->where('aspect_code', $aspect)->orderByDesc('id')->value('score');
        $prior = DB::table('practice_attempts')->where('student_id', $student->id)->where('aspect_code', $aspect)
            ->where('level_snapshot', $level)->where('status', 'completed')->where('id', '!=', $attempt->id)
            ->orderByDesc('finished_at')->orderByDesc('id')->limit(2)->pluck('score');
        $mastered = false;
        $support = $previous !== null && $previous - $score >= 20;
        $reason = 'Penguatan pada aspek dan tingkat saat ini.';
        $target = $aspect;
        if ($score >= 80 && $prior->isNotEmpty() && $prior->first() >= 80) {
            if ($level < 3) {
                $level++;
                $reason = 'Dua latihan mencapai ambang penguasaan.';
            } else {
                $mastered = true;
                $sequence = DB::table('learning_aspects')->where('code', $aspect)->value('sequence_no');
                $target = DB::table('learning_aspects')->where('sequence_no', '>', $sequence)->orderBy('sequence_no')->pluck('code')
                    ->first(fn ($code) => DB::table('mastery_history')->where('student_id', $student->id)->where('aspect_code', $code)->orderByDesc('id')->value('mastery_status') !== 'mastered');
                $level = 1;
                $reason = 'Aspek telah dikuasai pada tingkat tertinggi.';
            }
        } elseif ($score < 60 && $prior->count() === 2 && $prior->max() < 60) {
            $support = $support || $level === 1;
            $level = max(1, $level - 1);
            $reason = 'Tiga latihan berturut-turut di bawah 60.';
        }
        DB::table('mastery_history')->insert(['student_id' => $student->id, 'class_id' => $attempt->class_id, 'aspect_code' => $aspect,
            'observed_level' => $attempt->level_snapshot, 'target_aspect_code' => $target, 'target_level' => $target ? $level : null,
            'score' => $score, 'mastery_status' => $mastered ? 'mastered' : ($score < 60 ? 'not_mastered' : 'practicing'),
            'source_type' => $revisionId ? 'audio_evaluation' : 'practice',
            'audio_evaluation_revision_id' => $revisionId,
            'practice_attempt_id' => $revisionId ? null : $attempt->id, 'needs_teacher_support' => $support, 'reason' => $reason, 'recorded_at' => now()]);
        $active = DB::table('recommendations')->where('student_id', $student->id)->where('status', 'active')->first();
        if ($student->current_class_id !== $attempt->class_id || ($active && $active->source === 'teacher' && $active->id !== $attempt->recommendation_id)) {
            return;
        }
        if ($active) {
            $same = $active->id === $attempt->recommendation_id;
            DB::table('recommendations')->where('id', $active->id)->update(['status' => $same ? 'completed' : 'superseded',
                'closed_at' => now(), 'completed_by_practice_attempt_id' => $same ? $attempt->id : null]);
        }
        if (! $target) {
            return;
        }
        $class = DB::table('classes')->where('id', $attempt->class_id)->firstOrFail(['teacher_id', 'grade']);
        $material = DB::table('materials')->where('teacher_id', $class->teacher_id)->where('status', 'active')->where(fn ($q) => $q->whereNull('grade')->orWhere('grade', $class->grade))->where('aspect_code', $target)->where('level', $level)
            ->orderByRaw('id = ? '.($score < 60 ? 'DESC' : 'ASC'), [$attempt->material_id])->orderBy('id')->value('id');
        $values = ['student_id' => $student->id, 'class_id' => $attempt->class_id, 'aspect_code' => $target, 'target_level' => $level, 'created_at' => now(), 'reason' => $reason];
        if ($material) {
            DB::table('recommendations')->insert($values + ['material_id' => $material, 'source' => 'system']);
        } else {
            DB::table('material_gaps')->insert($values);
        }
    }
}
