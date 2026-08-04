import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/theme/app_theme.dart';
import '../services/call_service.dart';

/// 시험 중 영상통화 패널. 원격(상대) 영상을 크게, 내 영상을 작게 보여준다.
class CallPanel extends StatefulWidget {
  const CallPanel({
    super.key,
    required this.sessionId,
    required this.isCaller,
    this.height,
  });

  final String sessionId;
  final bool isCaller;

  /// 패널 높이. 키보드가 열릴 때 작게 줄이는 용도.
  final double? height;

  @override
  State<CallPanel> createState() => _CallPanelState();
}

class _CallPanelState extends State<CallPanel> with WidgetsBindingObserver {
  CallService? _service;
  String? _error;
  bool _ready = false;
  bool _remoteActive = false;
  bool _connected = false;
  bool _camOn = true;
  bool _micOn = true;
  bool _restarting = false;

  /// 상대 영상을 꽉 채워(잘라서) 볼지 여부.
  /// 기본은 false(전체 보기) — 잘라서 보면 세로 영상이 눈만 보이게 잘린다.
  bool _fillRemote = false;

  /// 한 번이라도 연결된 적이 있는지(앱 복귀 후 완전 재연결 판단에 사용).
  bool _everConnected = false;

  /// 연결이 끊겨 자동으로 다시 붙이고 있는 중인지.
  bool _reconnecting = false;
  Timer? _resumeCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_ready || !mounted) return;
    // 앱이 돌아오면 통화를 통째로 다시 만들지 않고 먼저 부드럽게 되살린다.
    // (통째로 다시 만들면 카메라가 껐다 켜지고 상대 화면이 끊긴다.)
    _service?.resume();
    _resumeCheck?.cancel();
    // 마이크(음성입력) 등으로 카메라가 아예 멈춰버린 경우를 대비해,
    // 잘 되던 통화가 잠시 뒤에도 살아나지 않으면 완전히 다시 연결한다.
    if (_everConnected) {
      _resumeCheck = Timer(const Duration(seconds: 8), () {
        if (!mounted || _connected || _restarting) return;
        _restarting = true;
        _retry().whenComplete(() => _restarting = false);
      });
    }
  }

  Future<void> _init() async {
    final service = CallService(
      sessionId: widget.sessionId,
      isCaller: widget.isCaller,
      onRemoteStream: () {
        // 원격 영상이 도착하면 UI를 강제로 다시 그린다.
        if (mounted) setState(() => _remoteActive = true);
      },
      onConnectionState: (state) {
        if (!mounted) return;
        setState(() {
          _connected = state == 'connected';
          if (_connected) {
            _everConnected = true;
            _error = null;
            _reconnecting = false;
          } else if (state == 'failed' || state == 'disconnected') {
            // 서비스가 스스로 다시 연결을 시도하므로 화면을 에러로 덮지 않는다.
            _reconnecting = true;
          }
        });
      },
    );
    try {
      await service.start();
      if (!mounted) {
        await service.dispose();
        return;
      }
      setState(() {
        _service = service;
        _ready = true;
      });
    } catch (_) {
      await service.dispose();
      if (mounted) {
        setState(() => _error = '카메라·마이크를 켤 수 없어요. 권한을 확인해 주세요.');
      }
    }
  }

  Future<void> _retry() async {
    await _service?.dispose();
    if (!mounted) return;
    setState(() {
      _service = null;
      _error = null;
      _ready = false;
      _remoteActive = false;
      _connected = false;
      _reconnecting = false;
    });
    await _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resumeCheck?.cancel();
    _service?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 높이 0이면(키보드가 열려 접힌 상태) 여백까지 없애 화면을 완전히 비워 준다.
    final height = widget.height ?? 200.h;
    final collapsed = height <= 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: height,
      margin: collapsed
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: AppColors.softShadow(blur: 12, y: 5),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 13.sp)),
              SizedBox(height: 12.h),
              FilledButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('다시 연결'),
              ),
            ],
          ),
        ),
      );
    }
    if (!_ready || _service == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white)),
            SizedBox(height: 12.h),
            Text('영상 연결 중…',
                style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
          ],
        ),
      );
    }

    final service = _service!;
    return Stack(
      children: [
        // 원격(상대) 영상 - 크게.
        // 기본은 '전체 보기'(Contain). 잘라서 채우면 세로로 찍힌 상대 영상이
        // 가로로 긴 패널에 맞춰 크게 잘려 얼굴이 눈만 보이게 된다.
        Positioned.fill(
          child: RTCVideoView(
            service.remoteRenderer,
            objectFit: _fillRemote
                ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
                : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
            placeholderBuilder: (_) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white54)),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    _reconnecting
                        ? '다시 연결하는 중…'
                        : (_remoteActive || _connected
                            ? '상대 영상 불러오는 중…'
                            : '상대가 들어오길 기다리는 중…'),
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                  ),
                  if (_reconnecting) ...[
                    SizedBox(height: 6.h),
                    TextButton(
                      onPressed: _restarting ? null : _retry,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text('다시 연결',
                          style: TextStyle(fontSize: 12.sp)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // 내 영상 - 작게(PiP).
        Positioned(
          right: 10.w,
          top: 10.h,
          child: Container(
            width: 84.w,
            height: 112.h,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.mintEnd, width: 2),
            ),
            child: RTCVideoView(
              service.localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ),
        // 컨트롤(카메라/마이크).
        Positioned(
          left: 0,
          right: 0,
          bottom: 8.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleButton(
                icon: _camOn ? Icons.videocam : Icons.videocam_off,
                onTap: () {
                  setState(() => _camOn = !_camOn);
                  service.toggleCamera(_camOn);
                },
              ),
              SizedBox(width: 16.w),
              _CircleButton(
                icon: _micOn ? Icons.mic : Icons.mic_off,
                onTap: () {
                  setState(() => _micOn = !_micOn);
                  service.toggleMic(_micOn);
                },
              ),
              SizedBox(width: 16.w),
              // 상대 영상을 '전체 보기 ↔ 꽉 채우기'로 바꾼다.
              _CircleButton(
                icon: _fillRemote
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                onTap: () => setState(() => _fillRemote = !_fillRemote),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20.sp),
      ),
    );
  }
}
