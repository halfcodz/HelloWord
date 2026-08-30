import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shuffle_toggle.dart';
import '../../../core/widgets/word_tile.dart';
import '../../word_sets/models/word_pair.dart';
import '../../word_sets/models/word_set.dart';
import '../widgets/memorize_filter.dart';

/// 단어 세트의 전체 단어 목록. 각 단어를 '외움' 체크할 수 있고
/// 전체 / 외운 것 / 안 외운 것으로 걸러 볼 수 있다.
class WordListView extends StatefulWidget {
  const WordListView({super.key, required this.set});

  final WordSet set;

  @override
  State<WordListView> createState() => _WordListViewState();
}

class _WordListViewState extends State<WordListView> {
  MemorizeFilter _filter = MemorizeFilter.all;

  /// 켜면 단어를 무작위 순서로 늘어놓는다.
  bool _random = false;

  /// 화면에 보여줄 기준 순서(무작위를 켤 때 한 번 섞어 고정한다).
  late List<WordPair> _base = widget.set.words;

  void _setRandom(bool on) {
    setState(() {
      _random = on;
      _base = on ? ([...widget.set.words]..shuffle()) : widget.set.words;
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = applyFilter(_base, _filter);
    return Scaffold(
      appBar: AppBar(title: Text(widget.set.title)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: MemorizeFilterBar(
                        value: _filter,
                        words: widget.set.words,
                        onChanged: (f) => setState(() => _filter = f),
                      ),
                    ),
                  ),
                  ShuffleChip(on: _random, onChanged: _setRandom),
                ],
              ),
            ),
            Expanded(
              child: words.isEmpty
                  ? Center(
                      child: Text(
                        _filter == MemorizeFilter.memorized
                            ? '아직 외운 단어가 없어요.\n단어를 체크해 표시해요!'
                            : '모두 외웠어요! 🎉',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp, color: AppColors.gray),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 20.h),
                      itemCount: words.length,
                      separatorBuilder: (_, _) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) => WordTile(
                        word: words[index],
                        trailing: MemorizeCheck(
                          key: ValueKey(words[index].english),
                          english: words[index].english,
                          // 필터가 걸려 있으면 체크 시 목록에서 사라지도록 갱신.
                          onChanged: () {
                            if (_filter != MemorizeFilter.all) {
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
