import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_user.dart';
import '../models/exam_session.dart';
import '../repositories/exam_repository.dart';
import 'session_exam_view.dart';

/// 언니가 보낸 시험 초대를 열어 수락/거절을 받는다.
///
/// 예전에는 초대가 오면 곧바로 팝업이 떴지만, 지금은 동생 홈의 '오늘 시험'에
/// 초대 카드가 쌓이고 그 카드를 눌렀을 때 이 화면이 열린다.
/// 수락하면 세션에 들어가 바로 시험 화면으로 넘어간다.
Future<void> showExamInvite(
  BuildContext context,
  ExamSession session,
  AppUser user,
) async {
  final repo = context.read<ExamRepository>();
  final choice = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '시험 초대',
    barrierColor: AppColors.navy.withValues(alpha: 0.6),
    transitionDuration: AppMotion.slow,
    pageBuilder: (context, _, _) => ExamInviteCard(session: session),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: AppMotion.enter);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
  if (!context.mounted) return;

  if (choice == true) {
    await repo.joinSession(
      sessionId: session.id,
      guestUid: user.uid,
      guestName: user.name,
    );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionExamView(sessionId: session.id, user: user),
      ),
    );
  } else if (choice == false) {
    await repo.declineInvite(session.id);
  }
}

/// 초대 내용을 크게 보여 주는 화면.
class ExamInviteCard extends StatelessWidget {
  const ExamInviteCard({super.key, required this.session});

  final ExamSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpace.xl.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 110.w,
                height: 110.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.navySoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.mintEnd, width: 4),
                ),
                child: Text('🐰', style: TextStyle(fontSize: 54.sp)),
              ),
              SizedBox(height: AppSpace.lg.h),
              Text(
                '${session.hostName}가 시험에\n초대했어요!',
                textAlign: TextAlign.center,
                style: AppTheme.display(
                  fontSize: 24.sp,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: AppSpace.sm.h),
              Text(
                '${session.title} · ${session.total}문제 · 영상통화',
                textAlign: TextAlign.center,
                style: AppTheme.font(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onNavy,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, 54.h),
                    textStyle: AppTheme.font(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('수락하고 시작하기'),
                ),
              ),
              SizedBox(height: AppSpace.xs.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, 50.h),
                    foregroundColor: AppColors.onNavy,
                    side: const BorderSide(color: Colors.white24, width: 1.5),
                  ),
                  child: const Text('지금은 어려워요'),
                ),
              ),
              SizedBox(height: AppSpace.lg.h),
            ],
          ),
        ),
      ),
    );
  }
}
