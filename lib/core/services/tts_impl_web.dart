import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.SpeechSynthesisVoice? _voice;
bool _warmed = false;

/// 웹(PWA 포함): 브라우저 내장 SpeechSynthesis로 또렷하게 재생한다.
/// (iOS 홈화면 앱에서는 외부 mp3 재생이 막히는 경우가 많아 내장 음성을 쓴다)
/// - 속도 1.0 + 고품질 en 보이스 선택으로 '먹먹함'을 줄인다.
Future<void> speakImpl(String text) async {
  final t = text.trim();
  if (t.isEmpty) return;
  try {
    final synth = web.window.speechSynthesis;
    // 사용자 제스처 안에서 바로 호출(iOS 재생 잠금 해제).
    // iOS Safari는 speechSynthesis가 일시정지되는 경우가 있어 resume 먼저.
    try {
      synth.resume();
    } catch (_) {}
    synth.cancel();
    _voice ??= _pickVoice(synth);

    final u = web.SpeechSynthesisUtterance(t)
      ..lang = 'en-US'
      ..rate = 1.0
      ..pitch = 1.0
      ..volume = 1.0;
    final v = _voice;
    if (v != null) u.voice = v;
    synth.speak(u);

    // 첫 호출 때 보이스 목록이 아직 안 왔으면 로드 후 캐시.
    if (!_warmed && _voice == null) {
      _warmed = true;
      synth.onvoiceschanged = ((web.Event _) {
        _voice = _pickVoice(synth);
      }).toJS;
    }
  } catch (_) {}
}

/// 고품질 영어 보이스를 고른다. (compact/저품질 제외, en-US 우선)
web.SpeechSynthesisVoice? _pickVoice(web.SpeechSynthesis synth) {
  List<web.SpeechSynthesisVoice> voices;
  try {
    voices = synth.getVoices().toDart;
  } catch (_) {
    return null;
  }
  web.SpeechSynthesisVoice? best;
  for (final v in voices) {
    final lang = v.lang.toLowerCase();
    if (!lang.startsWith('en')) continue;
    final name = v.name.toLowerCase();
    if (name.contains('compact') || name.contains('eloquence')) continue;
    // 애플/구글 고품질 보이스 우선.
    if (lang == 'en-us' &&
        (name.contains('samantha') ||
            name.contains('google') ||
            name.contains('aaron') ||
            name.contains('nicky'))) {
      return v;
    }
    if (lang == 'en-us') {
      best = v;
    } else {
      best ??= v;
    }
  }
  return best;
}
