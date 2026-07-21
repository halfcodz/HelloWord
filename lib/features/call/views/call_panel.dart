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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 마이크(음성입력) 버튼 등으로 앱이 백그라운드에 갔다 돌아오면
    // 카메라·마이크가 꺼진 채 멈추므로, 돌아왔을 때 자동으로 다시 연결한다.
    if (state == AppLifecycleState.resumed &&
        _ready &&
        !_restarting &&
        mounted) {
      _restarting = true;
      _retry().whenComplete(() => _restarting = false);
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
          if (state == 'failed') _error = '상대와 연결하지 못했어요. 네트워크를 확인해 다시 시도해 주세요.';
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
    });
    await _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service?.dispose();
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
        color: const Color(0xFF2B2440),
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
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
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
                    _remoteActive
                        ? '상대 영상 불러오는 중…'
                        : (_connected ? '상대 영상 불러오는 중…' : '상대가 들어오길 기다리는 중…'),
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                  ),
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
              border: Border.all(color: Colors.white, width: 2),
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
