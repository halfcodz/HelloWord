/// 영단어 한 쌍 (영어 - 해석).
class WordPair {
  const WordPair({required this.english, required this.korean});

  final String english;
  final String korean;

  Map<String, dynamic> toMap() => {'en': english, 'ko': korean};

  factory WordPair.fromMap(Map<String, dynamic> map) => WordPair(
        english: (map['en'] as String? ?? '').trim(),
        korean: (map['ko'] as String? ?? '').trim(),
      );
}
