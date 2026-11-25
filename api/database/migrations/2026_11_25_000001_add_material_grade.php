<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /** Older teacher-authored materials remain shared across grades. */
    public function up(): void
    {
        if (! Schema::hasColumn('materials', 'grade')) {
            Schema::table('materials', fn (Blueprint $table) => $table->unsignedTinyInteger('grade')->nullable());
        }
        foreach (json_decode(file_get_contents(resource_path('materi-kurikulum.json')), true, flags: JSON_THROW_ON_ERROR) as $entry) {
            DB::table('materials')->whereNull('grade')->where('title', $entry['title'])->where('content', $entry['content'])->update(['grade' => $entry['grade']]);
        }
    }

    public function down(): void
    {
        Schema::table('materials', fn (Blueprint $table) => $table->dropColumn('grade'));
    }
};
