import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// 시험 중 1:1 영상통화(WebRTC)를 관리한다.
/// 시그널링(offer/answer/ICE 후보)은 Firestore를 통해 주고받고,
/// 실제 영상은 두 기기가 P2P로 직접 연결한다(무료 STUN/TURN 사용).
///
/// 재접속 대응: 한쪽이 앱을 나갔다 들어와도 다시 화면에 들어오면
/// 새 CallService가 start()되고, 언니(caller)는 연결이 끊기면 자동으로
/// 다시 offer(ICE restart)를 보내 영상을 재연결한다.
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
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];
  bool _hasRemote = false;
  String? _appliedOfferSdp; // 콜리(callee): 마지막으로 반영한 offer
  String? _appliedAnswerSdp; // 콜러(caller): 마지막으로 반영한 answer
  Timer? _restartTimer;
  bool _disposed = false;

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

    pc.onConnectionState = (state) => onConnectionState?.call(state.name);
    pc.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        onConnectionState?.call('connected');
        _restartTimer?.cancel();
      } else if (state ==
              RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        onConnectionState?.call(
            state == RTCIceConnectionState.RTCIceConnectionStateFailed
                ? 'failed'
                : 'disconnected');
        // 언니(caller)는 잠시 뒤 자동으로 다시 연결을 시도한다.
        if (isCaller) {
          _restartTimer?.cancel();
          _restartTimer = Timer(const Duration(seconds: 2), () {
            if (!_disposed) _reoffer(pc);
          });
        }
      }
    };

    final myCandidates = isCaller ? _callerCandidates : _calleeCandidates;
    pc.onIceCandidate = (candidate) => myCandidates.add(candidate.toMap());

    if (isCaller) {
      await _runCaller(pc);
    } else {
      await _runCallee(pc);
    }
  }

  Future<void> _runCaller(RTCPeerConnection pc) async {
    await _offer(pc, iceRestart: false);

    // 콜리의 answer가 오면(재접속 포함 새 answer마다) 반영한다.
    _subs.add(_callDoc.snapshots().listen((snap) async {
      if (_disposed) return;
      final answer = snap.data()?['answer'];
      final sdp = answer?['sdp'] as String?;
      if (sdp == null || sdp == _appliedAnswerSdp) return;
      _appliedAnswerSdp = sdp;
      await pc.setRemoteDescription(
          RTCSessionDescription(sdp, answer['type'] as String?));
      _hasRemote = true;
      await _flushPendingCandidates(pc);
    }));

    _subs.add(_calleeCandidates.snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _addCandidate(pc, change.doc.data());
        }
      }
    }));
  }

  Future<void> _runCallee(RTCPeerConnection pc) async {
    // 재접속 시 깨끗하게 다시 협상하도록 내 후보를 비운다.
    await _clearCandidates(_calleeCandidates);

    // offer가 새로 오면(재접속 포함) 매번 answer를 만들어 응답한다.
    _subs.add(_callDoc.snapshots().listen((snap) async {
      if (_disposed) return;
      final offer = snap.data()?['offer'];
      final sdp = offer?['sdp'] as String?;
      if (sdp == null || sdp == _appliedOfferSdp) return;
      _appliedOfferSdp = sdp;
      await pc.setRemoteDescription(
          RTCSessionDescription(sdp, offer['type'] as String?));
      _hasRemote = true;
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      await _callDoc.set({'answer': answer.toMap()}, SetOptions(merge: true));
      await _flushPendingCandidates(pc);
    }));

    _subs.add(_callerCandidates.snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _addCandidate(pc, change.doc.data());
        }
      }
    }));
  }

  /// 콜러가 offer를 만들어 보낸다. (초기 연결/재연결 공통)
  Future<void> _offer(RTCPeerConnection pc, {required bool iceRestart}) async {
    final offer = await pc.createOffer(
        iceRestart ? {'iceRestart': true} : const {});
    await pc.setLocalDescription(offer);
    await _callDoc.set({'offer': offer.toMap()}, SetOptions(merge: true));
  }

  /// 연결이 끊겼을 때 콜러가 후보를 비우고 다시 offer한다(ICE restart).
  Future<void> _reoffer(RTCPeerConnection pc) async {
    if (_disposed) return;
    try {
      await _clearCandidates(_callerCandidates);
      await _clearCandidates(_calleeCandidates);
      await _callDoc.set({'answer': null}, SetOptions(merge: true));
      _appliedAnswerSdp = null;
      await _offer(pc, iceRestart: true);
    } catch (_) {}
  }

  void _addCandidate(RTCPeerConnection pc, Map<String, dynamic>? data) {
    if (data == null) return;
    final candidate = RTCIceCandidate(
      data['candidate'] as String?,
      data['sdpMid'] as String?,
      data['sdpMLineIndex'] as int?,
    );
    if (_hasRemote) {
      pc.addCandidate(candidate);
    } else {
      _pendingRemoteCandidates.add(candidate);
    }
  }

  Future<void> _flushPendingCandidates(RTCPeerConnection pc) async {
    for (final candidate in _pendingRemoteCandidates) {
      await pc.addCandidate(candidate);
    }
    _pendingRemoteCandidates.clear();
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
    _restartTimer?.cancel();

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
      try {
        await _clearCandidates(_callerCandidates);
        await _clearCandidates(_calleeCandidates);
        await _callDoc.delete();
      } catch (_) {}
    }
  }
}
