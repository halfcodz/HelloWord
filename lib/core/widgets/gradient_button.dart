import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import 'bouncy_tap.dart';

/// 화면의 주요 동작 버튼.
/// Flat 디자인이라 그라데이션·번쩍이는 그림자 없이 단색 + 탭 반응만 준다.
/// (이름은 예전 코드 호환을 위해 유지한다.)
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    // 비활성은 투명도만 낮추지 않고 색 자체를 바꿔 '못 누르는 상태'를 분명히 한다.
    final background = enabled ? AppColors.pink : AppColors.border;
    final foreground = enabled ? Colors.white : AppColors.hint;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: BouncyTap(
        onTap: enabled ? onPressed : null,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          height: 54.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.md.r),
          ),
          child: loading
              ? SizedBox(
                  height: 22.h,
                  width: 22.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: foreground, size: AppIconSize.sm.sp),
                      SizedBox(width: AppSpace.xs.w),
                    ],
                    Text(
                      label,
                      style: AppTheme.font(
                        color: foreground,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
