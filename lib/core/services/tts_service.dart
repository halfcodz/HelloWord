import 'tts_impl_native.dart'
    if (dart.library.js_interop) 'tts_impl_web.dart';

/// 미국식 영어 발음을 소리로 재생한다. (웹=브라우저 SpeechSynthesis, 그 외=flutter_tts)
class TtsService {
  TtsService._();

  static Future<void> speak(String text) => speakImpl(text);
}
