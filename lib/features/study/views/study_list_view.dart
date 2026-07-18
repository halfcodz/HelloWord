import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../models/app_user.dart';
import '../../social/repositories/friend_repository.dart';
import '../../word_sets/models/word_set.dart';
import '../../word_sets/repositories/word_set_repository.dart';
import '../viewmodels/study_viewmodel.dart';
import 'flashcard_study_view.dart';

/// 동생 공부 탭: 언니가 올린 단어 세트로 혼자 공부한다.
class StudyListView extends StatelessWidget {
  const StudyListView({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StudyViewModel(
        friendRepository: context.read<FriendRepository>(),
        wordSetRepository: context.read<WordSetRepository>(),
        myUid: user.uid,
      ),
      child: const _StudyBody(),
    );
  }
}

class _StudyBody extends StatelessWidget {
  const _StudyBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StudyViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('공부하기 📖')),
      body: SafeArea(child: _content(context, viewModel)),
    );
  }

  Widget _content(BuildContext context, StudyViewModel viewModel) {
    if (viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📚', style: TextStyle(fontSize: 56.sp)),
              SizedBox(height: 16.h),
              Text('공부할 단어가 아직 없어요',
                  style: TextStyle(fontSize: 17.sp, color: AppColors.ink)),
              SizedBox(height: 8.h),
              Text(
                '내 정보에서 언니와 친구를 맺으면\n언니가 올린 단어로 공부할 수 있어요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: AppColors.lavender),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: viewModel.sets.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final set = viewModel.sets[index];
        return _StudyCard(
          set: set,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FlashcardStudyView(set: set),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: (index * 50).ms)
            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({required this.set, required this.onTap});

  final WordSet set;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: AppColors.softShadow(blur: 16, y: 7),
        ),
        child: Row(
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                gradient: AppColors.primaryButton,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(Icons.school_rounded, color: Colors.white, size: 24.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(set.title,
                      style: TextStyle(fontSize: 16.sp, color: AppColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: 2.h),
                  Text('${set.wordCount}개 단어 · 혼자 공부',
                      style: TextStyle(
                          fontSize: 12.sp, color: AppColors.lavender)),
                ],
              ),
            ),
            Icon(Icons.play_circle_fill_rounded,
                color: AppColors.pink, size: 28.sp),
          ],
        ),
      ),
    );
  }
}
