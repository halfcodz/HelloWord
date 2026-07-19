import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/word_pair.dart';

/// 파일 파싱 결과.
class ParsedWords {
  const ParsedWords({required this.pairs, required this.skippedLines});

  final List<WordPair> pairs;

  /// 형식이 맞지 않아 건너뛴 줄 수.
  final int skippedLines;
}

class WordFileParseException implements Exception {
  WordFileParseException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// `영단어-해석` 형식의 파일(csv/txt/xlsx)을 [WordPair] 목록으로 변환한다.
///
/// - csv/txt: 각 줄을 탭 → 쉼표 → 하이픈 순서로 구분자를 자동 감지해 분리.
/// - xlsx/xls: 첫 시트의 A열=영단어, B열=해석.
class WordFileParser {
  static ParsedWords parse({
    required String fileName,
    required Uint8List bytes,
  }) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    switch (ext) {
      case 'xlsx':
      case 'xls':
        return _parseExcel(bytes);
      case 'csv':
      case 'txt':
      case '':
        return _parseDelimited(bytes);
      default:
        throw WordFileParseException(
          '지원하지 않는 파일 형식입니다: .$ext (csv, txt, xlsx만 가능)',
        );
    }
  }

  static ParsedWords _parseDelimited(Uint8List bytes) {
    // BOM 제거 후 UTF-8 디코딩 (깨진 문자는 대체).
    final content = utf8.decode(bytes, allowMalformed: true).replaceFirst(
          '﻿',
          '',
        );
    return parseText(content);
  }

  /// GPT/스프레드시트 등에서 복사한 텍스트(표)를 [WordPair] 목록으로 변환한다.
  ///
  /// 지원 형식:
  /// - 마크다운 표: `| apple | 사과 |` (구분선 `|---|`·헤더 자동 제외)
  /// - 탭/쉼표/하이픈으로 구분된 각 줄: `apple\t사과`, `apple, 사과`, `apple - 사과`
  static ParsedWords parseText(String content) {
    final pairs = <WordPair>[];
    var skipped = 0;

    for (final rawLine in content.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (_isMarkdownSeparator(line)) continue; // |---|---| 구분선

      // 여러 칸으로 나눈 뒤 '앞의 두 칸'(단어·뜻)만 사용한다.
      // 발음·예문 등 3번째 이후 칸은 버려 타일이 길어지지 않게 한다.
      final cells = _columns(line);
      if (cells.length < 2) {
        // 구분자가 없는 안내 문구/제목 줄은 조용히 건너뛴다.
        if (cells.isNotEmpty) skipped++;
        continue;
      }
      final en = cells[0];
      final ko = cells[1];
      if (en.isEmpty || ko.isEmpty) {
        skipped++;
        continue;
      }
      if (_looksLikeHeader(en, ko)) continue; // 단어/뜻/숙어 같은 헤더행
      pairs.add(WordPair(english: en, korean: ko));
    }
    return ParsedWords(pairs: pairs, skippedLines: skipped);
  }

  /// 한 줄을 칸(cell) 목록으로 나눈다. 우선순위: 파이프 → 탭 → 2칸 이상 공백 →
  /// 쉼표 → 하이픈. 앞뒤 공백을 제거하고 빈 칸은 버린다.
  static List<String> _columns(String line) {
    List<String> raw;
    if (line.contains('|')) {
      raw = line.split('|');
    } else if (line.contains('\t')) {
      raw = line.split('\t');
    } else if (RegExp(r'\s{2,}').hasMatch(line)) {
      raw = line.split(RegExp(r'\s{2,}'));
    } else if (line.contains(',')) {
      raw = line.split(',');
    } else if (line.contains('-')) {
      raw = line.split(RegExp(r'\s*-\s*'));
    } else {
      raw = [line];
    }
    return raw.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
  }

  /// `|---|:--:|` 같은 마크다운 표 구분선인지.
  static bool _isMarkdownSeparator(String line) {
    final stripped = line.replaceAll(RegExp(r'[\s|:\-]'), '');
    return stripped.isEmpty && line.contains('-');
  }

  /// `단어 | 뜻`, `숙어 | 뜻` 같은 헤더행으로 보이면 제외한다.
  static bool _looksLikeHeader(String en, String ko) {
    const enHeaders = {
      '영어', '영단어', '단어', '숙어', '표현', '어휘', 'english', 'word',
      'eng', '스펠링', 'idiom', 'phrase', 'expression'
    };
    const koHeaders = {'뜻', '의미', '해석', '한글', '뜻(한글)', 'korean', 'meaning'};
    return enHeaders.contains(en.toLowerCase()) ||
        koHeaders.contains(ko.toLowerCase());
  }

  static ParsedWords _parseExcel(Uint8List bytes) {
    final Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (_) {
      throw WordFileParseException('엑셀 파일을 읽을 수 없습니다. 파일이 손상되지 않았는지 확인해 주세요.');
    }

    final pairs = <WordPair>[];
    var skipped = 0;

    final firstSheet = excel.tables.values.isEmpty
        ? null
        : excel.tables.values.first;
    if (firstSheet == null) {
      throw WordFileParseException('엑셀에 시트가 없습니다.');
    }

    for (final row in firstSheet.rows) {
      final en = _cellText(row.isNotEmpty ? row[0]?.value : null);
      final ko = _cellText(row.length > 1 ? row[1]?.value : null);
      if (en.isEmpty && ko.isEmpty) continue; // 빈 줄
      if (en.isEmpty || ko.isEmpty) {
        skipped++;
        continue;
      }
      pairs.add(WordPair(english: en, korean: ko));
    }
    return ParsedWords(pairs: pairs, skippedLines: skipped);
  }

  static String _cellText(CellValue? value) {
    switch (value) {
      case null:
        return '';
      case TextCellValue():
        // excel의 TextSpan.toString()이 text + children을 이어붙여 준다.
        return value.value.toString().trim();
      case IntCellValue():
        return value.value.toString();
      case DoubleCellValue():
        final d = value.value;
        return d == d.roundToDouble()
            ? d.toInt().toString()
            : d.toString();
      case FormulaCellValue():
        return value.formula.trim();
      case BoolCellValue():
        return value.value.toString();
      default:
        return value.toString().trim();
    }
  }
}
