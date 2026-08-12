import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/services/sfx_service.dart';
import '../../../core/theme/app_theme.dart';
import '../services/call_service.dart';

/// 시험 중 영상통화 패널. 두 얼굴을 반반으로 나란히 보여준다.
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
  /// 비워 두면 [preferredHeight]로 계산한다.
  final double? height;

  /// 얼굴 한 칸의 가로:세로 비율(폰 카메라에 맞춘 세로 모양).
  static const double _tileRatio = 1.25;

  /// 키보드가 올라와 자리가 좁을 때의 비율.
  static const double _compactTileRatio = 0.95;

  /// 통화 패널에 알맞은 높이.
  ///
  /// **화면 '높이'가 아니라 '폭'을 기준으로 계산한다.** 높이로 재면 브라우저와
  /// 홈 화면 앱(PWA)에서 값이 달라지기 때문이다. 브라우저는 주소창이 화면
  /// 높이를 15%쯤 깎아먹는데, 그러면 `.h`로 잡은 높이도 같이 줄어들어
  /// 칸이 납작해지고 영상이 이상한 비율로 보인다. 폭은 둘이 똑같으므로
  /// 폭으로 재면 어디서 열어도 같은 모양이 된다.
  ///
  /// 다만 자리가 정말 없을 때(작은 폰 + 키보드)는 화면을 다 잡아먹지 않도록
  /// 남은 높이에 맞춰 줄인다.
  static double preferredHeight(BuildContext context, {bool compact = false}) {
    final media = MediaQuery.of(context);
    // 패널 좌우 여백(12.w씩)을 뺀 뒤 두 칸으로 나눈다(가운데 간격 4.w).
    final tileWidth = (media.size.width - 24.w - 4.w) / 2;
    final wanted = tileWidth * (compact ? _compactTileRatio : _tileRatio);

    // 상한은 자리가 정말 없을 때만 걸리게 넉넉히 둔다. 평소(키보드가 닫힌
    // 상태)에는 상한에 닿지 않아 브라우저·홈 화면 앱이 똑같은 높이가 된다.
    // 키보드가 올라오면 브라우저 쪽이 실제로 자리가 더 좁으므로 그때는
    // 상한이 걸려 조금 더 줄어든다(넘쳐서 잘리는 것보다 낫다).
    final available = media.size.height - media.viewInsets.bottom;
    final limit = available * (compact ? 0.34 : 0.36);
    return wanted < limit ? wanted : limit;
  }

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

  /// 한참(30초) 동안 한 번도 연결되지 않은 상태인지.
  /// 이때는 원인을 짐작할 수 있게 안내를 덧붙인다.
  bool _stuck = false;
  Timer? _stuckTimer;

  /// 30초가 지나도 연결이 안 되면 안내를 띄운다.
  void _armStuckTimer() {
    _stuckTimer?.cancel();
    _stuckTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || _connected) return;
      setState(() => _stuck = true);
    });
  }

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
            _stuck = false;
            _stuckTimer?.cancel();
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
      _armStuckTimer();
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
      _stuck = false;
    });
    await _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resumeCheck?.cancel();
    _stuckTimer?.cancel();
    _service?.dispose();
    SfxService.instance?.resume();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: widget.height ?? CallPanel.preferredHeight(context),
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
    // 두 얼굴을 딱 반반으로 나란히 놓는다.
    // 작게 겹쳐 놓던 예전 방식은 키보드가 올라와 패널이 납작해지면
    // 내 얼굴이 상대 얼굴을 거의 다 가려서 잘 보이지 않았다.
    return Stack(
      children: [
        Positioned.fill(
          child: Row(
            children: [
              Expanded(child: _remoteTile(service)),
              SizedBox(width: 4.w),
              Expanded(child: _localTile(service)),
            ],
          ),
        ),
        // 컨트롤(카메라/마이크).
        Positioned(
          left: 0,
          right: 0,
          bottom: 6.h,
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
              SizedBox(width: 12.w),
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

  /// 상대 얼굴(왼쪽 절반).
  Widget _remoteTile(CallService service) {
    return _tile(
      label: widget.isCaller ? '동생' : '언니',
      child: RTCVideoView(
        service.remoteRenderer,
        // 칸을 꽉 채운다. 칸 자체를 폰 카메라 비율에 맞춰 두었으므로
        // 잘려 나가는 부분은 거의 없다. [CallPanel.preferredHeight] 참고.
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        placeholderBuilder: (_) => _waitingPlaceholder(service),
      ),
    );
  }

  /// 내 얼굴(오른쪽 절반).
  Widget _localTile(CallService service) {
    return _tile(
      label: '나',
      child: service.isAudioOnly
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic_rounded, color: Colors.white70, size: 22.sp),
                  SizedBox(height: 4.h),
                  Text(
                    '소리만',
                    style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                  ),
                ],
              ),
            )
          : RTCVideoView(
              service.localRenderer,
              mirror: true,
              // 상대 칸과 똑같이 꽉 채우기.
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
    );
  }

  /// 얼굴 한 칸. 모서리를 둥글게 자르고 누구인지 작게 적어 준다.
  Widget _tile({required String label, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: ColoredBox(
        color: AppColors.navySoft,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned(
              left: 6.w,
              top: 5.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상대 얼굴이 아직 없을 때 그 칸에 띄우는 안내.
  /// 칸이 좁으니 문구는 최대한 짧게 쓴다.
  Widget _waitingPlaceholder(CallService service) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white54),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _reconnecting
                  ? '다시 연결 중…'
                  : (_remoteActive || _connected ? '불러오는 중…' : '기다리는 중…'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 11.sp),
            ),
            // 중계 서버가 없으면 서로 다른 망(한 명은 와이파이, 한 명은 LTE)에
            // 있을 때 영상·소리가 아예 가지 않는다. 원인을 알 수 있게 알려 준다.
            if (_stuck && !service.hasRelay) ...[
              SizedBox(height: 4.h),
              Text(
                '같은 와이파이면 잘 돼요',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 10.sp),
              ),
            ],
            if (_reconnecting) ...[
              SizedBox(height: 2.h),
              TextButton(
                onPressed: _restarting ? null : _retry,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                ),
                child: Text('다시 연결', style: TextStyle(fontSize: 11.sp)),
              ),
            ],
          ],
        ),
      ),
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
