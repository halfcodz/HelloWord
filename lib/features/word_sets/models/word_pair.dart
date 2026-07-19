/// 영단어 한 쌍 (영어 - 해석). 발음·예문은 선택 정보.
class WordPair {
  const WordPair({
    required this.english,
    required this.korean,
    this.pronunciation = '',
    this.example = '',
  });

  final String english;
  final String korean;

  /// 발음 표기(예: "디스커버"). 없으면 빈 문자열.
  final String pronunciation;

  /// 예문(예: "I discovered a park. 나는 공원을 발견했다."). 없으면 빈 문자열.
  final String example;

  bool get hasExtra => pronunciation.isNotEmpty || example.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'en': english,
        'ko': korean,
        if (pronunciation.isNotEmpty) 'pron': pronunciation,
        if (example.isNotEmpty) 'ex': example,
      };

  factory WordPair.fromMap(Map<String, dynamic> map) => WordPair(
        english: (map['en'] as String? ?? '').trim(),
        korean: (map['ko'] as String? ?? '').trim(),
        pronunciation: (map['pron'] as String? ?? '').trim(),
        example: (map['ex'] as String? ?? '').trim(),
      );
}
