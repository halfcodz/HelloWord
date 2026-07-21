import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../models/app_user.dart';
import '../../exam/models/exam_result.dart';
import '../../exam/repositories/exam_repository.dart';
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
        final todayResults =
            results.where((r) => _isToday(r.createdAt)).toList();
        final pastResults =
            results.where((r) => !_isToday(r.createdAt)).toList();

        final todaySets =
            viewModel.sets.where((s) => _isToday(s.date)).toList();
        final pastSets =
            viewModel.sets.where((s) => !_isToday(s.date)).toList();

        final children = <Widget>[];

        // ── 오늘 시험(눌러서 틀린 것 확인·공부) ──
        if (results.isNotEmpty) {
          children.add(_sectionLabel('오늘 시험'));
          if (todayResults.isEmpty) {
            children.add(_hint('오늘 본 시험이 없어요.'));
          } else {
            for (final r in todayResults) {
              children.add(_examTile(context, r));
            }
          }
          if (pastResults.isNotEmpty) {
            children.add(_historyButton(
              context,
              '지난 시험 기록 (${pastResults.length})',
              '지난 시험',
              [for (final r in pastResults) _examTile(context, r)],
            ));
          }
        }

        // ── 오늘 받은 단어 ──
        children.add(_sectionLabel('오늘 받은 단어'));
        if (viewModel.sets.isEmpty) {
          children.add(_emptySets());
        } else if (todaySets.isEmpty) {
          children.add(_hint('오늘 받은 단어가 없어요.'));
        } else {
          for (final set in todaySets) {
            children.add(_setCard(context, set));
          }
        }
        if (pastSets.isNotEmpty) {
          children.add(_historyButton(
            context,
            '지난 단어 기록 (${pastSets.length})',
            '지난 단어',
            [for (final set in pastSets) _setCard(context, set)],
          ));
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          children: children,
        );
      },
    );
  }

  bool _isToday(DateTime? d) {
    if (d == null) return false;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  Widget _examTile(BuildContext context, ExamResult r) => _ExamResultTile(
        result: r,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ExamReviewStudyView(result: r))),
      );

  Widget _setCard(BuildContext context, WordSet set) => Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: _StudyCard(set: set, onTap: () => _openStudyMenu(context, set)),
      );

  Widget _historyButton(
      BuildContext context, String label, String title, List<Widget> items) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => _StudyHistoryView(title: title, items: items))),
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.rowBg,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            children: [
              Icon(Icons.history_rounded, size: 18.sp, color: AppColors.grayText),
              SizedBox(width: 8.w),
              Text(label,
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const Spacer(),
              Icon(Icons.chevron_right, color: AppColors.hint, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hint(String text) => Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.rowBg,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: AppColors.gray)),
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
                        '${result.createdAt != null ? "${formatYmd(result.createdAt!)} · " : ""}${wrong > 0 ? "틀린 $wrong개 · 눌러서 확인·공부" : "다 맞았어요 🎉"}',
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

/// 공부 세트 커버 카드(진행 바 포함). 다 외우면 흰 카드, 아니면 민트 그라디언트.
class _StudyCard extends StatelessWidget {
  const _StudyCard({required this.set, required this.onTap});

  final WordSet set;
  final VoidCallback onTap;

  int get _memorized =>
      set.words.where((w) => MemorizedStore.isMemorized(w.english)).length;

  @override
  Widget build(BuildContext context) {
    final total = set.wordCount;
    final done = _memorized;
    final complete = total > 0 && done >= total;
    final progress = total == 0 ? 0.0 : done / total;

    final onCard = complete ? AppColors.ink : Colors.white;
    final subColor = complete
        ? AppColors.gray
        : Colors.white.withValues(alpha: 0.85);

    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: complete ? AppColors.cream : null,
          gradient: complete ? null : AppColors.primaryButton,
          borderRadius: BorderRadius.circular(26.r),
          boxShadow: complete
              ? AppColors.softShadow()
              : [
                  BoxShadow(
                      color: AppColors.mint.withValues(alpha: 0.3),
                      blurRadius: 22,
                      offset: const Offset(0, 10)),
                ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12.w,
              bottom: -18.h,
              child: Text('📚',
                  style: TextStyle(
                      fontSize: 82.sp,
                      color: Colors.white.withValues(
                          alpha: complete ? 0.06 : 0.22))),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(complete ? '완료' : 'STUDY',
                    style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: subColor)),
                SizedBox(height: 4.h),
                Text(set.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w800,
                        color: onCard)),
                SizedBox(height: 2.h),
                Text(complete ? '$total단어 · 다 외웠어요 🎉' : '$total단어 · 혼자 공부',
                    style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: subColor)),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7.h,
                          backgroundColor: complete
                              ? AppColors.border
                              : Colors.white.withValues(alpha: 0.25),
                          valueColor: AlwaysStoppedAnimation(
                              complete ? AppColors.mint : Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text('$done/$total',
                        style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: onCard)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 지난 단어/시험 기록 화면.
class _StudyHistoryView extends StatelessWidget {
  const _StudyHistoryView({required this.title, required this.items});

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          children: items,
        ),
      ),
    );
  }
}
