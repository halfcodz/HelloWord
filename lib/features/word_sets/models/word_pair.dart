/// 영단어 한 쌍 (영어 - 해석). 발음·예문은 선택 정보.
class WordPair {
  const WordPair({
    required this.english,
    required this.korean,
    this.pronunciation = '',
    this.example = '',
    this.askMeaning = false,
  });

  final String english;
  final String korean;

  /// 발음 표기(예: "디스커버"). 없으면 빈 문자열.
  final String pronunciation;

  /// 예문. 없으면 빈 문자열.
  final String example;

  /// 시험에서 '뜻 적기'로 낼지 여부.
  /// true면 영어를 보여주고 뜻(한글)을 적게 하고,
  /// false면 뜻을 보여주고 영어를 적게 한다.
  final bool askMeaning;

  bool get hasExtra => pronunciation.isNotEmpty || example.isNotEmpty;

  /// 시험에서 보여줄 문제(뜻 적기면 영어, 아니면 뜻).
  String get quizPrompt => askMeaning ? english : korean;

  /// 시험 정답(뜻 적기면 뜻, 아니면 영어).
  String get quizAnswer => askMeaning ? korean : english;

  /// 문제에 붙는 안내 문구.
  String get quizHint => askMeaning ? '이 단어의 뜻은?' : '이 뜻의 영어 단어는?';

  /// 입력칸 힌트.
  String get quizInputHint => askMeaning ? '뜻(한글)로 입력' : '영어로 입력';

  WordPair copyWith({bool? askMeaning}) => WordPair(
        english: english,
        korean: korean,
        pronunciation: pronunciation,
        example: example,
        askMeaning: askMeaning ?? this.askMeaning,
      );

  Map<String, dynamic> toMap() => {
        'en': english,
        'ko': korean,
        if (pronunciation.isNotEmpty) 'pron': pronunciation,
        if (example.isNotEmpty) 'ex': example,
        if (askMeaning) 'askMeaning': true,
      };

  factory WordPair.fromMap(Map<String, dynamic> map) => WordPair(
        english: (map['en'] as String? ?? '').trim(),
        korean: (map['ko'] as String? ?? '').trim(),
        pronunciation: (map['pron'] as String? ?? '').trim(),
        example: (map['ex'] as String? ?? '').trim(),
        askMeaning: map['askMeaning'] as bool? ?? false,
      );
}
