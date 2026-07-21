import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';

/// 미국식 영어 발음을 소리로 재생한다(브라우저/OS 내장 TTS, 무료).
class TtsService {
  TtsService._();

  static final FlutterTts _tts = FlutterTts();
  static bool _initOnce = false;

  /// iOS 등 네이티브 환경 초기 설정(무음 스위치에도 재생되도록).
  static Future<void> _initNative() async {
    if (_initOnce || kIsWeb) return;
    _initOnce = true;
    try {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    } catch (_) {}
  }

  static Future<void> speak(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    try {
      await _initNative();
      // 매 호출마다 설정(웹에서 처음 한 번 실패해도 다음 재생이 되도록).
      try {
        await _tts.stop();
      } catch (_) {}
      try {
        await _tts.setLanguage('en-US');
      } catch (_) {}
      try {
        await _tts.setVolume(1.0);
      } catch (_) {}
      try {
        await _tts.setPitch(1.0);
      } catch (_) {}
      try {
        // 웹/모바일 모두 자연스러운 속도.
        await _tts.setSpeechRate(kIsWeb ? 1.0 : 0.5);
      } catch (_) {}
      await _tts.speak(t);
    } catch (_) {
      // 지원하지 않는 환경이면 조용히 무시.
    }
  }
}
