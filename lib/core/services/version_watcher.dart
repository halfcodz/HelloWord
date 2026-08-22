import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_refresh.dart';
import 'version_check.dart';

/// 서버에 새 버전이 올라왔는지 지켜보다가 알려 준다.
///
/// 웹은 한 번 연 탭이 계속 살아 있고, 홈 화면에 추가해 쓰면 서비스워커가
/// 예전 파일을 그대로 내주기까지 한다. 그래서 새로 배포해도 본인은 모른 채
/// 옛날 화면을 계속 쓰게 된다. 여기서 서버의 version.json을 이따금 들여다보고
/// 앱에 박혀 있는 버전과 다르면 위쪽에 띠를 띄운다.
class VersionWatcher extends ChangeNotifier with WidgetsBindingObserver {
  VersionWatcher({
    this.interval = const Duration(minutes: 20),
    String? current,
    Future<String?> Function(String cacheBuster)? fetch,
  })  : _current = current ?? currentVersion,
        _fetch = fetch ?? fetchServerVersion;

  /// 빌드할 때 심어 주는 지금 버전('2.9.0+20'). tool/deploy.sh가 넣는다.
  /// 비어 있으면(로컬 개발 빌드) 확인하지 않는다.
  static const currentVersion = String.fromEnvironment('APP_VERSION');

  static const _dismissedKey = 'update_banner_dismissed';

  /// 얼마마다 한 번씩 들여다볼지.
  final Duration interval;

  /// 지금 돌고 있는 버전(테스트에서 갈아 끼울 수 있게 필드로 둔다).
  final String _current;
  final Future<String?> Function(String cacheBuster) _fetch;

  Timer? _timer;
  Timer? _firstCheck;
  bool _checking = false;
  bool _disposed = false;
  bool _started = false;

  String? _serverVersion;
  String? _dismissed;

  /// 알려 줄 새 버전이 있는지(사용자가 닫은 버전은 다시 띄우지 않는다).
  bool get updateAvailable =>
      _serverVersion != null && _serverVersion != _dismissed;

  /// 서버에 올라와 있는 버전. 없으면 null.
  String? get newVersion => _serverVersion;

  /// 화면에 보여 줄 버전 이름('2.9.0'). 빌드 번호는 떼고 보여 준다.
  String get newVersionLabel => (_serverVersion ?? '').split('+').first;

  Future<void> start() async {
    if (_started || _current.isEmpty) return;
    _started = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      _dismissed = prefs.getString(_dismissedKey);
    } catch (_) {
      // 못 읽어도 그냥 한 번 더 알려 주면 된다.
    }

    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(interval, (_) => check());
    // 켜자마자 묻지 않는다. 첫 화면이 뜨는 동안 네트워크를 나눠 쓰지 않도록
    // 조금 기다렸다 확인한다.
    _firstCheck = Timer(const Duration(seconds: 8), check);
  }

  /// 앱으로 돌아올 때마다 한 번 확인한다(그동안 배포가 있었을 수 있다).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) check();
  }

  Future<void> check() async {
    if (_checking || _disposed || _current.isEmpty) return;
    _checking = true;
    try {
      final server = await _fetch(
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
      // 못 읽었으면(오프라인 등) 지금 알고 있는 것을 그대로 둔다.
      if (server == null) return;

      final next = server == _current ? null : server;
      if (next == _serverVersion || _disposed) return;
      _serverVersion = next;
      notifyListeners();
    } finally {
      _checking = false;
    }
  }

  /// 이 버전은 됐다고 닫는다. 그다음 배포부터 다시 알려 준다.
  Future<void> dismiss() async {
    final version = _serverVersion;
    if (version == null) return;
    _dismissed = version;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedKey, version);
    } catch (_) {
      // 못 저장하면 다음에 또 뜬다. 그 정도는 괜찮다.
    }
  }

  /// 캐시를 비우고 최신 버전을 받아 온다. 보던 탭으로 돌아온다.
  Future<void> applyUpdate() => AppRefresh.refreshKeepingTab();

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _firstCheck?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
