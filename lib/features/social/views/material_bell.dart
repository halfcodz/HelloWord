import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../models/app_user.dart';
import '../../word_sets/models/word_set.dart';
import '../../word_sets/repositories/word_set_repository.dart';
import '../../word_sets/services/seen_materials_store.dart';
import '../models/friend_invite.dart';
import '../repositories/friend_repository.dart';

/// 동생 홈 우측 상단 알림 버튼.
/// 언니가 새 단어 자료를 올리면 '푸른색 그라데이션' 배지로 알린다.
/// (친구 초대 알림도 함께 보여준다.)
class MaterialBell extends StatefulWidget {
  const MaterialBell({super.key, required this.user});

  final AppUser user;

  @override
  State<MaterialBell> createState() => _MaterialBellState();
}

class _MaterialBellState extends State<MaterialBell> {
  List<WordSet> _newMaterials(List<WordSet> sets) {
    final seen = SeenMaterialsStore.lastSeenMs;
    final list = sets
        .where((s) => (s.createdAt?.millisecondsSinceEpoch ?? 0) > seen)
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final wordSets = context.read<WordSetRepository>();
    final friends = context.read<FriendRepository>();

    return StreamBuilder<List<WordSet>>(
      stream: wordSets.watchSharedWith(widget.user.uid),
      builder: (context, setSnap) {
        final newMats = _newMaterials(setSnap.data ?? const <WordSet>[]);
        return StreamBuilder<List<FriendInvite>>(
          stream: friends.watchIncomingInvites(widget.user.uid),
          builder: (context, invSnap) {
            final invites = invSnap.data ?? const <FriendInvite>[];
            final total = newMats.length + invites.length;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: '알림',
                  onPressed: () => _open(context, newMats),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                // 알림이 있으면 빨간 점만 표시(개수·색상 표시 없음).
                if (total > 0)
                  Positioned(
                    right: 10.w,
                    top: 10.h,
                    child: Container(
                      width: 9.w,
                      height: 9.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4D),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.4),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _open(BuildContext context, List<WordSet> newMats) async {
    // 알림을 열면 새 자료는 확인 처리(배지 사라짐).
    await SeenMaterialsStore.markSeenNow();
    if (mounted) setState(() {});
    if (!context.mounted) return;

    final friends = context.read<FriendRepository>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
          child: StreamBuilder<List<FriendInvite>>(
            stream: friends.watchIncomingInvites(widget.user.uid),
            builder: (context, snap) {
              final invites = snap.data ?? const <FriendInvite>[];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text('알림',
                        style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                  ),
                  SizedBox(height: 16.h),
                  if (newMats.isEmpty && invites.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: Center(
                        child: Text('새 알림이 없어요',
                            style: TextStyle(
                                fontSize: 14.sp, color: AppColors.gray)),
                      ),
                    ),
                  if (newMats.isNotEmpty) ...[
                    _sheetLabel('📚 새 단어 자료가 왔어요'),
                    SizedBox(height: 8.h),
                    for (final set in newMats) _MaterialTile(set: set),
                    Padding(
                      padding: EdgeInsets.only(top: 2.h, bottom: 4.h, left: 2.w),
                      child: Text('공부 탭에서 바로 학습할 수 있어요.',
                          style: TextStyle(
                              fontSize: 12.sp, color: AppColors.gray)),
                    ),
                  ],
                  if (invites.isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    _sheetLabel('👋 친구 초대'),
                    SizedBox(height: 8.h),
                    for (final invite in invites)
                      _InviteTile(
                        invite: invite,
                        onAccept: () => friends.acceptInvite(invite),
                        onReject: () => friends.rejectInvite(invite.id),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) => Text(text,
      style: TextStyle(
          fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.ink));
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.set});

  final WordSet set;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFD6E4FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3D7BFF), Color(0xFF00D2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text('📩', style: TextStyle(fontSize: 18.sp)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(set.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                SizedBox(height: 2.h),
                Text(
                    '${set.wordCount}개 단어${set.createdAt != null ? " · ${formatYmd(set.createdAt!)}" : ""}',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.gray)),
              ],
            ),
          ),
        ],
      ),
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
                    side: BorderSide(color: AppColors.border),
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
