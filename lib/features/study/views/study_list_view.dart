import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../models/app_user.dart';
import '../../exam/models/exam_result.dart';
import '../../exam/repositories/exam_repository.dart';
import '../../word_sets/models/word_pair.dart';
import '../../word_sets/models/word_set.dart';
import '../../word_sets/repositories/word_set_repository.dart';
import '../services/memorized_store.dart';
import '../viewmodels/study_viewmodel.dart';
import 'exam_review_study_view.dart';
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
      child: _StudyBody(uid: user.uid),
    );
  }
}

class _StudyBody extends StatelessWidget {
  const _StudyBody({required this.uid});

  final String uid;

  /// 지난 시험들에서 틀린 단어를 중복 없이 모은다.
  List<WordPair> _wrongWords(List<ExamResult> results) {
    final seen = <String>{};
    final out = <WordPair>[];
    for (final r in results) {
      for (final it in r.items) {
        if (!it.correct) {
          final key = it.english.toLowerCase().trim();
          if (key.isNotEmpty && seen.add(key)) {
            out.add(WordPair(english: it.english, korean: it.korean));
          }
        }
      }
    }
    return out;
  }

  void _openStudyMenu(BuildContext context, WordSet set) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
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

  /// 받은 단어 세트 중 아직 안 외운 단어를 중복 없이 모은다.
  List<WordPair> _notMemorizedWords(List<WordSet> sets) {
    final seen = <String>{};
    final out = <WordPair>[];
    for (final s in sets) {
      for (final w in s.words) {
        final key = w.english.toLowerCase().trim();
        if (key.isEmpty || seen.contains(key)) continue;
        seen.add(key);
        if (!MemorizedStore.isMemorized(w.english)) out.add(w);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StudyViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('공부하기')),
      body: SafeArea(child: _body(context, viewModel)),
    );
  }

  Widget _body(BuildContext context, StudyViewModel viewModel) {
    if (viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final exam = context.read<ExamRepository>();
    return StreamBuilder<List<ExamResult>>(
      stream: exam.watchResultsForGuest(uid),
      builder: (context, snap) {
        final results = snap.data ?? const <ExamResult>[];
        final wrong = _wrongWords(results);
        final notMemorized = _notMemorizedWords(viewModel.sets);

        final children = <Widget>[];

        // ── 복습 카드(안 외운 단어 / 틀린 단어) ──
        if (notMemorized.isNotEmpty) {
          children.add(_ReviewCard(
            color: AppColors.pink,
            softColor: AppColors.blueSoft,
            icon: Icons.psychology_alt_rounded,
            title: '안 외운 단어 모아 공부',
            subtitle: '아직 안 외운 ${notMemorized.length}개 · 집중 복습',
            onTap: () => _openStudyMenu(
                context,
                _quickSet('not-memorized', '안 외운 단어', notMemorized)),
          ));
        }
        if (wrong.isNotEmpty) {
          children.add(_ReviewCard(
            color: AppColors.danger,
            softColor: AppColors.dangerSoft,
            icon: Icons.refresh_rounded,
            title: '틀린 단어 모아 복습',
            subtitle: '지난 시험에서 틀린 ${wrong.length}개 · 다시 외워봐요',
            onTap: () =>
                _openStudyMenu(context, _quickSet('wrong', '틀린 단어', wrong)),
          ));
        }

        // ── 지난 시험(눌러서 틀린 것 확인·공부) ──
        if (results.isNotEmpty) {
          children.add(_sectionLabel('지난 시험'));
          for (final r in results) {
            children.add(_ExamResultTile(
              result: r,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ExamReviewStudyView(result: r))),
            ));
          }
        }

        // ── 받은 단어 ──
        children.add(_sectionLabel('받은 단어'));
        if (viewModel.sets.isEmpty) {
          children.add(_emptySets());
        } else {
          for (final set in viewModel.sets) {
            children.add(Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child:
                  _StudyCard(set: set, onTap: () => _openStudyMenu(context, set)),
            ));
          }
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          children: children,
        );
      },
    );
  }

  WordSet _quickSet(String id, String title, List<WordPair> words) => WordSet(
        id: id,
        title: title,
        date: DateTime.now(),
        message: '',
        words: words,
        createdBy: '',
      );

  Widget _sectionLabel(String text) => Padding(
        padding: EdgeInsets.fromLTRB(4.w, 14.h, 4.w, 10.h),
        child: Text(text,
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
      );

  Widget _emptySets() => Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.rowBg,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Text('📚', style: TextStyle(fontSize: 40.sp)),
            SizedBox(height: 10.h),
            Text('받은 단어가 아직 없어요',
                style: TextStyle(fontSize: 15.sp, color: AppColors.ink)),
            SizedBox(height: 6.h),
            Text('언니가 단어를 보내주면 여기서 공부할 수 있어요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, color: AppColors.gray)),
          ],
        ),
      );
}

/// 상단 복습 카드(안 외운 단어 / 틀린 단어).
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.color,
    required this.softColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final Color softColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: BouncyTap(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: softColor,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(13.r),
                ),
                child: Icon(icon, color: Colors.white, size: 24.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    SizedBox(height: 2.h),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12.sp, color: AppColors.grayText)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 22.sp),
            ],
          ),
        ),
      ),
    );
  }
}

/// 지난 시험 한 줄(점수 + 틀린 개수). 누르면 틀린 것 확인·공부.
class _ExamResultTile extends StatelessWidget {
  const _ExamResultTile({required this.result, required this.onTap});

  final ExamResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wrong = result.total - result.score;
    final pass = result.percent >= 60;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: BouncyTap(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: pass ? AppColors.greenSoft : AppColors.dangerSoft,
                  shape: BoxShape.circle,
                ),
                child: Text('${result.percent}점',
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: pass ? AppColors.green : AppColors.danger)),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    SizedBox(height: 2.h),
                    Text(
                        wrong > 0
                            ? '틀린 $wrong개 · 눌러서 확인·공부'
                            : '다 맞았어요 🎉',
                        style: TextStyle(
                            fontSize: 12.sp,
                            color:
                                wrong > 0 ? AppColors.danger : AppColors.green)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.hint, size: 20.sp),
            ],
          ),
        ),
      ),
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
          color: AppColors.cream,
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
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(16.r),
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
