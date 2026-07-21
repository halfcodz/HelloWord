import 'package:web/web.dart' as web;

/// 웹(PWA 포함): 브라우저 SpeechSynthesis를 '사용자 탭 안에서 바로' 호출한다.
/// (await로 제스처 컨텍스트를 잃으면 iOS 사파리가 재생을 막으므로 동기 호출)
Future<void> speakImpl(String text) async {
  final t = text.trim();
  if (t.isEmpty) return;
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
