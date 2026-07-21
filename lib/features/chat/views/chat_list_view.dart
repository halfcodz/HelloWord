import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../models/app_user.dart';
import '../../social/repositories/friend_repository.dart';
import '../../social/viewmodels/friends_viewmodel.dart';
import '../../social/views/friend_avatar.dart';
import 'chat_view.dart';

/// 채팅 탭: 친구 목록에서 상대를 골라 대화한다.
class ChatListView extends StatelessWidget {
  const ChatListView({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FriendsViewModel(
        repository: context.read<FriendRepository>(),
        me: user,
      ),
      child: _ChatListBody(user: user),
    );
  }
}

class _ChatListBody extends StatelessWidget {
  const _ChatListBody({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FriendsViewModel>();
    final friends = viewModel.friends;

    return Scaffold(
      appBar: AppBar(title: const Text('채팅')),
      body: SafeArea(
        child: friends.isEmpty
            ? _EmptyFriends()
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                itemCount: friends.length,
                separatorBuilder: (_, _) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return _ChatFriendTile(
                    friend: friend,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatView(
                          myUid: user.uid,
                          otherUid: friend.uid,
                          otherName: friend.name,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ChatFriendTile extends StatelessWidget {
  const _ChatFriendTile({required this.friend, required this.onTap});

  final AppUser friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: AppColors.softShadow(blur: 12, y: 5),
        ),
        child: Row(
          children: [
            FriendAvatar(user: friend),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.name,
                      style: TextStyle(fontSize: 16.sp, color: AppColors.ink)),
                  SizedBox(height: 2.h),
                  Text(
                    friend.studying && friend.online
                        ? '지금 공부 중 🔥'
                        : friend.online
                            ? '접속 중 💚'
                            : '오프라인',
                    style: TextStyle(
                        fontSize: 12.sp, color: AppColors.lavender),
                  ),
                ],
              ),
            ),
            Icon(Icons.chat_bubble_rounded, color: AppColors.pink, size: 22.sp),
          ],
        ),
      ),
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💬', style: TextStyle(fontSize: 56.sp)),
            SizedBox(height: 16.h),
            Text('아직 친구가 없어요',
                style: TextStyle(fontSize: 17.sp, color: AppColors.ink)),
            SizedBox(height: 8.h),
            Text('홈 상단의 프로필 바에서\n＋ 버튼으로 친구를 추가해 보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: AppColors.lavender)),
          ],
        ),
      ),
    );
  }
}
