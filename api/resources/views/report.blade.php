<!doctype html>
<html lang="id"><meta charset="utf-8">
<style>body{font-family:sans-serif;font-size:11pt}table{border-collapse:collapse;width:100%}td,th{padding:5px;text-align:left;border-bottom:1px solid #bbb}</style>
<h1>Laporan perkembangan {{ $scope }}</h1>
<table><thead><tr><th>Tanggal</th><th>Siswa</th><th>Kelas</th><th>Aspek</th><th>Skor</th></tr></thead><tbody>
@forelse($rows as $row)
<tr><td>{{ $row->tanggal }}</td><td>{{ $row->nama }}</td><td>{{ $row->kelas }}</td><td>{{ str_replace('_',' ',$row->aspek) }}</td><td>{{ $row->skor }}</td></tr>
@empty
<tr><td colspan="5">Belum ada hasil pada periode ini.</td></tr>
@endforelse
</tbody></table></html>
