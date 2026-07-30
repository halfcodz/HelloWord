import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
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
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String sessionId;
  final bool isCaller;
  final FirebaseFirestore _firestore;

  final void Function()? onRemoteStream;
  final void Function(String state)? onConnectionState;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  final List<StreamSubscription> _subs = [];

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

    _localStream = await navigator.mediaDevices.getUserMedia({
      'video': {'facingMode': 'user'},
      'audio': true,
    });
    localRenderer.srcObject = _localStream;

    final pc = await createPeerConnection(_config);
    _pc = pc;

    for (final track in _localStream!.getTracks()) {
      await pc.addTrack(track, _localStream!);
    }

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
        onRemoteStream?.call();
      }
    };
    pc.onAddStream = (stream) {
      remoteRenderer.srcObject = stream;
      onRemoteStream?.call();
    };

    pc.onConnectionState = _onPeerState;
    pc.onIceConnectionState = _onIceState;

    // 내가 만드는 ICE 후보에는 지금 협상 번호를 달아 보낸다.
    final myCandidates = isCaller ? _callerCandidates : _calleeCandidates;
    pc.onIceCandidate = (candidate) {
      if (_disposed) return;
      myCandidates.add({...candidate.toMap(), 'offerId': _negotiationId});
    };

    if (isCaller) {
      await _runCaller(pc);
    } else {
      await _runCallee(pc);
    }
    _startWatchdog();
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

    _subs.add(_callDoc.snapshots().listen((snap) => _onCallerDoc(pc, snap)));
    _subs.add(_calleeCandidates.snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _addCandidate(pc, change.doc.data());
        }
      }
    }));
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

    _subs.add(_callDoc.snapshots().listen((snap) => _onCalleeDoc(pc, snap)));
    _subs.add(_callerCandidates.snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _addCandidate(pc, change.doc.data());
        }
      }
    }));
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
        if (_recoverCount >= 12) {
          timer.cancel();
          return;
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
    } catch (_) {}
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
      pc.addCandidate(candidate);
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
      for (final t in _localStream?.getTracks() ?? const []) {
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
      await s.cancel();
    }
    try {
      await _localStream?.dispose();
      await _pc?.close();
    } catch (_) {}
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    // caller가 통화 정보를 정리한다(다음 통화를 위해).
    if (isCaller) {
      await _resetCallDoc();
    }
  }
}
