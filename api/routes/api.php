<?php

use App\Http\Controllers\ActivityController;
use App\Http\Controllers\AiDraftController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ClassController;
use App\Http\Controllers\ContentController;
use App\Http\Controllers\DiagnosticController;
use App\Http\Controllers\PracticeController;
use App\Http\Controllers\ProgressController;
use App\Http\Controllers\RecordingController;
use App\Http\Controllers\StudentAdminController;
use App\Http\Controllers\StudentOverviewController;
use App\Http\Controllers\TeacherReviewController;
use App\Http\Middleware\RequireRole;
use Illuminate\Support\Facades\Route;

Route::pattern('id', '[0-9]+');
Route::get('health', fn () => ['service' => 'bacatepat', 'status' => 'ok']);
Route::post('auth/login', [AuthController::class, 'login'])->middleware('throttle:login');

Route::middleware(['auth:sanctum', 'throttle:60,1'])->group(function () {
    Route::get('auth/me', [AuthController::class, 'me']);
    Route::post('auth/logout', [AuthController::class, 'logout']);
    Route::put('auth/password', [AuthController::class, 'password'])->middleware(RequireRole::class.':guru');

    Route::prefix('guru')->middleware(RequireRole::class.':guru')->group(function () {
        Route::get('ai/permintaan/{id}', [AiDraftController::class, 'show']);
        Route::post('ai/{kind}', [AiDraftController::class, 'create'])->whereIn('kind', ['materi', 'soal']);

        Route::get('dashboard', [ActivityController::class, 'dashboard']);

        Route::get('diagnostik', [ContentController::class, 'tests']);
        Route::post('diagnostik', [ContentController::class, 'createTest']);
        Route::put('diagnostik/{id}', [ContentController::class, 'createTest']);
        Route::get('diagnostik/{id}/hasil', [TeacherReviewController::class, 'results']);
        Route::patch('diagnostik/{id}/status', [ContentController::class, 'testStatus']);

        Route::put('evaluasi/{id}', [RecordingController::class, 'revise']);

        Route::get('kelas', [ClassController::class, 'index']);
        Route::post('kelas', [ClassController::class, 'save']);
        Route::delete('kelas/{id}', [ClassController::class, 'destroy']);
        Route::put('kelas/{id}', [ClassController::class, 'save']);

        Route::get('laporan/{scope}/{id}', [ProgressController::class, 'report'])->whereIn('scope', ['siswa', 'kelas']);

        Route::get('materi', [ContentController::class, 'materials']);
        Route::post('materi', [ContentController::class, 'material']);
        Route::put('materi/{id}', [ContentController::class, 'material']);
        Route::get('materi/{id}', [ContentController::class, 'materialDetail']);
        Route::patch('materi/{id}/status', [ContentController::class, 'materialStatus']);

        Route::get('perkembangan/kelas/{id}', [ProgressController::class, 'classroom']);
        Route::get('perkembangan/siswa/{id}', [ProgressController::class, 'student']);

        Route::put('profil', [AuthController::class, 'updateProfile']);

        Route::get('rekaman', [RecordingController::class, 'index']);
        Route::get('rekaman/{id}', [RecordingController::class, 'detail']);
        Route::delete('rekaman/{id}', [RecordingController::class, 'destroy']);
        Route::post('rekaman/{id}/analisis-ulang', [RecordingController::class, 'retryAnalysis']);
        Route::get('rekaman/{id}/audio', [RecordingController::class, 'stream']);
        Route::post('rekaman/{id}/evaluasi', [RecordingController::class, 'evaluate']);

        Route::get('siswa', [ClassController::class, 'students']);
        Route::post('siswa', [StudentAdminController::class, 'create']);
        Route::get('siswa/{id}', [StudentAdminController::class, 'detail']);
        Route::put('siswa/{id}', [StudentAdminController::class, 'edit']);
        Route::get('siswa/{id}/evaluasi', [ActivityController::class, 'evaluations']);
        Route::get('siswa/{id}/diagnostik', [ActivityController::class, 'diagnostic']);
        Route::patch('siswa/{id}/kelas', [StudentAdminController::class, 'transfer']);
        Route::get('siswa/{id}/latihan', [ActivityController::class, 'practice']);
        Route::put('siswa/{id}/persetujuan', [StudentAdminController::class, 'consent']);
        Route::put('siswa/{id}/rekomendasi', [TeacherReviewController::class, 'recommend']);
        Route::post('siswa/{id}/reset-password', [StudentAdminController::class, 'resetPassword']);
        Route::patch('siswa/{id}/status', [StudentAdminController::class, 'status']);

        Route::get('soal', [ContentController::class, 'questions']);
        Route::post('soal', [ContentController::class, 'question']);
        Route::put('soal/{id}', [ContentController::class, 'question']);
        Route::delete('soal/{id}', [ContentController::class, 'deleteQuestion']);
        Route::patch('soal/{id}/review', [ContentController::class, 'review']);
        Route::get('pendampingan', [TeacherReviewController::class, 'support']);
        Route::patch('siswa/{id}/pendampingan', [TeacherReviewController::class, 'followUp']);
    });

    Route::prefix('siswa')->middleware(RequireRole::class.':siswa')->group(function () {
        Route::get('beranda', StudentOverviewController::class);

        Route::get('diagnostik/aktif', [DiagnosticController::class, 'active']);
        Route::get('diagnostik/hasil', [DiagnosticController::class, 'results']);
        Route::post('diagnostik/hasil/{id}/jawaban', [DiagnosticController::class, 'answer']);
        Route::post('diagnostik/hasil/{id}/selesai', [DiagnosticController::class, 'finish']);
        Route::post('diagnostik/mulai', [DiagnosticController::class, 'start']);

        Route::get('evaluasi', [ActivityController::class, 'evaluations']);

        Route::get('latihan', [PracticeController::class, 'available']);
        Route::post('latihan/mulai', [PracticeController::class, 'start']);
        Route::get('latihan/riwayat', [ActivityController::class, 'practice']);
        Route::post('latihan/{id}/jawaban', [PracticeController::class, 'answer']);
        Route::post('latihan/{id}/selesai', [PracticeController::class, 'finish']);

        Route::get('perkembangan', [ProgressController::class, 'student']);

        Route::get('profil', [AuthController::class, 'me']);

        Route::post('rekaman', [RecordingController::class, 'upload']);
    });
});
