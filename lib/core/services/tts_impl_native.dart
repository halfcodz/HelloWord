import 'package:flutter_tts/flutter_tts.dart';

final FlutterTts _tts = FlutterTts();
bool _init = false;

/// 네이티브(iOS/Android): flutter_tts로 미국식 영어 발음 재생.
Future<void> speakImpl(String text) async {
  final t = text.trim();
  if (t.isEmpty) return;
  try {
    if (!_init) {
      _init = true;
      try {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
          IosTextToSpeechAudioMode.defaultMode,
        );
      } catch (_) {}
    }
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.stop();
    await _tts.speak(t);
  } catch (_) {}
}
