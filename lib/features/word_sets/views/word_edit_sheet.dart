import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../models/word_pair.dart';
import '../utils/word_file_parser.dart';

/// 단어 하나를 직접 쓰거나 고치는 시트.
///
/// 새로 만들 때는 [word]를 비워 두고, 고칠 때는 기존 단어를 넘긴다.
/// 저장하면 채워진 [WordPair]를 돌려주고, 취소하면 null을 돌려준다.
Future<WordPair?> showWordEditSheet(
  BuildContext context, {
  WordPair? word,
}) {
  return showModalBottomSheet<WordPair>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _WordEditSheet(word: word),
  );
}

class _WordEditSheet extends StatefulWidget {
  const _WordEditSheet({this.word});

  final WordPair? word;

  @override
  State<_WordEditSheet> createState() => _WordEditSheetState();
}

class _WordEditSheetState extends State<_WordEditSheet> {
  late final _english = TextEditingController(text: widget.word?.english ?? '');
  late final _korean = TextEditingController(text: widget.word?.korean ?? '');
  late final _pronunciation =
      TextEditingController(text: widget.word?.pronunciation ?? '');
  late final _example = TextEditingController(text: widget.word?.example ?? '');

  String? _error;

  @override
  void dispose() {
    _english.dispose();
    _korean.dispose();
    _pronunciation.dispose();
    _example.dispose();
    super.dispose();
  }

  void _save() {
    final english = _english.text.trim();
    final korean = _korean.text.trim();
    if (english.isEmpty || korean.isEmpty) {
      setState(() => _error = '영어와 뜻은 둘 다 있어야 해요.');
      return;
    }
    Navigator.of(context).pop(
      WordPair(
        english: english,
        korean: korean,
        pronunciation: _pronunciation.text.trim(),
        example: _example.text.trim(),
        askMeaning: widget.word?.askMeaning ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.word != null;
    return Padding(
      // 키보드 위로 올려 준다.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpace.gutter.w,
            AppSpace.md.h,
            AppSpace.gutter.w,
            AppSpace.md.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill.r),
                  ),
                ),
              ),
              SizedBox(height: AppSpace.md.h),
              Text(
                editing ? '단어 고치기' : '단어 추가',
                style: AppTheme.display(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: AppSpace.md.h),
              TextField(
                controller: _english,
                autofocus: !editing,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: '영어',
                  hintText: 'apple',
                ),
              ),
              SizedBox(height: AppSpace.xs.h),
              TextField(
                controller: _korean,
                decoration: const InputDecoration(
                  labelText: '뜻',
                  hintText: '사과',
                ),
              ),
              SizedBox(height: AppSpace.xs.h),
              TextField(
                controller: _pronunciation,
                decoration: const InputDecoration(
                  labelText: '발음 (선택)',
                  hintText: 'ˈæpl',
                ),
              ),
              SizedBox(height: AppSpace.xs.h),
              TextField(
                controller: _example,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '예문 (선택)',
                  hintText: 'I ate an apple. 나는 사과를 먹었다.',
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: AppSpace.xs.h),
                Text(
                  _error!,
                  style: AppTheme.font(fontSize: 12.sp, color: AppColors.danger),
                ),
              ],
              SizedBox(height: AppSpace.md.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                  ),
                  SizedBox(width: AppSpace.xs.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(editing ? '저장' : '추가'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 표를 붙여넣어 단어를 여러 개 더하는 시트.
/// 붙여넣은 내용을 그 자리에서 읽어 몇 개가 들어오는지 보여 준다.
Future<List<WordPair>?> showPasteWordsSheet(BuildContext context) {
  return showModalBottomSheet<List<WordPair>>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _PasteWordsSheet(),
  );
}

class _PasteWordsSheet extends StatefulWidget {
  const _PasteWordsSheet();

  @override
  State<_PasteWordsSheet> createState() => _PasteWordsSheetState();
}

class _PasteWordsSheetState extends State<_PasteWordsSheet> {
  final _controller = TextEditingController();
  List<WordPair> _parsed = const [];
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    if (text.trim().isEmpty) {
      setState(() {
        _parsed = const [];
        _error = null;
      });
      return;
    }
    try {
      final result = WordFileParser.parseText(text);
      setState(() {
        _parsed = result.pairs;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _parsed = const [];
        _error = '읽을 수 없는 형식이에요. 한 줄에 "영어, 뜻"으로 넣어 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpace.gutter.w,
            AppSpace.md.h,
            AppSpace.gutter.w,
            AppSpace.md.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill.r),
                  ),
                ),
              ),
              SizedBox(height: AppSpace.md.h),
              Text(
                '표 붙여넣기',
                style: AppTheme.display(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: AppSpace.xxs.h),
              Text(
                '엑셀이나 표를 그대로 붙여넣어도 되고, 한 줄에 "영어, 뜻"으로 써도 돼요.',
                style: AppTheme.font(
                  fontSize: 12.sp,
                  height: 1.5,
                  color: AppColors.gray,
                ),
              ),
              SizedBox(height: AppSpace.sm.h),
              TextField(
                controller: _controller,
                autofocus: true,
                minLines: 5,
                maxLines: 10,
                onChanged: _onChanged,
                decoration: const InputDecoration(
                  hintText: 'apple, 사과\nbanana, 바나나',
                ),
              ),
              SizedBox(height: AppSpace.xs.h),
              Text(
                _error ??
                    (_parsed.isEmpty
                        ? '아직 읽은 단어가 없어요.'
                        : '${_parsed.length}개를 읽었어요.'),
                style: AppTheme.font(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: _error != null
                      ? AppColors.danger
                      : (_parsed.isEmpty ? AppColors.gray : AppColors.green),
                ),
              ),
              SizedBox(height: AppSpace.md.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                  ),
                  SizedBox(width: AppSpace.xs.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: _parsed.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(_parsed),
                      child: Text('${_parsed.length}개 추가'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 파일(엑셀·CSV·txt)에서 단어를 읽어 온다. 취소하면 null.
Future<List<WordPair>?> pickWordsFromFile() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx', 'xls', 'csv', 'txt'],
    withData: true,
  );
  final file = (result == null || result.files.isEmpty)
      ? null
      : result.files.first;
  if (file == null) return null;
  final Uint8List? bytes = file.bytes;
  if (bytes == null) return null;
  final parsed = WordFileParser.parse(fileName: file.name, bytes: bytes);
  return parsed.pairs;
}
