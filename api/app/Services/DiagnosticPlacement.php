<?php

namespace App\Services;

use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class DiagnosticPlacement
{
    /** Called in the same transaction that completes the attempt. */
    public function apply(object $attempt, Collection $scores, ?int $revisionId = null, ?string $revisedAspect = null): void
    {
        $student = DB::table('students')->where('id', $attempt->student_id)->lockForUpdate()->firstOrFail();
        $aspects = DB::table('learning_aspects')->orderBy('sequence_no')->pluck('code');
        $target = null;
        foreach ($aspects as $aspect) {
            $score = $scores->get($aspect);
            if (! is_numeric($score)) {
                continue;
            }
            $level = $score >= 80 ? 3 : ($score >= 60 ? 2 : 1);
            if (! $revisionId || $aspect === $revisedAspect) {
                DB::table('mastery_history')->insert([
                    'student_id' => $student->id, 'class_id' => $attempt->class_id,
                    'aspect_code' => $aspect, 'observed_level' => $level, 'score' => $score,
                    'mastery_status' => [1 => 'not_mastered', 2 => 'practicing', 3 => 'mastered'][$level],
                    'source_type' => $revisionId ? 'audio_evaluation' : 'diagnostic', 'diagnostic_attempt_id' => $revisionId ? null : $attempt->id,
                    'audio_evaluation_revision_id' => $revisionId,
                    'reason' => 'Skor diagnostik per aspek.', 'recorded_at' => now(),
                ]);
            }
            if ($level < 3 && $target === null) {
                $target = ['aspect_code' => $aspect, 'target_level' => $level];
            }
        }
        if ($student->current_class_id !== $attempt->class_id) {
            return;
        }
        $active = DB::table('recommendations')->where('student_id', $student->id)->where('status', 'active');
        if ((clone $active)->where('source', 'teacher')->exists()) {
            return;
        }
        $active->update(['status' => 'superseded', 'closed_at' => now()]);
        if (! $target) {
            return;
        }
        $class = DB::table('classes')->where('id', $attempt->class_id)->firstOrFail(['teacher_id', 'grade']);
        $material = DB::table('materials')->where('teacher_id', $class->teacher_id)->where('status', 'active')->where(fn ($q) => $q->whereNull('grade')->orWhere('grade', $class->grade))
            ->where('aspect_code', $target['aspect_code'])->where('level', $target['target_level'])
            ->orderByRaw('EXISTS (SELECT 1 FROM practice_attempts WHERE student_id = ? AND material_id = materials.id)', [$student->id])
            ->orderBy('id')->value('id');
        $values = $target + ['student_id' => $student->id, 'class_id' => $attempt->class_id, 'created_at' => now()];
        if ($material === null) {
            DB::table('material_gaps')->insert($values + ['reason' => 'Materi aktif untuk hasil diagnostik ini belum tersedia.']);
        } else {
            DB::table('recommendations')->insert($values + ['material_id' => $material, 'source' => 'system', 'reason' => 'Aspek pertama yang perlu dilatih berdasarkan diagnostik.']);
        }
    }
}
