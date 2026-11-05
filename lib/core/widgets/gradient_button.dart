import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import 'bouncy_tap.dart';

/// 버터 알약 버튼. 그라데이션·그림자 없이 단색 + 탭 반응만 준다.
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
    final background = enabled ? AppColors.accent : AppColors.border;
    final foreground = enabled ? AppColors.onAccent : AppColors.hint;

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
            borderRadius: BorderRadius.circular(AppRadius.pill.r),
          ),
          child: loading
              ? SizedBox(
                  height: 22.h,
                  width: 22.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(AppColors.onAccent),
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
