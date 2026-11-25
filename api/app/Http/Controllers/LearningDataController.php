<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LearningDataController
{
    public function __invoke(Request $request)
    {
        $user = $request->user();
        abort_unless($user->status === 'aktif', 403);

        return DB::transaction(function () use ($user) {
            $teacher = $user->role === 'guru';
            $students = DB::table('students as s')->join('users as u', 's.user_id', '=', 'u.id')
                ->join('classes as c', 's.current_class_id', '=', 'c.id')
                ->when($teacher, fn ($q) => $q->where('c.teacher_id', $user->id),
                    fn ($q) => $q->where('s.user_id', $user->id)->where('s.status', 'aktif'))
                ->get(['s.id', 's.user_id', 'u.name', 'u.username', 's.current_class_id', 's.status', 's.guardian_name', 's.parent_consent', 's.ai_consent']);
            abort_if(! $teacher && $students->isEmpty(), 403);
            $classes = DB::table('classes')->when($teacher, fn ($q) => $q->where('teacher_id', $user->id),
                fn ($q) => $q->where('id', $students->first()->current_class_id))->get(['id', 'teacher_id', 'name', 'grade', 'school_year']);
            $owner = $teacher ? $user : DB::table('users')->find($classes->first()->teacher_id);
            $scoped = fn ($table) => DB::table($table)->whereIn('student_id', $students->pluck('id'))
                ->when($teacher, fn ($q) => $q->whereIn($table.'.class_id', $classes->pluck('id')));
            $materials = DB::table('materials')->where('teacher_id', $owner->id)->when(! $teacher, fn ($q) => $q->where('status', 'active'))
                ->get(['id', 'aspect_code', 'level', 'title', 'content', 'status']);
            $questions = DB::table('questions')->where('teacher_id', $owner->id)
                ->when(! $teacher, fn ($q) => $q->whereIn('material_id', $materials->pluck('id'))->where('review_status', 'approved')->whereIn('usage_scope', ['practice', 'both']))
                ->get(['id', 'material_id', 'aspect_code', 'level', 'question_type', 'usage_scope', 'prompt', 'stimulus_text', 'target_text', 'hint', 'review_status']);
            $options = DB::table('question_options')->whereIn('question_id', $questions->pluck('id'))->orderBy('position')
                ->get($teacher ? ['question_id', 'option_text', 'is_correct'] : ['question_id', 'option_text'])->groupBy('question_id');
            foreach ($questions as $row) {
                $row->options = $options->get($row->id, []);
            }
            $tests = DB::table('diagnostic_tests')->whereIn('class_id', $classes->pluck('id'))->when(! $teacher, fn ($q) => $q->where('status', 'active'))->get(['id', 'class_id', 'title', 'status']);
            $links = DB::table('diagnostic_test_questions')->whereIn('diagnostic_test_id', $tests->pluck('id'))->orderBy('position')->get()->groupBy('diagnostic_test_id');
            foreach ($tests as $row) {
                $row->questions = $links->get($row->id, collect())->pluck('question_id');
            }
            $diagnostics = $scoped('diagnostic_attempts')->where('diagnostic_attempts.status', 'completed')
                ->join('diagnostic_tests as t', 't.id', '=', 'diagnostic_attempts.diagnostic_test_id')
                ->get(['diagnostic_attempts.id', 'student_id', 'diagnostic_attempts.class_id', 'diagnostic_test_id', 'title', 'overall_score', 'started_at', 'diagnostic_attempts.finished_at']);

            $recordings = DB::table('voice_recordings as r')->join('students as s', 's.id', '=', 'r.student_id')
                ->leftJoin('practice_attempts as p', 'p.id', '=', 'r.practice_attempt_id')
                ->leftJoin('diagnostic_attempts as d', 'd.id', '=', 'r.diagnostic_attempt_id')
                ->leftJoin('questions as q', 'q.id', '=', 'r.question_id')
                ->leftJoin('audio_evaluations as e', 'e.recording_id', '=', 'r.id')
                ->whereIn('s.id', $students->pluck('id'))->where('s.parent_consent', true)->where('r.parent_consent_snapshot', true)
                ->when($teacher, fn ($query) => $query->whereIn(DB::raw('COALESCE(p.class_id,d.class_id)'), $classes->pluck('id')))
                ->get(['r.id', 'r.student_id', 'r.target_text_snapshot', 'r.duration_seconds', 'r.status', 'r.ai_consent_snapshot', 'q.aspect_code', 'e.accuracy_score', 'e.fluency_score', 'e.comment', 'e.advice']);

            return ['data' => [
                'teacher' => ['id' => $owner->id, 'name' => $owner->name, 'email' => $teacher ? $owner->email : null, 'retention' => $teacher ? $owner->audio_retention_days : null],
                'recordings' => $recordings, 'classes' => $classes, 'students' => $students, 'materials' => $materials, 'questions' => $questions, 'tests' => $tests, 'diagnostics' => $diagnostics,
                'practice' => $scoped('practice_attempts')->where('status', 'completed')->orderByDesc('finished_at')->get(),
                'mastery' => $scoped('mastery_history')->orderBy('recorded_at')->orderBy('id')->get(),
                'recommendations' => $scoped('recommendations')->where('status', 'active')->get(),
                'gaps' => $scoped('material_gaps')->whereNull('resolved_at')->get(),
            ]];
        });
    }
}
