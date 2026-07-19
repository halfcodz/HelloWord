import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../models/app_user.dart';
import '../models/friend_invite.dart';
import '../repositories/friend_repository.dart';

/// 우측 상단 알림 버튼. 받은 친구 초대에 빨간 배지를 표시하고,
/// 누르면 승인/거절할 수 있는 목록을 연다.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.user});

  final AppUser user;

  void _openInvites(BuildContext context) {
    final repository = context.read<FriendRepository>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: StreamBuilder<List<FriendInvite>>(
            stream: repository.watchIncomingInvites(user.uid),
            builder: (context, snapshot) {
              final invites = snapshot.data ?? const <FriendInvite>[];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('알림',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17.sp, color: AppColors.ink)),
                  SizedBox(height: 16.h),
                  if (invites.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: Center(
                        child: Text('새 알림이 없어요',
                            style: TextStyle(
                                fontSize: 14.sp, color: AppColors.lavender)),
                      ),
                    )
                  else
                    ...invites.map((invite) => _InviteTile(
                          invite: invite,
                          onAccept: () => repository.acceptInvite(invite),
                          onReject: () => repository.rejectInvite(invite.id),
                        )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<FriendRepository>();
    return StreamBuilder<List<FriendInvite>>(
      stream: repository.watchIncomingInvites(user.uid),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: '알림',
              onPressed: () => _openInvites(context),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            if (count > 0)
              Positioned(
                right: 8.w,
                top: 8.h,
                child: Container(
                  width: 16.w,
                  height: 16.w,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4D6D),
                    shape: BoxShape.circle,
                  ),
                  child: Text('$count',
                      style: TextStyle(fontSize: 9.sp, color: Colors.white)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InviteTile extends StatelessWidget {
  const _InviteTile({
    required this.invite,
    required this.onAccept,
    required this.onReject,
  });

  final FriendInvite invite;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: AppColors.softShadow(blur: 10, y: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${invite.fromName}님이 친구 초대를 보냈어요',
              style: TextStyle(fontSize: 15.sp, color: AppColors.ink)),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    side: BorderSide(color: AppColors.pinkSoft),
                  ),
                  child: const Text('거절'),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                flex: 2,
                child: GradientButton(label: '승인', onPressed: onAccept),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
