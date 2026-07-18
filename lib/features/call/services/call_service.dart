import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// 시험 중 1:1 영상통화(WebRTC)를 관리한다.
/// 시그널링(offer/answer/ICE 후보)은 Firestore를 통해 주고받고,
/// 실제 영상은 두 기기가 P2P로 직접 연결한다(무료 STUN 사용).
class CallService {
  CallService({
    required this.sessionId,
    required this.isCaller,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 언니(host)를 caller로 둔다.
  final String sessionId;
  final bool isCaller;
  final FirebaseFirestore _firestore;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  final List<StreamSubscription> _subs = [];
  bool _remoteDescSet = false;
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
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
    ],
  };

  /// 카메라/마이크 시작 + 피어 연결 수립. 실패 시 예외를 던진다.
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
      }
    };

    final myCandidates = isCaller ? _callerCandidates : _calleeCandidates;
    pc.onIceCandidate = (candidate) {
      myCandidates.add(candidate.toMap());
    };

    if (isCaller) {
      await _runCaller(pc);
    } else {
      await _runCallee(pc);
    }
  }

  Future<void> _runCaller(RTCPeerConnection pc) async {
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    await _callDoc.set({'offer': offer.toMap()}, SetOptions(merge: true));

    _subs.add(_callDoc.snapshots().listen((snap) async {
      final data = snap.data();
      if (data == null || _remoteDescSet) return;
      final answer = data['answer'];
      if (answer != null) {
        _remoteDescSet = true;
        await pc.setRemoteDescription(
          RTCSessionDescription(answer['sdp'], answer['type']),
        );
      }
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
    _subs.add(_callDoc.snapshots().listen((snap) async {
      final data = snap.data();
      if (data == null || _remoteDescSet) return;
      final offer = data['offer'];
      if (offer != null) {
        _remoteDescSet = true;
        await pc.setRemoteDescription(
          RTCSessionDescription(offer['sdp'], offer['type']),
        );
        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        await _callDoc.set({'answer': answer.toMap()}, SetOptions(merge: true));
      }
    }));

    _subs.add(_callerCandidates.snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _addCandidate(pc, change.doc.data());
        }
      }
    }));
  }

  void _addCandidate(RTCPeerConnection pc, Map<String, dynamic>? data) {
    if (data == null) return;
    pc.addCandidate(RTCIceCandidate(
      data['candidate'] as String?,
      data['sdpMid'] as String?,
      data['sdpMLineIndex'] as int?,
    ));
  }

  /// 카메라 on/off 토글.
  void toggleCamera(bool enabled) {
    _localStream?.getVideoTracks().forEach((t) => t.enabled = enabled);
  }

  /// 마이크 on/off 토글.
  void toggleMic(bool enabled) {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = enabled);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
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
        final caller = await _callerCandidates.get();
        for (final d in caller.docs) {
          await d.reference.delete();
        }
        final callee = await _calleeCandidates.get();
        for (final d in callee.docs) {
          await d.reference.delete();
        }
        await _callDoc.delete();
      } catch (_) {}
    }
  }
}
