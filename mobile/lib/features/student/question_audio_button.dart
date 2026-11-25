import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/theme/app_tokens.dart';
import 'question_speech_config.dart';

export 'question_speech_config.dart';

abstract interface class QuestionSpeechEngine {
  set onStart(VoidCallback? callback);
  set onComplete(VoidCallback? callback);
  set onError(VoidCallback? callback);

  QuestionSpeechVoiceInfo? get selectedVoiceInfo;
  Future<bool> supportsIndonesian();
  Future<void> configure();
  Future<void> speak(
    String text, {
    QuestionSpeechKind kind = QuestionSpeechKind.instruction,
  });
  Future<void> stop();
}

class FlutterTtsQuestionSpeechEngine implements QuestionSpeechEngine {
  final FlutterTts _tts = FlutterTts();
  Map<String, String>? _preferredAndroidVoice;
  QuestionSpeechVoiceInfo? _selectedVoiceInfo;

  @override
  QuestionSpeechVoiceInfo? get selectedVoiceInfo => _selectedVoiceInfo;

  @override
  set onStart(VoidCallback? callback) =>
      _tts.setStartHandler(callback ?? () {});

  @override
  set onComplete(VoidCallback? callback) =>
      _tts.setCompletionHandler(callback ?? () {});

  @override
  set onError(VoidCallback? callback) =>
      _tts.setErrorHandler((_) => callback?.call());

  @override
  Future<bool> supportsIndonesian() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        _preferredAndroidVoice = chooseIndonesianOfflineVoice(
          await _indonesianAndroidVoices(),
        );
        return _preferredAndroidVoice != null;
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        final languages = await _tts.getLanguages;
        return languages is List && languages.any(_isIndonesianLocale);
      }
      return await _tts.isLanguageAvailable('id-ID') == true;
    } catch (_) {
      if (defaultTargetPlatform == TargetPlatform.android) return false;
      try {
        final languages = await _tts.getLanguages;
        return languages is List && languages.any(_isIndonesianLocale);
      } catch (_) {
        return false;
      }
    }
  }

  bool _isIndonesianLocale(Object? language) {
    final normalized = language.toString().replaceAll('_', '-').toLowerCase();
    return normalized == 'id' || normalized.startsWith('id-');
  }

  @override
  Future<void> configure() async {
    await _tts.setLanguage('id-ID');
    if (defaultTargetPlatform == TargetPlatform.android) {
      final voice = _preferredAndroidVoice;
      if (voice == null) {
        throw StateError('No installed Indonesian voice is available.');
      }
      final selected = await _tts.setVoice({
        'name': voice['name']!,
        'locale': voice['locale']!,
      });
      if (selected == 0) {
        throw StateError(
          'The installed Indonesian voice could not be selected.',
        );
      }
      _selectedVoiceInfo = QuestionSpeechVoiceInfo.fromAndroidMap(voice);
      if (kDebugMode) {
        String? engine;
        try {
          engine = (await _tts.getDefaultEngine)?.toString();
        } catch (_) {
          // Voice identity remains useful when the engine name is unavailable.
        }
        debugPrint(
          '[BacaTepat TTS] setVoice accepted: '
          '${_selectedVoiceInfo!.toDiagnosticString(engine: engine)}',
        );
      }
    }
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(false);
  }

  @override
  Future<void> speak(
    String text, {
    QuestionSpeechKind kind = QuestionSpeechKind.instruction,
  }) async {
    final profile = questionSpeechProfileFor(kind);
    await _tts.setSpeechRate(profile.rate);
    await _tts.setPitch(profile.pitch);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  Future<List<Map<String, String>>> _indonesianAndroidVoices() async {
    final voices = await _tts.getVoices;
    if (voices is! List) return const [];
    return voices
        .whereType<Map>()
        .map(
          (voice) => voice.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ),
        )
        .where((voice) {
          final locale = voice['locale']?.replaceAll('_', '-').toLowerCase();
          return locale == 'id' || (locale?.startsWith('id-') ?? false);
        })
        .where((voice) => voice['network_required'] == '0')
        .where(
          (voice) =>
              !(voice['features']?.toLowerCase().contains('notinstalled') ??
                  false),
        )
        .toList();
  }
}

@visibleForTesting
Map<String, String>? chooseIndonesianOfflineVoice(
  Iterable<Map<String, String>> voices,
) {
  final candidates = voices.where((voice) {
    final locale = voice['locale']?.replaceAll('_', '-').toLowerCase();
    final features = voice['features']?.toLowerCase() ?? '';
    final isIndonesian = locale == 'id' || (locale?.startsWith('id-') ?? false);
    return isIndonesian &&
        voice['network_required'] == '0' &&
        !features.contains('notinstalled');
  }).toList();
  if (candidates.isEmpty) return null;

  int localeRank(String? locale) =>
      locale?.replaceAll('_', '-').toLowerCase() == 'id-id' ? 1 : 0;
  int qualityRank(String? quality) => switch (quality?.toLowerCase()) {
    'very high' => 4,
    'high' => 3,
    'normal' => 2,
    'low' => 1,
    _ => 0,
  };
  int latencyRank(String? latency) => switch (latency?.toLowerCase()) {
    'very low' => 5,
    'low' => 4,
    'normal' => 3,
    'high' => 2,
    'very high' => 1,
    _ => 0,
  };
  candidates.sort((left, right) {
    final localeDifference =
        localeRank(right['locale']) - localeRank(left['locale']);
    if (localeDifference != 0) return localeDifference;
    final latencyDifference =
        latencyRank(right['latency']) - latencyRank(left['latency']);
    if (latencyDifference != 0) return latencyDifference;
    return qualityRank(right['quality']) - qualityRank(left['quality']);
  });
  return candidates.first;
}

class QuestionAudioButton extends StatefulWidget {
  const QuestionAudioButton({
    required this.text,
    super.key,
    this.engine,
    this.label = 'Dengarkan soal',
    this.kind = QuestionSpeechKind.instruction,
  });

  final String text;
  final QuestionSpeechEngine? engine;
  final String label;
  final QuestionSpeechKind kind;

  @override
  State<QuestionAudioButton> createState() => _QuestionAudioButtonState();
}

class _QuestionAudioButtonState extends State<QuestionAudioButton> {
  late final QuestionSpeechEngine _engine =
      widget.engine ?? FlutterTtsQuestionSpeechEngine();
  bool _isPlaying = false;
  bool _isUnavailable = false;
  bool _isStarting = false;
  bool _isConfigured = false;
  bool _disposed = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _engine.onStart = _markPlaying;
    _engine.onComplete = _markStopped;
    _engine.onError = _markStopped;
  }

  @override
  void didUpdateWidget(covariant QuestionAudioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.kind != widget.kind ||
        oldWidget.engine != widget.engine) {
      _stop();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    _engine.onStart = null;
    _engine.onComplete = null;
    _engine.onError = null;
    unawaited(_stopQuietly());
    super.dispose();
  }

  void _markPlaying() {
    if (_disposed || !mounted) return;
    setState(() {
      _isStarting = false;
      _isPlaying = true;
    });
  }

  void _markStopped() {
    if (_disposed || !mounted) return;
    setState(() {
      _isStarting = false;
      _isPlaying = false;
    });
  }

  Future<void> _toggle() async {
    if (_isPlaying || _isStarting) {
      await _stop();
      return;
    }

    final requestId = ++_requestId;
    setState(() {
      _isStarting = true;
      _isUnavailable = false;
    });
    try {
      final supported = await _engine.supportsIndonesian();
      if (!_isCurrent(requestId)) return;
      if (!supported) {
        setState(() {
          _isStarting = false;
          _isUnavailable = true;
        });
        return;
      }
      if (!_isConfigured) {
        await _engine.configure();
        if (!_isCurrent(requestId)) return;
        _isConfigured = true;
      }
      await _engine.stop();
      if (!_isCurrent(requestId)) return;
      await _engine.speak(_spokenText(widget.text), kind: widget.kind);
      if (_isCurrent(requestId)) {
        setState(() {
          _isStarting = false;
          _isPlaying = true;
        });
      }
    } catch (_) {
      if (!_isCurrent(requestId)) return;
      setState(() {
        _isStarting = false;
        _isPlaying = false;
        _isUnavailable = true;
      });
    }
  }

  Future<void> _stop() async {
    _requestId++;
    if (mounted) {
      setState(() {
        _isStarting = false;
        _isPlaying = false;
      });
    }
    try {
      await _engine.stop();
    } catch (_) {
      // A platform may report an error when stop is called before first use.
    }
  }

  Future<void> _stopQuietly() async {
    try {
      await _engine.stop();
    } catch (_) {
      // A platform may not expose text-to-speech in the current environment.
    }
  }

  bool _isCurrent(int requestId) =>
      !_disposed && mounted && requestId == _requestId;

  String _spokenText(String text) => text
      .replaceAll(RegExp(r'_{2,}'), ' bagian yang kosong ')
      .replaceAll('…', ' bagian yang kosong ')
      .replaceAll('...', ' bagian yang kosong ')
      .replaceAllMapped(RegExp(r'\s+([.,!?])'), (match) => match.group(1)!)
      .replaceAll(RegExp(r' {2,}'), ' ')
      .trim();

  @override
  Widget build(BuildContext context) {
    final active = _isPlaying || _isStarting;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: IconButton.filled(
            key: const ValueKey('question-audio-button'),
            tooltip: active ? 'Hentikan suara soal' : widget.label,
            onPressed: _toggle,
            style: IconButton.styleFrom(
              backgroundColor: active ? AppTokens.secondary : AppTokens.primary,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
            ),
            icon: _isStarting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                    size: 28,
                  ),
          ),
        ),
        if (_isPlaying)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Sedang dibacakan',
              style: TextStyle(fontSize: 12, color: AppTokens.secondary),
            ),
          ),
        if (_isUnavailable)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Suara bahasa Indonesia tidak tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTokens.mutedText),
            ),
          ),
      ],
    );
  }
}
