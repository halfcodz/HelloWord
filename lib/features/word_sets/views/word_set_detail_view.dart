import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../models/app_user.dart';
import '../../exam/repositories/exam_repository.dart';
import '../../exam/views/session_monitor_view.dart';
import '../models/word_set.dart';

/// 저장된 단어 세트의 상세(단어 목록) 화면.
class WordSetDetailView extends StatelessWidget {
  const WordSetDetailView({super.key, required this.set, required this.user});

  final WordSet set;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(set.title)),
      bottomNavigationBar: _StartExamButton(set: set, user: user),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14.sp),
                    SizedBox(width: 4.w),
                    Text(formatYmd(set.date), style: theme.textTheme.bodyMedium),
                    SizedBox(width: 12.w),
                    Icon(Icons.style_outlined, size: 14.sp),
                    SizedBox(width: 4.w),
                    Text('${set.wordCount}개', style: theme.textTheme.bodyMedium),
                  ],
                ),
                if (set.message.trim().isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Text(
                    '💬 ${set.message}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: set.words.length,
              separatorBuilder: (_, _) => Divider(height: 1.h),
              itemBuilder: (context, index) {
                final word = set.words[index];
                return ListTile(
                  dense: true,
                  leading: Text(
                    '${index + 1}',
                    style: theme.textTheme.bodySmall,
                  ),
                  title: Text(
                    word.english,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    word.korean,
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "이 단어로 시험 내기" 버튼. 세션을 만들고 감독 화면으로 이동한다.
class _StartExamButton extends StatefulWidget {
  const _StartExamButton({required this.set, required this.user});

  final WordSet set;
  final AppUser user;

  @override
  State<_StartExamButton> createState() => _StartExamButtonState();
}

class _StartExamButtonState extends State<_StartExamButton> {
  bool _creating = false;

  Future<void> _start() async {
    setState(() => _creating = true);
    try {
      final session = await context.read<ExamRepository>().createSession(
            wordSet: widget.set,
            hostUid: widget.user.uid,
            hostName: widget.user.name,
          );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SessionMonitorView(sessionId: session.id),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('시험을 시작하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: GradientButton(
          label: '이 단어로 시험 내기',
          icon: Icons.play_arrow_rounded,
          loading: _creating,
          onPressed: _creating ? null : _start,
        ),
      ),
    );
  }
}
