import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/services/sfx_service.dart';
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

  /// 지금 통화를 켜는 중인지(두 번 켜지 않도록).
  bool _starting = false;

  /// 한 번이라도 연결된 적이 있는지(앱 복귀 후 완전 재연결 판단에 사용).
  bool _everConnected = false;

  /// 연결이 끊겨 자동으로 다시 붙이고 있는 중인지.
  bool _reconnecting = false;
  Timer? _resumeCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 통화 중에는 버튼 효과음을 멈춘다(마이크로 흘러 들어가지 않게).
    SfxService.instance?.suspend();
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
    // 이미 켜는 중이거나 켜져 있으면 두 번 시작하지 않는다
    // (카메라가 두 개 열려 하나가 검게 남는 것을 막는다).
    if (_starting || _ready) return;
    _starting = true;

    final service = CallService(
      sessionId: widget.sessionId,
      isCaller: widget.isCaller,
      onRemoteStream: () {
        // 원격 영상이 도착하면 UI를 강제로 다시 그린다.
        if (mounted) setState(() => _remoteActive = true);
      },
      onLocalStreamChanged: () {
        // 카메라를 다시 열었을 때(전화 등으로 끊겼다가 살아남) 다시 그린다.
        if (mounted) setState(() {});
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
    } catch (e) {
      debugPrint('영상통화 시작 실패: $e');
      await service.dispose();
      if (mounted) {
        setState(() => _error = _mediaErrorMessage(e));
      }
    } finally {
      _starting = false;
    }
  }

  /// 무엇 때문에 못 켰는지에 따라 할 수 있는 일을 알려 준다.
  String _mediaErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('notallowed') ||
        message.contains('permission') ||
        message.contains('denied')) {
      return '카메라·마이크 사용을 허용해 주세요.\n허용한 적이 없으면 다시 연결을 눌러 주세요.';
    }
    if (message.contains('notreadable') ||
        message.contains('trackstart') ||
        message.contains('aborterror')) {
      return '카메라를 다른 앱이 쓰고 있어요.\n그 앱을 닫고 다시 연결을 눌러 주세요.';
    }
    if (message.contains('notfound') || message.contains('devicesnotfound')) {
      return '카메라·마이크를 찾을 수 없어요.\n기기를 확인한 뒤 다시 연결을 눌러 주세요.';
    }
    if (message.contains('securityerror') ||
        message.contains('not supported') ||
        message.contains('unsupported') ||
        message.contains('mediadevices')) {
      return '이 브라우저에서는 영상통화를 켤 수 없어요.\n사파리에서 열어 주세요.';
    }
    return '카메라·마이크를 켤 수 없어요.\n잠시 뒤 다시 연결을 눌러 주세요.';
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
    SfxService.instance?.resume();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: widget.height ?? 200.h,
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
        Positioned.fill(
          child: RTCVideoView(
            service.remoteRenderer,
            // 세로로 찍힌 얼굴이 잘리지 않도록 전체 보기.
            // (그리기 방식만 바꾸는 것이라 연결에는 영향을 주지 않는다)
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
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
        // 내 영상 - 작게(PiP). 카메라를 못 열었으면 소리만 나가는 중이라고 알린다.
        Positioned(
          right: 10.w,
          top: 10.h,
          child: Container(
            width: 84.w,
            height: 112.h,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.navySoft,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.mintEnd, width: 2),
            ),
            child: service.isAudioOnly
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_rounded,
                          color: Colors.white70,
                          size: 20.sp,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '소리만',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  )
                : RTCVideoView(
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
