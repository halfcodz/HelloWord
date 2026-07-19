import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../models/app_user.dart';
import '../../word_sets/models/word_set.dart';
import '../../word_sets/repositories/word_set_repository.dart';
import '../viewmodels/study_viewmodel.dart';
import 'flashcard_study_view.dart';
import 'self_quiz_view.dart';
import 'word_list_view.dart';

/// 동생 공부 탭: 언니가 올린 단어 세트로 혼자 공부한다.
class StudyListView extends StatelessWidget {
  const StudyListView({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StudyViewModel(
        wordSetRepository: context.read<WordSetRepository>(),
        myUid: user.uid,
      ),
      child: const _StudyBody(),
    );
  }
}

class _StudyBody extends StatelessWidget {
  const _StudyBody();

  void _openStudyMenu(BuildContext context, WordSet set) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(set.title,
                    style: TextStyle(fontSize: 17.sp, color: AppColors.ink)),
              ),
              SizedBox(height: 16.h),
              _MenuTile(
                icon: Icons.style_rounded,
                label: '플래시카드',
                hint: '카드를 넘기며 암기',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FlashcardStudyView(set: set)));
                },
              ),
              SizedBox(height: 10.h),
              _MenuTile(
                icon: Icons.edit_rounded,
                label: '직접 입력 연습',
                hint: '시험처럼 직접 써보기',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SelfQuizView(set: set)));
                },
              ),
              SizedBox(height: 10.h),
              _MenuTile(
                icon: Icons.list_alt_rounded,
                label: '단어 목록',
                hint: '전체 단어 한눈에 보기',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => WordListView(set: set)));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StudyViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('공부하기')),
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
          onTap: () => _openStudyMenu(context, set),
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: (index * 50).ms)
            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: AppColors.softShadow(blur: 10, y: 4),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                gradient: AppColors.primaryButton,
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Icon(icon, color: Colors.white, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          TextStyle(fontSize: 16.sp, color: AppColors.ink)),
                  SizedBox(height: 2.h),
                  Text(hint,
                      style: TextStyle(
                          fontSize: 12.sp, color: AppColors.lavender)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.lavender, size: 20.sp),
          ],
        ),
      ),
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
