import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:helloword/features/word_sets/utils/word_file_parser.dart';

Uint8List _bytes(String content) => Uint8List.fromList(utf8.encode(content));

void main() {
  group('WordFileParser (csv/txt)', () {
    test('하이픈 구분자를 파싱한다', () {
      final result = WordFileParser.parse(
        fileName: 'words.txt',
        bytes: _bytes('apple-사과\nbook-책'),
      );
      expect(result.pairs.length, 2);
      expect(result.pairs[0].english, 'apple');
      expect(result.pairs[0].korean, '사과');
      expect(result.pairs[1].english, 'book');
      expect(result.pairs[1].korean, '책');
    });

    test('쉼표 구분자를 파싱한다', () {
      final result = WordFileParser.parse(
        fileName: 'words.csv',
        bytes: _bytes('apple,사과\nbanana,바나나'),
      );
      expect(result.pairs.length, 2);
      expect(result.pairs[1].english, 'banana');
      expect(result.pairs[1].korean, '바나나');
    });

    test('탭 구분자를 파싱한다', () {
      final result = WordFileParser.parse(
        fileName: 'words.txt',
        bytes: _bytes('apple\t사과'),
      );
      expect(result.pairs.single.korean, '사과');
    });

    test('쉼표가 하이픈보다 우선한다 (well-being,행복)', () {
      final result = WordFileParser.parse(
        fileName: 'words.csv',
        bytes: _bytes('well-being,행복'),
      );
      expect(result.pairs.single.english, 'well-being');
      expect(result.pairs.single.korean, '행복');
    });

    test('빈 줄은 무시하고 형식 안 맞는 줄은 건너뛴다', () {
      final result = WordFileParser.parse(
        fileName: 'words.txt',
        bytes: _bytes('apple-사과\n\n형식없는줄\nbook-책\n'),
      );
      expect(result.pairs.length, 2);
      expect(result.skippedLines, 1);
    });

    test('앞뒤 공백을 제거한다', () {
      final result = WordFileParser.parse(
        fileName: 'words.csv',
        bytes: _bytes('  apple  ,  사과  '),
      );
      expect(result.pairs.single.english, 'apple');
      expect(result.pairs.single.korean, '사과');
    });

    test('지원하지 않는 확장자는 예외를 던진다', () {
      expect(
        () => WordFileParser.parse(
          fileName: 'words.pdf',
          bytes: _bytes('apple-사과'),
        ),
        throwsA(isA<WordFileParseException>()),
      );
    });
  });
}
