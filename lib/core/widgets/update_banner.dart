import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../services/version_watcher.dart';
import '../theme/app_theme.dart';
import 'bouncy_tap.dart';

/// 새 버전이 올라왔을 때 화면 맨 위에 뜨는 띠.
///
/// 알려 줄 것이 없으면 자리를 차지하지 않는다.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final watcher = context.watch<VersionWatcher>();
    if (!watcher.updateAvailable) return const SizedBox.shrink();

    final label = watcher.newVersionLabel;

    return Material(
      color: AppColors.pinkSoft,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpace.md.w, 8.h, AppSpace.xs.w, 8.h),
          child: Row(
            children: [
              Icon(Icons.rocket_launch_rounded,
                  size: 18.sp, color: AppColors.pink),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label.isEmpty ? '새 버전이 나왔어요' : '새 버전 $label이 나왔어요',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mintDeep,
                      ),
                    ),
                    Text(
                      '받으면 잠깐 로딩 화면이 보여요',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              BouncyTap(
                onTap: watcher.applyUpdate,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.pink,
                    borderRadius: BorderRadius.circular(AppRadius.pill.r),
                  ),
                  child: Text(
                    '지금 받기',
                    style: AppTheme.font(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: watcher.dismiss,
                icon: Icon(Icons.close_rounded,
                    size: 18.sp, color: AppColors.gray),
                tooltip: '나중에',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
