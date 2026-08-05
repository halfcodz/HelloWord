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

  /// 지금 나오는 곡(1부터). 디버그·표시용.
  int get trackNumber => _track + 1;
  int get trackCount => _playlist.length;

  /// 곡이 끝나면 다음 곡으로 넘기는 구독.
  /// 플랫폼에 따라 이 이벤트가 오지 않는 경우가 있어서(웹에서 확인됨)
  /// 아래 [_advanceTimer]로도 같이 넘긴다.
  StreamSubscription<void>? _completeSub;

  /// 재생 중인 곡의 길이.
  Duration _duration = Duration.zero;
  StreamSubscription<Duration>? _durationSub;

  /// 곡 길이만큼 기다렸다가 다음 곡으로 넘기는 타이머.
  Timer? _advanceTimer;

  /// 지금 재생을 몇 번째로 시작했는지. 타이머가 뒤늦게 깨어나
  /// 엉뚱한 곡을 넘기지 않도록 확인하는 표식.
  int _playToken = 0;

  /// 이미 예약을 걸어 둔 재생 번호. 곡 길이 이벤트가 여러 번 오더라도
  /// 예약을 다시 걸지 않기 위한 것(다시 걸면 타이머가 계속 미뤄져 안 터진다).
  int _scheduledToken = -1;

  /// 마지막으로 곡을 넘긴 뒤 흐른 시간. 완료 이벤트와 타이머가 겹쳐
  /// 한 곡을 건너뛰는 것을 막는다.
  final Stopwatch _sinceAdvance = Stopwatch()..start();

  /// 브라우저가 자동재생을 막아 재생이 실패한 상태.
  /// 아이폰은 크롬이든 사파리든 WebKit이라 '사용자가 화면을 만지기 전에는'
  /// 소리를 시작할 수 없다. 그래서 실패를 영구 잠금으로 두지 않고,
  /// 다음 탭에서 다시 시도한다.
  bool _blocked = false;

  /// 소리를 낼 수 없는 기기로 단정하지 않는다.
  /// 브라우저는 '사용자가 만진 직후'에만 소리를 허용하므로, 몇 번 실패했다고
  /// 잠가 버리면 정작 눌렀을 때 영영 안 나온다. 실패하면 계속 다시 시도한다.
  bool get isUnavailable => false;

  /// 브라우저 차단으로 아직 못 틀고 있는 상태(설정 화면 안내용).
  bool get isBlocked => _blocked;

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
    _instance = service;
    WidgetsBinding.instance.addObserver(service);
    return service;
  }

  /// 음원을 미리 물려 둔 상태인지.
  bool _prepared = false;

  /// 소리를 내지 않고 음원만 미리 걸어 둔다.
  ///
  /// 브라우저는 '사용자가 누른 그 순간에 시작한 소리'만 허용한다.
  /// play()는 내부에서 음원을 먼저 불러오느라 기다림이 생기고, 그 사이에
  /// 제스처 자격이 풀려 재생이 거부된다. 그래서 불러오기는 미리 해 두고,
  /// 누른 순간에는 resume()만 부른다.
  Future<void> _prepare() async {
    if (_prepared) return;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(_volume);
      await _player.setSource(AssetSource(_playlist[_track]));
      _completeSub ??= _player.onPlayerComplete.listen((_) => _playNext());
      _durationSub ??= _player.onDurationChanged.listen((d) {
        _duration = d;
        _scheduleAdvance();
      });
      _prepared = true;
    } catch (e) {
      debugPrint('BGM 준비 실패: $e');
    }
  }

  /// 로그인 후 등 '이제 틀어도 되는' 시점에 호출한다.
  Future<void> start() async {
    _started = true;
    await _prepare();
    await _sync();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    // 스위치를 켜는 것도 사용자의 손짓이므로 그 자리에서 바로 재생한다.
    if (value && _started) {
      playFromGesture();
    } else {
      await _sync();
    }
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

  bool get _shouldPlay =>
      _started && _enabled && !isSuspended && !isUnavailable;

  /// 사용자가 화면을 만졌을 때 호출한다(버튼 탭 등).
  /// 브라우저 차단으로 못 틀고 있었다면 이때 다시 시도한다.
  static void notifyUserGesture() {
    final service = _instance;
    if (service == null || !service._blocked) return;
    if (!service._started || !service._enabled || service.isSuspended) return;
    if (service._player.state == PlayerState.playing) return;
    service.playFromGesture();
  }

  /// 사용자가 누른 그 순간에 재생을 시작한다.
  /// 여기서는 resume()이 첫 호출이어야 한다. 앞에 다른 기다림을 두면
  /// 브라우저가 '사용자가 시작한 소리'로 인정하지 않는다.
  void playFromGesture() {
    if (!_started || !_enabled || isSuspended) return;
    _player
        .resume()
        .then((_) {
          _blocked = false;
          _playToken++;
          notifyListeners();
          _scheduleAdvance(force: true);
        })
        .catchError((Object e) {
          debugPrint('BGM 제스처 재생 실패: $e');
          _blocked = true;
          notifyListeners();
        });
  }

  /// 앱 어디서나 탭 시점을 알릴 수 있도록 하나만 두고 쓴다.
  static BgmService? _instance;

  Future<void> _sync() async {
    try {
      if (_shouldPlay) {
        await _prepare();
        // 한 곡이 끝나면 자동으로 다음 곡을 잇는다.
        _completeSub ??= _player.onPlayerComplete.listen((_) => _playNext());
        _durationSub ??= _player.onDurationChanged.listen((d) {
          _duration = d;
          _scheduleAdvance();
        });
        await _player.setReleaseMode(ReleaseMode.stop);
        await _player.setVolume(_volume);
        if (_player.state == PlayerState.paused) {
          await _player.resume();
          // 멈춰 있던 동안 흐른 시간을 반영해 다시 계산한다.
          await _scheduleAdvance(force: true);
        } else if (_player.state != PlayerState.playing) {
          await _startTrack();
        }
        // 여기까지 왔으면 재생이 시작된 것.
        _blocked = false;
      } else {
        _advanceTimer?.cancel();
        if (_player.state == PlayerState.playing) {
          await _player.pause();
        }
      }
    } catch (e) {
      // 브라우저 자동재생 차단이 대부분이다. 다음 탭에서 다시 시도한다.
      debugPrint('BGM 재생 실패: $e');
      _blocked = true;
      notifyListeners();
    }
  }

  /// 지금 곡을 처음부터 튼다.
  Future<void> _startTrack() async {
    _playToken++;
    await _player.play(AssetSource(_playlist[_track]), volume: _volume);
    await _scheduleAdvance();
  }

  /// 남은 시간만큼 기다렸다가 다음 곡으로 넘기도록 예약한다.
  /// (완료 이벤트가 오지 않는 플랫폼에서도 곡이 넘어가게 하는 장치)
  ///
  /// 곡 하나에 한 번만 건다. 곡 길이 이벤트는 재생 중 여러 번 올 수 있는데,
  /// 그때마다 다시 걸면 남은 시간이 계속 초기화돼 타이머가 영영 안 터진다.
  Future<void> _scheduleAdvance({bool force = false}) async {
    if (!_shouldPlay || _duration == Duration.zero) return;
    final alreadySet =
        _scheduledToken == _playToken && (_advanceTimer?.isActive ?? false);
    if (alreadySet && !force) return;

    _advanceTimer?.cancel();
    Duration position;
    try {
      position = await _player.getCurrentPosition() ?? Duration.zero;
    } catch (_) {
      position = Duration.zero;
    }
    // 여운이 잘리지 않게 아주 조금 여유를 준다.
    final remain = _duration - position + const Duration(milliseconds: 120);
    final token = _playToken;
    _scheduledToken = token;
    _advanceTimer = Timer(remain.isNegative ? Duration.zero : remain, () {
      if (token != _playToken) return; // 그사이 다른 곡이 시작됐으면 무시
      _playNext();
    });
  }

  /// 다음 곡으로 넘어간다. 마지막 곡 다음은 다시 첫 곡.
  Future<void> _playNext() async {
    // 완료 이벤트와 타이머가 거의 동시에 들어오면 두 곡이 한 번에 넘어간다.
    if (_sinceAdvance.elapsedMilliseconds < 1500) return;
    _sinceAdvance.reset();
    _advanceTimer?.cancel();
    if (!_shouldPlay) return;
    _track = (_track + 1) % _playlist.length;
    try {
      await _startTrack();
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
      // 앱을 내린 동안 타이머가 돌아 엉뚱하게 곡이 넘어가지 않도록 멈춘다.
      _advanceTimer?.cancel();
      _player.pause().catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    if (identical(_instance, this)) _instance = null;
    WidgetsBinding.instance.removeObserver(this);
    _completeSub?.cancel();
    _durationSub?.cancel();
    _advanceTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
