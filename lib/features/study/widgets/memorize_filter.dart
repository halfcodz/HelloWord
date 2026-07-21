import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../word_sets/models/word_pair.dart';
import '../services/memorized_store.dart';

/// 공부 화면의 단어 필터. 전체 / 외운 것 / 안 외운 것.
enum MemorizeFilter { all, memorized, notMemorized }

extension MemorizeFilterX on MemorizeFilter {
  String get label => switch (this) {
        MemorizeFilter.all => '전체',
        MemorizeFilter.memorized => '외운 것',
        MemorizeFilter.notMemorized => '안 외운 것',
      };

  bool keep(WordPair w) {
    final m = MemorizedStore.isMemorized(w.english);
    return switch (this) {
      MemorizeFilter.all => true,
      MemorizeFilter.memorized => m,
      MemorizeFilter.notMemorized => !m,
    };
  }
}

/// 단어 목록을 현재 필터로 걸러 반환한다.
List<WordPair> applyFilter(List<WordPair> words, MemorizeFilter filter) =>
    words.where(filter.keep).toList();

/// 전체 / 외운 것 / 안 외운 것 필터 칩 줄.
class MemorizeFilterBar extends StatelessWidget {
  const MemorizeFilterBar({
    super.key,
    required this.value,
    required this.onChanged,
    required this.words,
  });

  final MemorizeFilter value;
  final ValueChanged<MemorizeFilter> onChanged;
  final List<WordPair> words;

  int _count(MemorizeFilter f) => words.where(f.keep).length;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      child: Row(
        children: [
          for (final f in MemorizeFilter.values) ...[
            _Chip(
              label: '${f.label} ${_count(f)}',
              selected: f == value,
              onTap: () => onChanged(f),
            ),
            SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.pink : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.grayText)),
      ),
    );
  }
}

/// 단어 하나의 '외움' 체크 버튼. 누르면 MemorizedStore에 저장/해제된다.
class MemorizeCheck extends StatefulWidget {
  const MemorizeCheck({super.key, required this.english, this.onChanged});

  final String english;
  final VoidCallback? onChanged;

  @override
  State<MemorizeCheck> createState() => _MemorizeCheckState();
}

class _MemorizeCheckState extends State<MemorizeCheck> {
  late bool _on = MemorizedStore.isMemorized(widget.english);

  Future<void> _toggle() async {
    final next = !_on;
    setState(() => _on = next);
    await MemorizedStore.setMemorized(widget.english, next);
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: Container(
        margin: EdgeInsets.only(left: 6.w),
        width: 40.w,
        height: 40.w,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 26.w,
          height: 26.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _on ? AppColors.green : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: _on ? AppColors.green : AppColors.hint,
              width: 2,
            ),
          ),
          child: _on
              ? Icon(Icons.check_rounded, size: 17.sp, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
