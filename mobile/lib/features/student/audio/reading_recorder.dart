import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

class ReadingRecorder extends StatefulWidget {
  const ReadingRecorder({super.key, required this.onSubmit});
  final Future<void> Function(Uint8List) onSubmit;
  @override
  State<ReadingRecorder> createState() => _ReadingRecorderState();
}

class _ReadingRecorderState extends State<ReadingRecorder> {
  final recorder = AudioRecorder();
  final player = AudioPlayer();
  Timer? limit;
  Future<Uint8List>? recording;
  Uint8List? preview;
  String? error;
  bool busy = false;

  @override
  void dispose() {
    limit?.cancel();
    unawaited(recorder.dispose());
    unawaited(player.dispose());
    super.dispose();
  }

  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(
          () => error =
              'Perekaman gagal. Periksa izin mikrofon atau pilih file audio.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> start() async {
    await player.stop();
    if (!await recorder.hasPermission()) {
      error = 'Izinkan mikrofon untuk merekam.';
      return;
    }
    final stream = await recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    final buffer = BytesBuilder(copy: false);
    recording = stream
        .fold<BytesBuilder>(buffer, (b, chunk) => b..add(chunk))
        .then((b) => b.takeBytes());
    preview = null;
    limit = Timer(const Duration(seconds: 59), () {
      if (mounted) unawaited(perform(stop));
    });
  }

  Future<void> stop() async {
    limit?.cancel();
    await recorder.stop();
    final pcm = await recording!;
    recording = null;
    if (pcm.length < 32000) {
      error = 'Rekam minimal satu detik.';
      return;
    }
    final length = pcm.length.clamp(0, 60 * 32000);
    final bytes = Uint8List(44 + length);
    final header = ByteData.sublistView(bytes);
    bytes.setAll(0, ascii.encode('RIFF'));
    header.setUint32(4, 36 + length, Endian.little);
    bytes.setAll(8, ascii.encode('WAVEfmt '));
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, 16000, Endian.little);
    header.setUint32(28, 32000, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    bytes.setAll(36, ascii.encode('data'));
    header.setUint32(40, length, Endian.little);
    bytes.setRange(44, 44 + length, pcm);
    preview = bytes;
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (error != null) Text(error!),
      Wrap(
        children: [
          TextButton.icon(
            onPressed: busy
                ? null
                : () => perform(recording == null ? start : stop),
            icon: Icon(recording == null ? Icons.mic : Icons.stop),
            label: Text(recording == null ? 'Rekam bacaan' : 'Selesai merekam'),
          ),
          if (preview != null) ...[
            TextButton(
              onPressed: busy
                  ? null
                  : () => perform(
                      () => player.play(
                        BytesSource(preview!, mimeType: 'audio/wav'),
                      ),
                    ),
              child: const Text('Dengarkan'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () => perform(() => widget.onSubmit(preview!)),
              child: const Text('Kirim rekaman'),
            ),
          ],
        ],
      ),
    ],
  );
}
