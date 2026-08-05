import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 버튼을 눌렀을 때 나는 짧은 효과음.
///
/// 배경음악과 따로 켜고 끌 수 있다. 소리가 겹치면 안 되는 화면
/// (영상통화)에서는 배경음악과 같이 [suspend]로 잠시 멈춘다.
/// 음원은 `assets/audio/tap.mp3` (tool/generate_bgm.py로 직접 합성).
class SfxService extends ChangeNotifier {
  SfxService._(this._enabled);

  static const _prefKey = 'sfx_enabled';
  static const _asset = 'audio/tap.mp3';
  static const double _volume = 0.35;

  /// 앱 어디서나 탭 소리를 낼 수 있도록 하나만 만들어 쓴다.
  static SfxService? _instance;
  static SfxService? get instance => _instance;

  /// 소리를 실제로 낼 때 만든다.
  ///
  /// 앱이 켜지자마자 오디오 플레이어를 만들어 두면 아이폰 브라우저에서
  /// 오디오 세션을 미리 잡아, 나중에 영상통화가 마이크를 못 쓰는 일이 있다.
  /// 그래서 필요할 때 만들고, 통화가 시작되면 통째로 놓아 준다.
  AudioPlayer? _player;

  AudioPlayer _ensurePlayer() {
    return _player ??= AudioPlayer(playerId: 'helloword-sfx')
      ..setPlayerMode(PlayerMode.lowLatency);
  }

  bool _enabled;
  bool get enabled => _enabled;

  int _suspendCount = 0;
  bool _unavailable = false;

  static Future<SfxService> load() async {
    var enabled = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_prefKey) ?? true;
    } catch (_) {}
    final service = SfxService._(enabled);
    _instance = service;
    return service;
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
  }

  /// 영상통화처럼 마이크를 쓰는 화면에서 호출한다.
  /// 소리를 멈추는 데 그치지 않고 오디오 플레이어를 통째로 놓아 준다.
  void suspend() {
    _suspendCount++;
    final player = _player;
    _player = null;
    player?.dispose();
  }

  void resume() {
    if (_suspendCount > 0) _suspendCount--;
  }

  /// 버튼을 눌렀을 때 호출한다. 실패해도 앱 동작에는 영향이 없다.
  static void tap() => _instance?._play();

  void _play() {
    if (!_enabled || _suspendCount > 0 || _unavailable) return;
    final player = _ensurePlayer();
    // 이전 소리가 남아 있어도 곧바로 다시 울리도록 되감아서 재생한다.
    player.stop().then((_) {
      return player.play(AssetSource(_asset), volume: _volume);
    }).catchError((Object e) {
      debugPrint('효과음 재생 실패: $e');
      _unavailable = true;
    });
  }

  @override
  void dispose() {
    if (identical(_instance, this)) _instance = null;
    _player?.dispose();
    super.dispose();
  }
}
