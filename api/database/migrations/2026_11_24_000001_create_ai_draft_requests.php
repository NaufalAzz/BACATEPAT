<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_draft_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('teacher_id')->constrained('users');
            $table->enum('kind', ['materi', 'soal']);
            $table->json('parameters');
            $table->string('status', 20)->default('queued');
            $table->json('result_ids')->nullable();
            $table->timestamps();
            $table->index(['teacher_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_draft_requests');
    }
};
