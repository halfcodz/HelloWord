import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import 'bouncy_tap.dart';

/// 화면을 짜는 데 쓰는 공용 조각들.
/// 화면마다 카드·제목·빈 상태를 따로 만들지 않고 여기 것만 가져다 쓴다.

/// 홈 맨 위에 깔리는 큰 헤더 패널.
/// 인사말과 오늘의 숫자(통계)를 한 덩어리로 묶어 첫 화면의 중심을 만든다.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    this.trailing,
    this.stats = const [],
  });

  /// 큰 제목(예: "현구, 안녕!").
  final String title;

  /// 제목 위 작은 글씨(예: 날짜).
  final String subtitle;

  /// 제목 아래 강조 문구(예: "오늘 시험이 있어요").
  final String? badge;

  /// 오른쪽 위에 놓을 위젯(알림 벨 등).
  final Widget? trailing;

  /// 아래쪽 숫자 카드들.
  final List<HeroStat> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpace.gutter.w,
        AppSpace.md.h,
        AppSpace.gutter.w,
        AppSpace.md.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.pink,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: AppTheme.font(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    SizedBox(height: AppSpace.xxs.h),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.display(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (badge != null) ...[
            SizedBox(height: AppSpace.sm.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpace.sm.w,
                vertical: AppSpace.xxs.h + 2,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pill.r),
              ),
              child: Text(
                badge!,
                style: AppTheme.font(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          if (stats.isNotEmpty) ...[
            SizedBox(height: AppSpace.md.h),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) SizedBox(width: AppSpace.xs.w),
                    Expanded(child: stats[i]),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// [HeroHeader] 안에 들어가는 숫자 한 칸.
class HeroStat extends StatelessWidget {
  const HeroStat({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.onTap,
  });

  final String value;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpace.sm.w,
        vertical: AppSpace.sm.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.md.r),
      ),
      // 글자 크기 설정이 큰 기기에서도 칸을 넘치지 않도록
      // 각 줄을 Flexible + 축소 허용으로 둔다.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSize.sm.sp, color: Colors.white),
            SizedBox(height: AppSpace.xxs.h),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: AppTheme.tabularNumber(
                  fontSize: 20.sp,
                  color: Colors.white,
                ).copyWith(height: 1.1),
              ),
            ),
          ),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.font(
                fontSize: 11.sp,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return BouncyTap(onTap: onTap, child: card);
  }
}

/// 섹션 제목. 오른쪽에 '더보기' 같은 동작을 붙일 수 있다.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String label;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.gutter.w,
        AppSpace.lg.h,
        AppSpace.gutter.w - 8,
        AppSpace.xs.h,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSize.sm.sp, color: AppColors.pink),
            SizedBox(width: AppSpace.xs.w - 2),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTheme.display(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.symmetric(horizontal: AppSpace.xs.w),
              ),
              child: Text(actionLabel!, style: TextStyle(fontSize: 13.sp)),
            ),
        ],
      ),
    );
  }
}

/// 앱 전체에서 쓰는 기본 카드. 테두리로 구분하고 그림자는 쓰지 않는다.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.borderColor,
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(AppSpace.md.w),
      decoration: BoxDecoration(
        color: color ?? AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return BouncyTap(onTap: onTap, child: card);
  }
}

/// 내용이 없을 때 보여 주는 안내. 아이콘 + 설명 + (선택) 버튼.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpace.gutter.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: AppSpace.lg.h,
          horizontal: AppSpace.md.w,
        ),
        decoration: BoxDecoration(
          color: AppColors.rowBg,
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppIconSize.md.sp, color: AppColors.hint),
            ),
            SizedBox(height: AppSpace.sm.h),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTheme.font(
                fontSize: 13.sp,
                height: 1.5,
                color: AppColors.gray,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: AppSpace.sm.h),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  minimumSize: Size(0, 40.h),
                  padding: EdgeInsets.symmetric(horizontal: AppSpace.md.w),
                  textStyle: AppTheme.font(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 진행률 막대(공부한 단어 수 등).
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
  });

  /// 0~1.
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill.r),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height.h,
        backgroundColor: AppColors.border,
        valueColor: AlwaysStoppedAnimation(color ?? AppColors.pink),
      ),
    );
  }
}

/// 작은 상태 표시 칩(D-DAY, 개수, 완료 등).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.color,
    this.background,
    this.icon,
  });

  final String label;
  final Color? color;
  final Color? background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.pink;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpace.xs.w,
        vertical: AppSpace.xxs.h,
      ),
      decoration: BoxDecoration(
        color: background ?? AppColors.pinkSoft,
        borderRadius: BorderRadius.circular(AppRadius.xs.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13.sp, color: fg),
            SizedBox(width: 3.w),
          ],
          Text(
            label,
            style: AppTheme.font(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
