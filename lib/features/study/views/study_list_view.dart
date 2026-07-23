import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/bouncy_tap.dart';
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
              child: Text(set.title,
                  style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
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
Widget studySetCard(BuildContext context, WordSet set, {VoidCallback? onChanged}) {
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
    onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ExamReviewStudyView(result: r))),
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
        final todayResults = results.where((r) => _isToday(r.createdAt)).toList();
        final pastResults = results.where((r) => !_isToday(r.createdAt)).toList();

        final todaySets = viewModel.sets.where((s) => _isToday(s.date)).toList();
        final pastSets = viewModel.sets.where((s) => !_isToday(s.date)).toList();

        // 지난 자료(단어 + 시험)를 하나의 달력으로.
        final pastItems = <DatedItem>[
          for (final set in pastSets)
            DatedItem(date: set.date, child: studySetCard(context, set)),
          for (final r in pastResults)
            DatedItem(
                date: r.createdAt ?? now, child: examResultTile(context, r)),
        ];

        final todayCount = todaySets.length + todayResults.length;
        final pastCount = pastItems.length;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            Text('무엇을 공부해 볼까요?',
                style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            SizedBox(height: 4.h),
            Text('오늘의 자료로 공부하거나, 지난 기록을 달력에서 찾아봐요.',
                style: TextStyle(fontSize: 13.sp, color: AppColors.gray)),
            SizedBox(height: 18.h),
            _BigChoiceCard(
              emoji: '📖',
              badge: 'TODAY',
              title: '오늘의 공부',
              subtitle: todayCount == 0
                  ? '오늘 받은 자료가 아직 없어요'
                  : '받은 단어 ${todaySets.length}개 · 시험 ${todayResults.length}개',
              action: '공부하러 가기',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    TodayStudyView(sets: todaySets, results: todayResults),
              )),
            ),
            SizedBox(height: 14.h),
            _BigChoiceCard(
              emoji: '🗓️',
              badge: 'HISTORY',
              title: '지난 기록',
              subtitle: pastCount == 0
                  ? '아직 지난 기록이 없어요'
                  : '달력에서 지난 단어·시험 $pastCount건 찾기',
              action: '달력으로 보기',
              dark: true,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => HistoryCalendarView(
                  title: '지난 자료',
                  items: pastItems,
                  emptyText: '이 날은 받은 단어나 시험이 없어요.',
                ),
              )),
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
                studySetCard(context, set,
                    onChanged: () => setState(() {})),
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
          Text(text,
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
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
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.sp, color: AppColors.gray)),
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
}

/// '오늘' / '지난'을 고르는 큰 선택 카드. dark=true면 네이비, 아니면 민트 그라디언트.
class _BigChoiceCard extends StatelessWidget {
  const _BigChoiceCard({
    required this.emoji,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
    this.dark = false,
  });

  final String emoji;
  final String badge;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final sub = Colors.white.withValues(alpha: 0.85);
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(22.w),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: dark ? AppColors.navy : null,
          gradient: dark ? null : AppColors.primaryButton,
          borderRadius: BorderRadius.circular(26.r),
          boxShadow: [
            BoxShadow(
              color: (dark ? AppColors.navy : AppColors.mint)
                  .withValues(alpha: dark ? 0.28 : 0.3),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10.w,
              bottom: -22.h,
              child: Text(emoji,
                  style: TextStyle(
                      fontSize: 96.sp,
                      color: Colors.white.withValues(alpha: 0.16))),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(badge,
                      style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white)),
                ),
                SizedBox(height: 14.h),
                Text(title,
                    style: TextStyle(
                        fontSize: 23.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                SizedBox(height: 4.h),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: sub)),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Text(action,
                        style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    SizedBox(width: 6.w),
                    Container(
                      width: 26.w,
                      height: 26.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 16.sp, color: Colors.white),
                    ),
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
                      style: TextStyle(fontSize: 16.sp, color: AppColors.ink)),
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
    final subColor =
        complete ? AppColors.gray : Colors.white.withValues(alpha: 0.85);

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
                      color: Colors.white
                          .withValues(alpha: complete ? 0.06 : 0.22))),
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
