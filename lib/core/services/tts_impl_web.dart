import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.HTMLAudioElement? _audio;

/// 웹(PWA 포함): 깨끗한 발음을 위해 구글 번역 TTS의 mp3를 오디오로 재생한다.
/// (시스템 음성은 먹먹하게 들려서, 네이버 사전처럼 또렷한 녹음 음성을 쓴다)
/// 실패하면 브라우저 내장 SpeechSynthesis로 대체한다.
Future<void> speakImpl(String text) async {
  final t = text.trim();
  if (t.isEmpty) return;
  final url =
      'https://translate.google.com/translate_tts?ie=UTF-8&tl=en&client=tw-ob&q=${Uri.encodeComponent(t)}';
  try {
    _audio?.pause();
    final a = web.HTMLAudioElement();
    // CORS 모드를 켜지 않아야(anonymous 미설정) 크로스도메인 mp3가 재생된다.
    a.src = url;
    _audio = a;
    // play()는 Promise를 반환. 자동재생 차단/네트워크 실패 시 내장 음성으로 대체.
    a.play().toDart.then((_) {}).catchError((Object _) {
      _synth(t);
      return null;
    });
  } catch (_) {
    _synth(t);
  }
}

/// 대체: 브라우저 내장 SpeechSynthesis (사용자 탭 안에서 바로 호출).
void _synth(String t) {
  try {
    final synth = web.window.speechSynthesis;
    synth.cancel();
    final u = web.SpeechSynthesisUtterance(t)
      ..lang = 'en-US'
      ..rate = 0.95
      ..volume = 1.0;
    synth.speak(u);
  } catch (_) {}
}
