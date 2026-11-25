<?php

use App\Models\User;
use Illuminate\Contracts\Http\Kernel;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$kernel = $app->make(Kernel::class);
$kernel->bootstrap();
if (getenv('BACATEPAT_INTEGRATION_TEST') !== '1') {
    throw new RuntimeException('Use the disposable integration database.');
}
DB::beginTransaction();
try {
    $teacher = new User;
    $teacher->forceFill(['name' => 'Guru kelas lain', 'username' => 'test.'.bin2hex(random_bytes(6)),
        'role' => 'guru', 'status' => 'aktif', 'password_hash' => Hash::make(bin2hex(random_bytes(32)))])->save();
    $token = $teacher->createToken('integration')->plainTextToken;
    $student = DB::table('students as s')->join('users as u', 's.user_id', '=', 'u.id')->where('u.username', 'demo.siswa.andi')->firstOrFail(['s.id', 's.current_class_id']);
    $record = DB::table('voice_recordings')->where('student_id', $student->id)->firstOrFail();
    $evaluation = DB::table('audio_evaluations')->where('recording_id', $record->id)->value('id');
    $checks = [
        ['GET', 'guru/kelas', [], 200],
        ['GET', 'guru/siswa/'.$student->id, [], 404],
        ['GET', 'guru/laporan/kelas/'.$student->current_class_id, [], 404],
        ['PATCH', 'guru/siswa/'.$student->id.'/status', ['aktif' => false], 404],
        ['PUT', 'guru/siswa/'.$student->id.'/persetujuan', ['persetujuan_ai' => true, 'persetujuan_wali' => true], 404],
        ['GET', 'guru/rekaman/'.$record->id.'/audio', [], 404],
        ['GET', 'siswa/beranda', [], 403],
    ];
    if ($evaluation) {
        $checks[] = ['PUT', 'guru/evaluasi/'.$evaluation, ['nilai_ketepatan' => 0, 'nilai_kelancaran' => 0, 'komentar' => 'uji', 'saran' => 'uji'], 404];
    }
    foreach ($checks as [$method,$path,$input,$expected]) {
        Auth::forgetGuards();
        $request = Request::create('/api/v1/'.$path, $method, $input, [], [], ['HTTP_ACCEPT' => 'application/json', 'HTTP_AUTHORIZATION' => 'Bearer '.$token]);
        $response = $kernel->handle($request);
        if ($response->getStatusCode() !== $expected || ($path === 'guru/kelas' && json_decode($response->getContent(), true)['data'] !== [])) {
            throw new RuntimeException("Unexpected authorization result for $method $path");
        }
    }
    echo "Cross-class authorization passed.\n";
} finally {
    DB::rollBack();
}
