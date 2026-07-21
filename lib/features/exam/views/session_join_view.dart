import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_user.dart';
import '../models/exam_session.dart';
import '../repositories/exam_repository.dart';
import 'session_exam_view.dart';

/// 동생(응시자)의 시험 탭: 언니가 보낸 시험 초대를 받아 승인/거절한다.
class SessionJoinView extends StatelessWidget {
  const SessionJoinView({super.key, required this.user});

  final AppUser user;

  Future<void> _accept(BuildContext context, ExamSession s) async {
    final repo = context.read<ExamRepository>();
    await repo.joinSession(
      sessionId: s.id,
      guestUid: user.uid,
      guestName: user.name,
    );
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SessionExamView(sessionId: s.id, user: user),
    ));
  }

  Future<void> _decline(BuildContext context, ExamSession s) async {
    await context.read<ExamRepository>().declineInvite(s.id);
  }

  @override
  Widget build(BuildContext context) {
    final exam = context.read<ExamRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('시험')),
      body: SafeArea(
        child: StreamBuilder<List<ExamSession>>(
          stream: exam.watchInvitesForGuest(user.uid),
          builder: (context, snap) {
            final invites = snap.data ?? const <ExamSession>[];
            if (invites.isEmpty) {
              return _Empty();
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(20.w),
              itemCount: invites.length,
              separatorBuilder: (_, _) => SizedBox(height: 14.h),
              itemBuilder: (context, index) => _InviteCard(
                session: invites[index],
                onAccept: () => _accept(context, invites[index]),
                onDecline: () => _decline(context, invites[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 120.h),
        Center(
          child: Column(
            children: [
              Container(
                width: 96.w,
                height: 96.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  shape: BoxShape.circle,
                ),
                child: Text('📩', style: TextStyle(fontSize: 44.sp)),
              ),
              SizedBox(height: 20.h),
              Text('아직 시험 초대가 없어요',
                  style: TextStyle(fontSize: 17.sp, color: AppColors.ink)),
              SizedBox(height: 8.h),
              Text('언니가 시험을 시작하면\n여기로 초대가 와요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.sp, color: AppColors.gray)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.session,
    required this.onAccept,
    required this.onDecline,
  });

  final ExamSession session;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow(blur: 12, y: 5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🐰', style: TextStyle(fontSize: 30.sp)),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${session.hostName}에게서 시험 초대가 왔어요!',
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    SizedBox(height: 2.h),
                    Text('${session.title} · ${session.total}문제',
                        style:
                            TextStyle(fontSize: 13.sp, color: AppColors.gray)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    side: BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.grayText,
                  ),
                  child: const Text('거절'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.videocam_rounded, size: 20),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                  ),
                  label: const Text('승인하고 시험 보기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
