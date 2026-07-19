import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_user.dart';
import '../../chat/views/chat_view.dart';
import '../repositories/friend_repository.dart';
import '../viewmodels/friends_viewmodel.dart';
import 'friend_avatar.dart';

/// Todomate풍 상단 프로필 바. 나 + 친구들의 아바타와 상태를 보여준다.
class FriendBar extends StatelessWidget {
  const FriendBar({super.key, required this.me});

  final AppUser me;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FriendsViewModel(
        repository: context.read<FriendRepository>(),
        me: me,
      ),
      child: _FriendBarBody(me: me),
    );
  }
}

class _FriendBarBody extends StatelessWidget {
  const _FriendBarBody({required this.me});

  final AppUser me;

  String _statusText(AppUser user) {
    if (user.studying && user.online) return '지금 공부 중이에요 🔥';
    if (user.online) return '접속 중이에요 💚';
    return '오프라인이에요';
  }

  void _showStatus(BuildContext context, AppUser user, {bool isMe = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${isMe ? "나" : user.name} · ${_statusText(user)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openChat(BuildContext context, AppUser friend) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatView(
          myUid: me.uid,
          otherUid: friend.uid,
          otherName: friend.name,
        ),
      ),
    );
  }

  /// 언니는 '동생', 동생은 '웅니'를 초대한다.
  String get _inviteTargetLabel =>
      me.role == UserRole.elder ? '동생' : '웅니';

  Future<void> _invite(
    BuildContext context,
    FriendsViewModel viewModel,
  ) async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$_inviteTargetLabel 초대하기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_inviteTargetLabel의 이메일을 입력하면 초대장을 보내요.\n상대가 승인하면 친구가 됩니다.'),
            SizedBox(height: 12.h),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: '이메일'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('초대'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;

    final result = await viewModel.invite(email);
    if (!context.mounted) return;
    final message = switch (result) {
      FriendAddResult.success => '초대장을 보냈어요! 상대가 승인하면 친구가 돼요',
      FriendAddResult.notFound => '그 이메일의 사용자를 찾지 못했어요.',
      FriendAddResult.self => '내 이메일은 초대할 수 없어요.',
      FriendAddResult.alreadyFriend => '이미 친구예요!',
      FriendAddResult.alreadyPending => '이미 초대장을 보냈어요.',
      FriendAddResult.error =>
        '초대 저장에 실패했어요. Firestore 규칙에 friendInvites 권한이 있는지 확인해 주세요.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FriendsViewModel>();
    final friends = viewModel.friends;

    return SizedBox(
      height: 92.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        children: [
          FriendAvatar(
            user: me,
            isMe: true,
            onTap: () => _showStatus(context, me, isMe: true),
          ),
          SizedBox(width: 8.w),
          for (final friend in friends) ...[
            FriendAvatar(
              user: friend,
              onTap: () => _openChat(context, friend),
            ),
            SizedBox(width: 8.w),
          ],
          _AddFriendButton(
            label: '$_inviteTargetLabel 초대',
            onTap: () => _invite(context, viewModel),
          ),
        ],
      ),
    );
  }
}

class _AddFriendButton extends StatelessWidget {
  const _AddFriendButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64.w,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: AppColors.fieldBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: AppColors.gray, size: 22.sp),
            ),
          ),
          SizedBox(height: 4.h),
          Text(label,
              style: TextStyle(fontSize: 11.sp, color: AppColors.hint)),
        ],
      ),
    );
  }
}
