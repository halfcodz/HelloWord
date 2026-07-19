import 'package:flutter_test/flutter_test.dart';
import 'package:helloword/features/word_sets/utils/word_file_parser.dart';

const markdownInput = r'''
방금 준 단어들과 **겹치지 않는 다른 중학생 필수 단어 15개**입니다.

| 단어        | 뜻            | 발음     | 예문                                                    |
| --------- | ------------ | ------ | ----------------------------------------------------- |
| discover  | 발견하다         | 디스커버   | I discovered a small park. 나는 작은 공원을 발견했다.            |
| imagine   | 상상하다         | 이매진    | Imagine your future. 너의 미래를 상상해 봐.                    |
| be proud of | ~을 자랑스러워하다 | 비 프라우드 어브 | I am proud of my team. 나는 우리 팀이 자랑스럽다.                    |

위에는 단어고 아래는 숙어야.
| 숙어          | 뜻          | 발음        | 예문                                                        |
| ----------- | ---------- | --------- | --------------------------------------------------------- |
| give up     | 포기하다       | 기브 업      | Do not give up your dream. 꿈을 포기하지 마라.                     |
| in front of | ~앞에        | 인 프런트 어브  | The bus stop is in front of the school. 버스 정류장은 학교 앞에 있다. |
''';

// ChatGPT 렌더링 표를 복사하면 흔히 탭으로 칸이 구분된다.
const tabInput = 'discover\t발견하다\t디스커버\tI discovered a small park.\n'
    'imagine\t상상하다\t이매진\tImagine your future.';

void main() {
  test('마크다운 4칸 표: 단어/뜻 + 발음/예문 분리, 헤더행 제외', () {
    final r = WordFileParser.parseText(markdownInput);
    final byEn = {for (final p in r.pairs) p.english: p};
    expect(byEn['discover']!.korean, '발견하다');
    expect(byEn['imagine']!.korean, '상상하다');
    expect(byEn['be proud of']!.korean, '~을 자랑스러워하다');
    expect(byEn['give up']!.korean, '포기하다');
    expect(byEn['in front of']!.korean, '~앞에');
    // 헤더행(단어/숙어)은 단어로 잡히면 안 된다.
    expect(byEn.containsKey('단어'), isFalse);
    expect(byEn.containsKey('숙어'), isFalse);
    // 뜻에 발음/예문이 섞이면 안 된다.
    expect(byEn['discover']!.korean.contains('디스커버'), isFalse);
    // 발음·예문은 각각의 칸으로 잡혀야 한다.
    expect(byEn['discover']!.pronunciation, '디스커버');
    expect(byEn['discover']!.example.contains('discovered'), isTrue);
    expect(r.pairs.length, 5);
  });

  test('탭 구분 표: 앞 2칸만 사용', () {
    final r = WordFileParser.parseText(tabInput);
    final map = {for (final p in r.pairs) p.english: p.korean};
    expect(map['discover'], '발견하다');
    expect(map['imagine'], '상상하다');
    expect(map['discover']!.contains('디스커버'), isFalse);
  });
}
