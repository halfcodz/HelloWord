import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// 시험 중 1:1 영상통화(WebRTC)를 관리한다.
/// 시그널링(offer/answer/ICE 후보)은 Firestore를 통해 주고받고,
/// 실제 영상은 두 기기가 P2P로 직접 연결한다(무료 STUN/TURN 사용).
///
/// 바로바로 연결되게 하는 규칙:
/// 1. 언니(caller)는 통화를 시작할 때 지난 통화 기록(offer/answer/후보)을 먼저 지운다.
///    → 지난 통화의 낡은 answer를 잘못 적용해 연결이 안 되는 문제를 막는다.
/// 2. 모든 offer에 협상 번호(offerId)를 붙이고, answer·ICE 후보도 그 번호를 달고 온다.
///    번호가 다른 answer·후보는 버린다. → 순서가 엉켜도 꼬이지 않는다.
/// 3. 동생(callee)은 화면에 들어오는 순간 `calleeId`로 "들어왔다"고 알린다.
///    언니는 동생이 (다시) 들어온 걸 보면 즉시 새 offer를 보낸다.
///    → 나갔다 들어오기를 반복하지 않아도 바로 다시 연결된다.
/// 4. 몇 초 안에 연결되지 않으면 양쪽이 스스로 다시 시도한다(watchdog).
class CallService {
  CallService({
    required this.sessionId,
    required this.isCaller,
    this.onRemoteStream,
    this.onConnectionState,
    this.onLocalStreamChanged,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String sessionId;
  final bool isCaller;
  final FirebaseFirestore _firestore;

  final void Function()? onRemoteStream;
  final void Function(String state)? onConnectionState;

  /// 내 카메라·마이크가 바뀌었을 때(다시 열렸을 때) 알린다.
  final void Function()? onLocalStreamChanged;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _pc;
  MediaStream? _localStream;

  /// 상대 영상·소리. onTrack이 스트림 없이 트랙만 줄 때 직접 만들어 담는다.
  MediaStream? _remoteStream;
  final List<StreamSubscription> _subs = [];

  /// 카메라를 못 열어 소리만으로 연결된 상태인지.
  bool _audioOnly = false;

  /// 카메라·마이크를 다시 여는 중인지(중복 실행 방지).
  bool _reopening = false;

  /// 오래 연결이 안 될 때 재시도 간격을 늘리기 위한 눈금.
  int _slowTicks = 0;

  /// 카메라 없이 소리만 연결된 상태인지. 화면에 안내를 띄우는 데 쓴다.
  bool get isAudioOnly => _audioOnly;

  /// 원격 설명(offer/answer)을 적용하기 전에 도착한 ICE 후보를 협상 번호와 함께 담아 둔다.
  final List<({String? id, RTCIceCandidate cand})> _pendingCandidates = [];

  /// 이 기기(통화 참가자) 식별자. 나갔다 들어오면 새 값이 된다.
  final String _peerId = _randomId();

  /// 지금 진행 중인 협상 번호(offerId).
  String? _negotiationId;

  /// 마지막으로 적용한 원격 SDP(같은 걸 두 번 적용하지 않기 위해).
  String? _appliedRemoteSdp;

  /// 언니가 마지막으로 확인한 동생 식별자.
  String? _lastCalleeId;

  /// 동생이 "들어왔다"고 알린 횟수(다시 시도할 때마다 값이 달라져야 한다).
  int _announceCount = 0;

  /// 마지막으로 offer를 보낸 시각(재협상 간격 제한).
  DateTime? _lastOfferAt;

  bool _remoteReady = false;
  bool _connected = false;
  bool _renegotiating = false;
  int _recoverCount = 0;
  Timer? _watchdog;
  Timer? _restartTimer;

  /// 간격 제한 때문에 미뤄 둔 재협상.
  Timer? _pendingRenegotiate;
  bool _disposed = false;

  /// 지금 상대와 연결되어 있는지.
  bool get isConnected => _connected;

  static String _randomId() {
    final rand = Random();
    return List.generate(12, (_) => rand.nextInt(36).toRadixString(36)).join();
  }

  DocumentReference<Map<String, dynamic>> get _callDoc => _firestore
      .collection('sessions')
      .doc(sessionId)
      .collection('rtc')
      .doc('call');

  CollectionReference<Map<String, dynamic>> get _callerCandidates =>
      _callDoc.collection('callerCandidates');
  CollectionReference<Map<String, dynamic>> get _calleeCandidates =>
      _callDoc.collection('calleeCandidates');

  static const Map<String, dynamic> _config = {
    'sdpSemantics': 'unified-plan',
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun.relay.metered.ca:80',
        ],
      },
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turns:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
  };

  Future<void> start() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    if (_disposed) return;

    final stream = await _openLocalStream();
    // 카메라를 여는 사이에 화면을 떠났을 수 있다. 그대로 두면 카메라가 켜진 채
    // 남으므로 반드시 여기서 끈다.
    if (_disposed) {
      await _stopStream(stream);
      return;
    }
    _localStream = stream;
    localRenderer.srcObject = stream;
    _watchLocalTracks();

    final pc = await createPeerConnection(_config);
    if (_disposed) {
      try {
        await pc.close();
      } catch (_) {}
      await _stopStream(stream);
      _localStream = null;
      return;
    }
    _pc = pc;

    for (final track in stream.getTracks()) {
      await pc.addTrack(track, stream);
    }

    pc.onTrack = (event) => unawaited(_attachRemoteTrack(event));
    pc.onAddStream = (stream) {
      if (_disposed) return;
      _remoteStream = stream;
      remoteRenderer.srcObject = stream;
      onRemoteStream?.call();
    };

    pc.onConnectionState = _onPeerState;
    pc.onIceConnectionState = _onIceState;

    // 내가 만드는 ICE 후보에는 지금 협상 번호를 달아 보낸다.
    final myCandidates = isCaller ? _callerCandidates : _calleeCandidates;
    pc.onIceCandidate = (candidate) {
      if (_disposed) return;
      // 네트워크가 잠깐 끊기면 쓰기가 실패할 수 있다. 통화를 죽이지는 않는다.
      unawaited(_sendCandidate(myCandidates, candidate));
    };

    if (isCaller) {
      await _runCaller(pc);
    } else {
      await _runCallee(pc);
    }
    _startWatchdog();
  }

  Future<void> _sendCandidate(
    CollectionReference<Map<String, dynamic>> col,
    RTCIceCandidate candidate,
  ) async {
    try {
      await col.add({...candidate.toMap(), 'offerId': _negotiationId});
    } catch (e) {
      debugPrint('ICE 후보를 보내지 못했습니다: $e');
    }
  }

  /// 카메라·마이크를 여는 순서. 앞에서부터 되는 것을 쓴다.
  /// 마지막은 소리만 — 카메라를 못 쓰는 상황에서도 목소리는 들리게 한다.
  static const List<({bool video, Map<String, dynamic> constraints})>
  _mediaAttempts = [
    (
      video: true,
      constraints: {
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
          'frameRate': {'ideal': 24, 'max': 30},
        },
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
      },
    ),
    // 위 조건을 못 맞추는 카메라(OverconstrainedError)를 위한 기본값.
    (video: true, constraints: {'video': true, 'audio': true}),
    // 카메라가 아예 안 되면 소리만이라도.
    (video: false, constraints: {'video': false, 'audio': true}),
  ];

  /// 카메라·마이크를 연다. 조건을 낮춰 가며 될 때까지 시도하고,
  /// 카메라가 끝내 안 되면 소리만으로 연결한다.
  Future<MediaStream> _openLocalStream() async {
    Object? firstError;
    for (final attempt in _mediaAttempts) {
      try {
        final stream = await navigator.mediaDevices.getUserMedia(
          attempt.constraints,
        );
        // 영상을 요청했는데 실제로 영상 트랙이 없으면 다음 방법으로 넘어간다.
        if (attempt.video && stream.getVideoTracks().isEmpty) {
          await _stopStream(stream);
          continue;
        }
        _audioOnly = !attempt.video || stream.getVideoTracks().isEmpty;
        if (_audioOnly) debugPrint('카메라 없이 소리만으로 통화를 시작합니다.');
        return stream;
      } catch (e) {
        firstError ??= e;
        debugPrint('카메라·마이크 열기 실패(다음 방법 시도): $e');
      }
    }
    throw firstError ?? StateError('카메라·마이크를 열 수 없습니다.');
  }

  /// onTrack으로 받은 상대 트랙을 화면에 붙인다.
  /// 브라우저에 따라 스트림 없이 트랙만 오는 경우가 있어 직접 담아 준다.
  Future<void> _attachRemoteTrack(RTCTrackEvent event) async {
    if (_disposed) return;
    if (event.streams.isNotEmpty) {
      _remoteStream = event.streams.first;
      remoteRenderer.srcObject = _remoteStream;
      onRemoteStream?.call();
      return;
    }
    try {
      final stream = _remoteStream ??= await createLocalMediaStream('remote');
      if (_disposed) return;
      await stream.addTrack(event.track);
      remoteRenderer.srcObject = stream;
      onRemoteStream?.call();
    } catch (e) {
      debugPrint('상대 영상을 붙이지 못했습니다: $e');
    }
  }

  /// 내 카메라·마이크가 죽으면 다시 연다.
  /// 전화가 오거나 다른 앱이 카메라를 가져가면 트랙이 그대로 끝나 버리는데,
  /// 두면 상대에게 검은 화면만 계속 나간다.
  void _watchLocalTracks() {
    for (final track in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      track.onEnded = () {
        if (_disposed) return;
        debugPrint('내 ${track.kind} 트랙이 끊겼습니다. 다시 엽니다.');
        unawaited(_reopenLocalStream());
      };
    }
  }

  /// 카메라·마이크를 다시 열어 지금 통화에 갈아 끼운다.
  /// 연결은 그대로 두고 트랙만 바꾸므로 통화가 끊기지 않는다.
  Future<void> _reopenLocalStream() async {
    if (_disposed || _reopening) return;
    _reopening = true;
    try {
      final fresh = await _openLocalStream();
      if (_disposed) {
        await _stopStream(fresh);
        return;
      }
      final old = _localStream;
      _localStream = fresh;
      localRenderer.srcObject = fresh;
      _watchLocalTracks();

      final pc = _pc;
      if (pc != null) {
        for (final sender in await pc.getSenders()) {
          final kind = sender.track?.kind;
          final replacement = kind == 'audio'
              ? _firstOrNull(fresh.getAudioTracks())
              : _firstOrNull(fresh.getVideoTracks());
          if (replacement == null) continue;
          try {
            await sender.replaceTrack(replacement);
          } catch (e) {
            debugPrint('트랙 교체 실패($kind): $e');
          }
        }
      }
      await _stopStream(old);
      onLocalStreamChanged?.call();
    } catch (e) {
      debugPrint('카메라·마이크를 다시 열지 못했습니다: $e');
    } finally {
      _reopening = false;
    }
  }

  static T? _firstOrNull<T>(List<T> list) => list.isEmpty ? null : list.first;

  /// 스트림의 트랙을 확실히 멈춘다(웹에서는 stop()을 불러야 카메라가 꺼진다).
  static Future<void> _stopStream(MediaStream? stream) async {
    if (stream == null) return;
    try {
      for (final t in stream.getTracks()) {
        try {
          await t.stop();
        } catch (_) {}
      }
    } catch (_) {}
    try {
      await stream.dispose();
    } catch (_) {}
  }

  void _onIceState(RTCIceConnectionState state) {
    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
      case RTCIceConnectionState.RTCIceConnectionStateCompleted:
        _markConnected();
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        _markLost('failed');
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        _markLost('disconnected');
      default:
        break; // new/checking/closed는 알리지 않는다.
    }
  }

  void _onPeerState(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _markConnected();
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        _markLost('failed');
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        _markLost('disconnected');
      default:
        break;
    }
  }

  void _markConnected() {
    if (_disposed) return;
    _connected = true;
    _recoverCount = 0;
    _restartTimer?.cancel();
    // 이미 붙었으면 미뤄 둔 재협상은 취소한다(멀쩡한 통화를 다시 흔들지 않게).
    _pendingRenegotiate?.cancel();
    onConnectionState?.call('connected');
  }

  void _markLost(String reason) {
    if (_disposed) return;
    _connected = false;
    onConnectionState?.call(reason);
    // 잠시 뒤 스스로 다시 연결을 시도한다.
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!_disposed && !_connected) _recover();
    });
  }

  // ── 언니(caller) ───────────────────────────────

  Future<void> _runCaller(RTCPeerConnection pc) async {
    // 지난 통화 흔적을 먼저 지운다(낡은 offer/answer/후보 때문에 연결이 안 되는 것 방지).
    await _resetCallDoc();
    await _sendOffer(pc, iceRestart: false);

    _subs.add(
      _callDoc.snapshots().listen(
        (snap) => _onCallerDoc(pc, snap),
        onError: (Object e) => debugPrint('통화 문서 구독 오류: $e'),
      ),
    );
    _subs.add(
      _calleeCandidates.snapshots().listen(
        (snap) {
          for (final change in snap.docChanges) {
            if (change.type == DocumentChangeType.added) {
              _addCandidate(pc, change.doc.data());
            }
          }
        },
        onError: (Object e) => debugPrint('동생 ICE 후보 구독 오류: $e'),
      ),
    );
  }

  Future<void> _onCallerDoc(
    RTCPeerConnection pc,
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) async {
    if (_disposed) return;
    final data = snap.data();
    if (data == null) return;

    final calleeId = data['calleeId'] as String?;
    final answerFor = data['answerFor'] as String?;
    final answer = data['answer'];

    // 동생이 (다시) 들어왔다 → 곧바로 새 offer로 다시 협상한다.
    if (calleeId != null && calleeId != _lastCalleeId) {
      final wasKnown = _lastCalleeId != null;
      _lastCalleeId = calleeId;
      if (wasKnown) {
        await _renegotiate(pc);
        return;
      }
    }

    // 지금 협상에 대한 answer만 받아들인다.
    if (answer == null || answerFor != _negotiationId) return;
    final sdp = answer['sdp'] as String?;
    if (sdp == null || sdp == _appliedRemoteSdp) return;

    // 내 offer가 대기 중일 때만 answer를 넣을 수 있다.
    // (상태가 어긋났으면 새 offer부터 다시 시작한다.)
    final state = await pc.getSignalingState();
    if (state != null &&
        state != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      await _renegotiate(pc);
      return;
    }

    _appliedRemoteSdp = sdp;
    try {
      await pc.setRemoteDescription(
          RTCSessionDescription(sdp, answer['type'] as String?));
      _remoteReady = true;
      await _flushPendingCandidates(pc);
    } catch (_) {
      // 적용에 실패했으면 새 offer로 처음부터 다시 협상한다.
      _appliedRemoteSdp = null;
      await _renegotiate(pc);
    }
  }

  /// 새 협상 번호로 offer를 만들어 보낸다. (첫 연결·재연결 공통)
  Future<void> _sendOffer(RTCPeerConnection pc,
      {required bool iceRestart}) async {
    final id = _randomId();
    _negotiationId = id;
    _lastOfferAt = DateTime.now();
    _appliedRemoteSdp = null;
    _remoteReady = false;
    _pendingCandidates.clear();

    final offer =
        await pc.createOffer(iceRestart ? {'iceRestart': true} : const {});
    await pc.setLocalDescription(offer);
    await _callDoc.set({
      'offer': offer.toMap(),
      'offerId': id,
      'callerId': _peerId,
      'answer': null,
      'answerFor': null,
    }, SetOptions(merge: true));
  }

  /// 연결이 어긋났을 때 언니가 새 offer로 다시 협상한다.
  /// 너무 잦은 재협상(무한 반복)을 막기 위해 offer 간 최소 2초 간격을 두되,
  /// 간격이 안 됐으면 버리지 않고 남은 시간만큼 미뤄서 한 번 실행한다.
  Future<void> _renegotiate(RTCPeerConnection pc) async {
    if (_disposed || _renegotiating) return;
    final last = _lastOfferAt;
    final wait = last == null
        ? Duration.zero
        : const Duration(seconds: 2) - DateTime.now().difference(last);
    if (wait > Duration.zero) {
      _pendingRenegotiate?.cancel();
      _pendingRenegotiate = Timer(wait, () {
        if (!_disposed && !_connected) _renegotiate(pc);
      });
      return;
    }
    _pendingRenegotiate?.cancel();
    _renegotiating = true;
    try {
      await _sendOffer(pc, iceRestart: true);
    } catch (_) {
    } finally {
      _renegotiating = false;
    }
  }

  /// 통화 문서를 초기화한다(지난 통화의 offer/answer/후보 제거).
  Future<void> _resetCallDoc() async {
    try {
      await _clearCandidates(_callerCandidates);
      await _clearCandidates(_calleeCandidates);
      await _callDoc.delete();
    } catch (_) {}
  }

  // ── 동생(callee) ───────────────────────────────

  Future<void> _runCallee(RTCPeerConnection pc) async {
    // 언니에게 "나 들어왔어"라고 알린다 → 언니가 새 offer를 보낸다.
    await _announce();

    _subs.add(
      _callDoc.snapshots().listen(
        (snap) => _onCalleeDoc(pc, snap),
        onError: (Object e) => debugPrint('통화 문서 구독 오류: $e'),
      ),
    );
    _subs.add(
      _callerCandidates.snapshots().listen(
        (snap) {
          for (final change in snap.docChanges) {
            if (change.type == DocumentChangeType.added) {
              _addCandidate(pc, change.doc.data());
            }
          }
        },
        onError: (Object e) => debugPrint('언니 ICE 후보 구독 오류: $e'),
      ),
    );
  }

  Future<void> _onCalleeDoc(
    RTCPeerConnection pc,
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) async {
    if (_disposed) return;
    final data = snap.data();
    if (data == null) return;

    final offer = data['offer'];
    final sdp = offer?['sdp'] as String?;
    if (sdp == null || sdp == _appliedRemoteSdp) return;

    // 새 offer가 왔다 → 협상 번호를 갱신하고 answer를 만들어 응답한다.
    _appliedRemoteSdp = sdp;
    _negotiationId = data['offerId'] as String?;
    _remoteReady = false;
    try {
      await pc.setRemoteDescription(
          RTCSessionDescription(sdp, offer['type'] as String?));
      _remoteReady = true;
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      await _callDoc.set({
        'answer': answer.toMap(),
        'answerFor': _negotiationId,
        'calleeId': _calleeToken,
      }, SetOptions(merge: true));
      await _flushPendingCandidates(pc);
    } catch (_) {
      // 상태가 어긋났으면 다음 offer를 받아 다시 시도한다.
      _appliedRemoteSdp = null;
    }
  }

  String get _calleeToken => '$_peerId-$_announceCount';

  /// 동생이 통화 화면에 있다는 것을 알린다(값이 매번 달라져 언니가 새 offer를 보낸다).
  Future<void> _announce() async {
    if (_disposed) return;
    _announceCount++;
    try {
      await _callDoc.set({
        'calleeId': _calleeToken,
        'calleeJoinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // ── 공통 ──────────────────────────────────────

  /// 몇 초 안에 연결되지 않으면 스스로 다시 시도한다.
  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(
      Duration(seconds: isCaller ? 7 : 9),
      (timer) {
        if (_disposed) {
          timer.cancel();
          return;
        }
        if (_connected) return;
        // 언니는 동생이 들어온 뒤부터 다시 시도한다(아무도 없으면 의미 없음).
        if (isCaller && _lastCalleeId == null) return;
        // 오래 안 붙으면 포기하지 않고 간격만 늘린다. 지하철에서 나오거나
        // 와이파이가 돌아오면 그때 저절로 다시 붙어야 하기 때문이다.
        if (_recoverCount >= 12) {
          _slowTicks++;
          if (_slowTicks % 6 != 0) return;
        }
        _recover();
      },
    );
  }

  /// 연결이 안 될 때의 복구 동작. 언니는 새 offer, 동생은 재입장 알림.
  Future<void> _recover() async {
    if (_disposed) return;
    final pc = _pc;
    if (pc == null) return;
    _recoverCount++;
    if (isCaller) {
      await _renegotiate(pc);
    } else {
      await _announce();
    }
  }

  /// 앱이 백그라운드에서 돌아왔을 때: 통화를 끊지 않고 되살린다.
  Future<void> resume() async {
    if (_disposed) return;
    // 화면(렌더러)이 스트림을 놓쳤을 수 있으니 다시 연결해 준다.
    try {
      if (_localStream != null) localRenderer.srcObject = _localStream;
      if (_remoteStream != null) remoteRenderer.srcObject = _remoteStream;
    } catch (e) {
      debugPrint('화면에 스트림을 다시 붙이지 못했습니다: $e');
    }

    // 돌아와 보니 카메라·마이크가 죽어 있으면(전화·다른 앱에 뺏김) 다시 연다.
    // onEnded가 오지 않는 경우가 있어 여기서도 직접 확인한다.
    final tracks = _localStream?.getTracks() ?? const <MediaStreamTrack>[];
    final dead = tracks.isEmpty || tracks.every((t) => t.muted == true);
    if (dead) {
      await _reopenLocalStream();
    }

    _slowTicks = 0;
    if (_connected) return;
    _recoverCount = 0;
    await _recover();
  }

  void _addCandidate(RTCPeerConnection pc, Map<String, dynamic>? data) {
    if (data == null || _disposed) return;
    final id = data['offerId'] as String?;
    // 지난 협상에서 온 후보는 버린다.
    if (id != null && _negotiationId != null && id != _negotiationId) return;

    final candidate = RTCIceCandidate(
      data['candidate'] as String?,
      data['sdpMid'] as String?,
      data['sdpMLineIndex'] as int?,
    );
    if (_remoteReady) {
      // 상태가 어긋난 순간에 들어오면 던질 수 있다. 통화를 죽이지는 않는다.
      unawaited(
        pc.addCandidate(candidate).catchError((Object e) {
          debugPrint('ICE 후보를 넣지 못했습니다: $e');
        }),
      );
    } else {
      _pendingCandidates.add((id: id, cand: candidate));
    }
  }

  Future<void> _flushPendingCandidates(RTCPeerConnection pc) async {
    final pending = List.of(_pendingCandidates);
    _pendingCandidates.clear();
    for (final item in pending) {
      if (item.id != null &&
          _negotiationId != null &&
          item.id != _negotiationId) {
        continue;
      }
      try {
        await pc.addCandidate(item.cand);
      } catch (_) {}
    }
  }

  Future<void> _clearCandidates(
      CollectionReference<Map<String, dynamic>> col) async {
    try {
      final docs = await col.get();
      for (final d in docs.docs) {
        await d.reference.delete();
      }
    } catch (_) {}
  }

  void toggleCamera(bool enabled) {
    _localStream?.getVideoTracks().forEach((t) => t.enabled = enabled);
  }

  void toggleMic(bool enabled) {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = enabled);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _watchdog?.cancel();
    _restartTimer?.cancel();
    _pendingRenegotiate?.cancel();

    // 카메라/마이크 하드웨어를 확실히 끈다.
    // 웹에서는 MediaStream.dispose()·PC.close()만으로는 트랙이 멈추지 않아
    // 탭에 카메라가 계속 켜져 있으므로, 각 트랙에 stop()을 반드시 호출한다.
    // (다른 async 정리보다 먼저 실행해 중간에 끊겨도 반드시 멈추게 한다.)
    try {
      for (final t in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
        t.onEnded = null;
        try {
          await t.stop();
        } catch (_) {}
      }
    } catch (_) {}
    // 렌더러에서 스트림 참조를 떼어낸다(웹 비디오 요소 해제).
    try {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    } catch (_) {}

    for (final s in _subs) {
      try {
        await s.cancel();
      } catch (_) {}
    }
    _subs.clear();
    _pendingCandidates.clear();

    try {
      await _localStream?.dispose();
      await _remoteStream?.dispose();
      await _pc?.close();
    } catch (e) {
      debugPrint('통화 정리 중 오류(무시): $e');
    }
    _localStream = null;
    _remoteStream = null;
    _pc = null;

    try {
      await localRenderer.dispose();
      await remoteRenderer.dispose();
    } catch (e) {
      debugPrint('화면 정리 중 오류(무시): $e');
    }
    // caller가 통화 정보를 정리한다(다음 통화를 위해).
    if (isCaller) {
      await _resetCallDoc();
    }
  }
}
