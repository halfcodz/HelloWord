import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 잔잔한 배경음악을 틀고 끄는 서비스.
///
/// - 켬/끔은 기기에 저장돼 다음 실행에도 이어진다.
/// - 앱을 내리면 자동으로 멈추고, 돌아오면 다시 켠다.
/// - 영상통화(시험)처럼 소리가 겹치면 안 되는 화면에서는 [suspend]로 잠시 멈춘다.
/// - 음원은 `assets/audio/bgm_1~4.mp3`. 한 곡이 끝나면 다음 곡으로 넘어가고,
///   마지막 곡 다음에는 다시 첫 곡으로 돌아가 계속 이어진다.
///   (게임 BGM 등 저작권 있는 음원 대신 tool/generate_bgm.py로 직접 합성한 곡)
class BgmService extends ChangeNotifier with WidgetsBindingObserver {
  BgmService._(this._enabled);

  static const _prefKey = 'bgm_enabled';

  /// 이어서 트는 곡 목록.
  static const _playlist = [
    'audio/bgm_1.mp3',
    'audio/bgm_2.mp3',
    'audio/bgm_3.mp3',
    'audio/bgm_4.mp3',
  ];

  /// 배경음악이라 존재감이 없을 만큼 작게 튼다.
  static const double _volume = 0.22;

  final AudioPlayer _player = AudioPlayer(playerId: 'helloword-bgm');

  bool _enabled;
  bool get enabled => _enabled;

  /// 재생을 시도한 적이 있는지(로그인 전에는 틀지 않는다).
  bool _started = false;

  /// 겹쳐 쓸 수 있도록 '멈춰 달라'는 요청 수를 센다.
  int _suspendCount = 0;
  bool get isSuspended => _suspendCount > 0;

  /// 지금 트는 곡 번호.
  int _track = 0;

  /// 곡이 끝나면 다음 곡으로 넘기는 구독.
  StreamSubscription<void>? _completeSub;

  /// 소리를 낼 수 없는 환경(웹 자동재생 차단 등)인지.
  bool _unavailable = false;
  bool get isUnavailable => _unavailable;

  /// 저장된 설정을 불러와 서비스를 만든다. (앱 시작 시 1회)
  static Future<BgmService> load() async {
    var enabled = true; // 기본값: 켜짐
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_prefKey) ?? true;
    } catch (_) {
      // 저장소 접근 실패 시 기본값.
    }
    final service = BgmService._(enabled);
    WidgetsBinding.instance.addObserver(service);
    return service;
  }

  /// 로그인 후 등 '이제 틀어도 되는' 시점에 호출한다.
  Future<void> start() async {
    _started = true;
    await _sync();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    await _sync();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
  }

  /// 영상통화처럼 소리가 겹치면 안 되는 화면에서 잠시 멈춘다.
  /// 반드시 [resume]과 짝을 맞춰 호출한다.
  Future<void> suspend() async {
    _suspendCount++;
    if (_suspendCount == 1) {
      notifyListeners();
      await _sync();
    }
  }

  Future<void> resume() async {
    if (_suspendCount == 0) return;
    _suspendCount--;
    if (_suspendCount == 0) {
      notifyListeners();
      await _sync();
    }
  }

  bool get _shouldPlay => _started && _enabled && !isSuspended && !_unavailable;

  Future<void> _sync() async {
    try {
      if (_shouldPlay) {
        // 한 곡이 끝나면 자동으로 다음 곡을 잇는다.
        _completeSub ??= _player.onPlayerComplete.listen((_) => _playNext());
        await _player.setReleaseMode(ReleaseMode.stop);
        await _player.setVolume(_volume);
        if (_player.state == PlayerState.paused) {
          await _player.resume();
        } else if (_player.state != PlayerState.playing) {
          await _player.play(
            AssetSource(_playlist[_track]),
            volume: _volume,
          );
        }
      } else {
        if (_player.state == PlayerState.playing) {
          await _player.pause();
        }
      }
    } catch (e) {
      // 웹 자동재생 차단·음원 누락 등. 앱 동작에는 영향을 주지 않는다.
      debugPrint('BGM 재생 실패: $e');
      _unavailable = true;
      notifyListeners();
    }
  }

  /// 다음 곡으로 넘어간다. 마지막 곡 다음은 다시 첫 곡.
  Future<void> _playNext() async {
    if (!_shouldPlay) return;
    _track = (_track + 1) % _playlist.length;
    try {
      await _player.play(AssetSource(_playlist[_track]), volume: _volume);
    } catch (e) {
      debugPrint('BGM 다음 곡 재생 실패: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sync();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _player.pause().catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
