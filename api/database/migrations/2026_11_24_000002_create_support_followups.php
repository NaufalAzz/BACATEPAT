<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('support_followups', function (Blueprint $table) {
            $table->foreignId('history_id')->primary()->constrained('mastery_history');
            $table->foreignId('teacher_id')->constrained('users');
            $table->dateTime('reviewed_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('support_followups');
    }
};
