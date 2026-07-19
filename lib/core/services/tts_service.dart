import 'package:flutter_tts/flutter_tts.dart';

/// 미국식 영어 발음을 소리로 재생한다(브라우저/OS 내장 TTS, 무료).
class TtsService {
  TtsService._();

  static final FlutterTts _tts = FlutterTts();
  static bool _configured = false;

  static Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    _configured = true;
  }

  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _ensureConfigured();
      await _tts.stop();
      await _tts.speak(text.trim());
    } catch (_) {
      // 지원하지 않는 환경이면 조용히 무시.
    }
  }
}
