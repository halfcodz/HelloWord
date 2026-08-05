import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/history_calendar_view.dart';
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

/// 동생 공부 탭: '오늘' / '지난' 큰 카드 2개 중 하나를 골라 들어간다.
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
      child: _StudyHome(uid: user.uid),
    );
  }
}

bool _isToday(DateTime? d) {
  if (d == null) return false;
  final n = DateTime.now();
  return d.year == n.year && d.month == n.month && d.day == n.day;
}

/// 공부 세트 학습 메뉴(플래시카드/직접입력/목록)를 띄우고, 고른 학습을 연다.
/// 학습에서 돌아올 때까지 기다리므로, 호출부에서 진행률을 새로고침할 수 있다.
Future<void> openStudyMenu(BuildContext context, WordSet set) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.cream,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                set.title,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            _MenuTile(
              icon: Icons.style_rounded,
              label: '플래시카드',
              hint: '카드를 넘기며 암기',
              onTap: () => Navigator.of(sheet).pop('flash'),
            ),
            SizedBox(height: 10.h),
            _MenuTile(
              icon: Icons.edit_rounded,
              label: '직접 입력 연습',
              hint: '시험처럼 직접 써보기',
              onTap: () => Navigator.of(sheet).pop('quiz'),
            ),
            SizedBox(height: 10.h),
            _MenuTile(
              icon: Icons.list_alt_rounded,
              label: '단어 목록',
              hint: '전체 단어 한눈에 보기',
              onTap: () => Navigator.of(sheet).pop('list'),
            ),
          ],
        ),
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  final Widget page;
  switch (choice) {
    case 'flash':
      page = FlashcardStudyView(set: set);
      break;
    case 'quiz':
      page = SelfQuizView(set: set);
      break;
    case 'list':
      page = WordListView(set: set);
      break;
    default:
      return;
  }
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

/// 공부 세트 커버 카드 한 장(여백 포함). 학습에서 돌아오면 onChanged로 진행률 갱신.
Widget studySetCard(
  BuildContext context,
  WordSet set, {
  VoidCallback? onChanged,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: 12.h),
    child: _StudyCard(
      set: set,
      onTap: () async {
        await openStudyMenu(context, set);
        onChanged?.call();
      },
    ),
  );
}

/// 지난 시험 한 줄(점수 + 틀린 개수). 누르면 틀린 것 확인·공부.
Widget examResultTile(BuildContext context, ExamResult r) {
  return _ExamResultTile(
    result: r,
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ExamReviewStudyView(result: r))),
  );
}

class _StudyHome extends StatelessWidget {
  const _StudyHome({required this.uid});

  final String uid;

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
    final exam = context.read<ExamRepository>();
    final now = DateTime.now();

    return StreamBuilder<List<ExamResult>>(
      stream: exam.watchResultsForGuest(uid),
      builder: (context, snap) {
        final results = snap.data ?? const <ExamResult>[];
        final todayResults = results
            .where((r) => _isToday(r.createdAt))
            .toList();
        final pastResults = results
            .where((r) => !_isToday(r.createdAt))
            .toList();

        final todaySets = viewModel.sets
            .where((s) => _isToday(s.date))
            .toList();
        final pastSets = viewModel.sets
            .where((s) => !_isToday(s.date))
            .toList();

        // 지난 단어·시험을 한 목록으로 모아 기록 화면에 넘긴다.
        final pastItems = <DatedItem>[
          for (final set in pastSets)
            DatedItem(date: set.date, child: studySetCard(context, set)),
          for (final r in pastResults)
            DatedItem(
              date: r.createdAt ?? now,
              child: examResultTile(context, r),
            ),
        ];

        // 오늘 받은 단어 중 얼마나 외웠는지.
        var total = 0;
        var memorized = 0;
        for (final set in todaySets) {
          total += set.words.length;
          memorized += set.words
              .where((w) => MemorizedStore.isMemorized(w.english))
              .length;
        }
        final ratio = total == 0 ? 0.0 : memorized / total;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: kBottomInset.h),
          children: [
            // 오늘 받은 단어가 있을 때만 진행 상황을 보여 준다.
            // (없을 때 빈 막대만 뜨면 무슨 뜻인지 알 수 없다)
            if (total > 0)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpace.gutter.w,
                  AppSpace.sm.h,
                  AppSpace.gutter.w,
                  0,
                ),
                child: AppCard(
                  color: AppColors.cream.withValues(alpha: 0.78),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '오늘 외운 단어',
                              style: AppTheme.font(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gray,
                              ),
                            ),
                          ),
                          Text(
                            '$memorized / $total',
                            style: AppTheme.tabularNumber(
                              fontSize: 16.sp,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpace.xs.h),
                      ProgressBar(value: ratio),
                    ],
                  ),
                ),
              ),
            SectionHeader(
              icon: Icons.menu_book_rounded,
              label: '오늘의 단어',
              actionLabel: todaySets.isEmpty ? null : '모아 보기',
              onAction: todaySets.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TodayStudyView(
                          sets: todaySets,
                          results: todayResults,
                        ),
                      ),
                    ),
            ),
            if (todaySets.isEmpty)
              EmptyState(
                icon: Icons.menu_book_rounded,
                text: '오늘 받은 단어가 없어요.\n언니가 자료를 올리면 여기에 바로 나와요.',
              )
            else
              // 카드를 눌러 바로 공부를 시작한다(예전처럼 화면을 한 번 더 들어가지 않는다).
              for (final set in todaySets)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpace.md.w),
                  child: studySetCard(context, set),
                ),
            if (todayResults.isNotEmpty) ...[
              SectionHeader(icon: Icons.fact_check_rounded, label: '오늘 본 시험'),
              for (final r in todayResults)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpace.md.w),
                  child: examResultTile(context, r),
                ),
            ],
            SectionHeader(
              icon: Icons.history_rounded,
              label: '지난 기록',
              actionLabel: pastItems.isEmpty ? null : '전체 보기',
              onAction: pastItems.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HistoryCalendarView(
                          title: '지난 기록',
                          items: pastItems,
                          emptyText: '이 날은 받은 단어나 시험이 없어요.',
                        ),
                      ),
                    ),
            ),
            if (pastItems.isEmpty)
              EmptyState(
                icon: Icons.history_rounded,
                text: '아직 지난 기록이 없어요.',
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpace.md.w),
                child: AppCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HistoryCalendarView(
                        title: '지난 기록',
                        items: pastItems,
                        emptyText: '이 날은 받은 단어나 시험이 없어요.',
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46.w,
                        height: 46.w,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.purpleSoft,
                          borderRadius: BorderRadius.circular(AppRadius.sm.r),
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          size: AppIconSize.md.sp,
                          color: AppColors.purple,
                        ),
                      ),
                      SizedBox(width: AppSpace.sm.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '지난 단어와 시험 ${pastItems.length}건',
                              style: AppTheme.display(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            SizedBox(height: AppSpace.xxs.h),
                            Text(
                              '날짜별로 모아 볼 수 있어요',
                              style: AppTheme.font(
                                fontSize: 12.sp,
                                color: AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.hint,
                        size: AppIconSize.md.sp,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 오늘의 공부: 오늘 시험과 오늘 받은 단어를 분리해서 보여준다.
class TodayStudyView extends StatefulWidget {
  const TodayStudyView({super.key, required this.sets, required this.results});

  final List<WordSet> sets;
  final List<ExamResult> results;

  @override
  State<TodayStudyView> createState() => _TodayStudyViewState();
}

class _TodayStudyViewState extends State<TodayStudyView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('오늘의 공부')),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          children: [
            const _SectionLabel('오늘 시험', icon: '📝'),
            if (widget.results.isEmpty)
              const _Hint('오늘 본 시험이 없어요.')
            else
              for (final r in widget.results) examResultTile(context, r),
            SizedBox(height: 6.h),
            const _SectionLabel('오늘 받은 단어', icon: '📚'),
            if (widget.sets.isEmpty)
              const _EmptySets()
            else
              for (final set in widget.sets)
                studySetCard(context, set, onChanged: () => setState(() {})),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.icon});

  final String text;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 14.h, 4.w, 10.h),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 17.sp)),
          SizedBox(width: 7.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.rowBg,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13.sp, color: AppColors.gray),
      ),
    );
  }
}

class _EmptySets extends StatelessWidget {
  const _EmptySets();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.rowBg,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_rounded, size: AppIconSize.lg.sp, color: AppColors.pink),
          SizedBox(height: 10.h),
          Text(
            '받은 단어가 아직 없어요',
            style: TextStyle(fontSize: 15.sp, color: AppColors.ink),
          ),
          SizedBox(height: 6.h),
          Text(
            '언니가 단어를 보내주면 여기서 공부할 수 있어요!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: AppColors.gray),
          ),
        ],
      ),
    );
  }
}

/// '오늘' / '지난'을 고르는 큰 선택 카드. dark=true면 네이비, 아니면 민트 그라디언트.
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
                child: Text(
                  '${result.percent}점',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: pass ? AppColors.green : AppColors.danger,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${result.createdAt != null ? "${formatYmd(result.createdAt!)} · " : ""}${wrong > 0 ? "틀린 $wrong개 · 눌러서 확인·공부" : "다 맞았어요 🎉"}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: wrong > 0 ? AppColors.danger : AppColors.green,
                      ),
                    ),
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
                color: AppColors.pink,
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Icon(icon, color: Colors.white, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 16.sp, color: AppColors.ink),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.lavender,
                    ),
                  ),
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

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpace.sm.h),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 진행 상태를 아이콘 하나로 먼저 알린다.
                Container(
                  width: 46.w,
                  height: 46.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: complete ? AppColors.greenSoft : AppColors.pinkSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm.r),
                  ),
                  child: Icon(
                    complete
                        ? Icons.check_circle_rounded
                        : Icons.menu_book_rounded,
                    size: AppIconSize.md.sp,
                    color: complete ? AppColors.green : AppColors.pink,
                  ),
                ),
                SizedBox(width: AppSpace.sm.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        set.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.display(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: AppSpace.xxs.h),
                      Text(
                        '${formatYmd(set.date)} · $total단어',
                        style: AppTheme.font(
                          fontSize: 12.sp,
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpace.xs.w),
                StatusChip(
                  label: complete ? '완료' : '$done/$total',
                  color: complete ? AppColors.green : AppColors.pink,
                  background: complete
                      ? AppColors.greenSoft
                      : AppColors.pinkSoft,
                ),
              ],
            ),
            SizedBox(height: AppSpace.sm.h),
            ProgressBar(
              value: progress,
              color: complete ? AppColors.green : AppColors.pink,
            ),
            SizedBox(height: AppSpace.xs.h),
            Row(
              children: [
                Icon(
                  Icons.play_circle_fill_rounded,
                  size: AppIconSize.sm.sp,
                  color: AppColors.pink,
                ),
                SizedBox(width: AppSpace.xxs.w),
                Text(
                  complete ? '다시 복습하기' : '공부 시작하기',
                  style: AppTheme.font(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
