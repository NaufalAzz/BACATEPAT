import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

import '../../../core/api/bacatepat_api.dart';
import '../audio/reading_recorder.dart';

class ServerDiagnosticPage extends StatefulWidget {
  const ServerDiagnosticPage({super.key, required this.api, this.material});
  final Map<String, dynamic>? material;
  final BacaTepatApi api;

  @override
  State<ServerDiagnosticPage> createState() => _ServerDiagnosticPageState();
}

class _ServerDiagnosticPageState extends State<ServerDiagnosticPage> {
  bool get practice => widget.material != null;
  String get prefix => practice ? 'siswa/latihan' : 'siswa/diagnostik/hasil';
  late final tests = practice
      ? Future.value({
          'data': [
            {
              'id': widget.material!['materi_id'],
              'judul': widget.material!['judul'],
            },
          ],
        })
      : widget.api.request('siswa/diagnostik/aktif');
  Map<String, dynamic>? attempt;
  Map<String, dynamic>? result;
  bool saving = false;

  Future<void> run(Future<void> Function() action) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await action();
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> start(int id) => run(() async {
    final response = await widget.api.request(
      practice ? 'siswa/latihan/mulai' : 'siswa/diagnostik/mulai',
      body: {if (practice) 'materi_id': id else 'tes_id': id},
    );
    attempt = response['data'];
  });

  Future<void> select(Map<String, dynamic> question, String answer) =>
      run(() async {
        await widget.api.request(
          '$prefix/${attempt!['hasil_id']}/jawaban',
          body: {'soal_id': question['soal_id'], 'jawaban': answer},
        );
        question['jawaban'] = answer;
      });

  Future<void> finish() => run(() async {
    final response = await widget.api.request(
      '$prefix/${attempt!['hasil_id']}/selesai',
      body: {},
    );
    result = response['data'];
  });

  @override
  Widget build(BuildContext context) {
    final current = attempt;
    final scores = result == null
        ? null
        : practice
        ? {'Nilai latihan': result!['skor']}
        : result!['skor'] as Map<String, dynamic>;
    return Scaffold(
      appBar: AppBar(
        title: Text(practice ? 'Latihan membaca' : 'Tes diagnostik'),
      ),
      body: scores != null
          ? ListView(
              children: [
                for (final score in scores.entries)
                  ListTile(
                    title: Text(score.key.replaceAll('_', ' ')),
                    trailing: Text('${score.value ?? "Menunggu penilaian"}'),
                  ),
              ],
            )
          : current == null
          ? FutureBuilder(
              future: tests,
              builder: (context, state) {
                if (state.hasError) {
                  return Center(child: Text(state.error.toString()));
                }
                if (!state.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = state.requireData['data'] as List;
                if (rows.isEmpty) {
                  return const Center(child: Text('Belum ada tes aktif.'));
                }
                return ListView(
                  children: [
                    for (final test in rows)
                      ListTile(
                        title: Text(test['judul']),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: saving ? null : () => start(test['id']),
                      ),
                  ],
                );
              },
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final question in current['soal']) ...[
                  ListTile(
                    title: Text(question['pertanyaan']),
                    subtitle: Text(
                      question['stimulus'] ?? question['teks_target'] ?? '',
                    ),
                  ),
                  if (question['tipe'] == 'oral_reading' &&
                      current['izin_rekaman'] != true &&
                      question['terkirim'] != true)
                    const ListTile(
                      title: Text(
                        'Guru perlu mencatat izin wali sebelum kamu merekam bacaan.',
                      ),
                    ),
                  if (question['tipe'] == 'oral_reading' &&
                      current['izin_rekaman'] == true &&
                      question['terkirim'] != true)
                    ReadingRecorder(
                      key: ValueKey(question['id']),
                      onSubmit: (bytes) => run(() async {
                        await widget.api.uploadRecording(bytes, 'bacaan.wav', {
                          'soal_id': question['soal_id'].toString(),
                          if (practice)
                            'hasil_latihan_id': attempt!['hasil_id'].toString()
                          else
                            'hasil_diagnostik_id': attempt!['hasil_id']
                                .toString(),
                        });
                        question['terkirim'] = true;
                      }),
                    ),
                  if (question['tipe'] == 'oral_reading' &&
                      (current['izin_rekaman'] == true ||
                          question['terkirim'] == true))
                    TextButton.icon(
                      icon: const Icon(Icons.audio_file),
                      label: Text(
                        question['terkirim'] == true
                            ? 'Rekaman terkirim'
                            : 'Pilih rekaman bacaan',
                      ),
                      onPressed: saving || question['terkirim'] == true
                          ? null
                          : () => run(() async {
                              final file = await openFile(
                                acceptedTypeGroups: [
                                  const XTypeGroup(
                                    label: 'Audio',
                                    extensions: ['wav', 'm4a', 'aac', 'mp3'],
                                    mimeTypes: ['audio/*'],
                                    uniformTypeIdentifiers: ['public.audio'],
                                  ),
                                ],
                              );
                              if (file == null) return;
                              if (await file.length() > 5242880) {
                                throw const ApiError(
                                  'Ukuran maksimum 5 MB.',
                                  422,
                                );
                              }
                              await widget.api.uploadRecording(
                                await file.readAsBytes(),
                                file.name,
                                {
                                  'soal_id': question['soal_id'].toString(),
                                  if (practice)
                                    'hasil_latihan_id': attempt!['hasil_id']
                                        .toString()
                                  else
                                    'hasil_diagnostik_id': attempt!['hasil_id']
                                        .toString(),
                                },
                              );
                              question['terkirim'] = true;
                            }),
                    ),
                  for (final option in question['opsi'])
                    ListTile(
                      title: Text(option),
                      leading: Icon(
                        question['jawaban'] == option
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      onTap: saving ? null : () => select(question, option),
                    ),
                ],
                FilledButton(
                  onPressed: saving ? null : finish,
                  child: const Text('Selesaikan tes'),
                ),
              ],
            ),
    );
  }
}
