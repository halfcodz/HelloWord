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
  /// csv/txt에서 구분자로 인식할 후보 (우선순위 순).
  static const _delimiters = ['\t', ',', '-'];

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
    final pairs = <WordPair>[];
    var skipped = 0;

    for (final rawLine in content.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final pair = _splitLine(line);
      if (pair == null) {
        skipped++;
        continue;
      }
      pairs.add(pair);
    }
    return ParsedWords(pairs: pairs, skippedLines: skipped);
  }

  static WordPair? _splitLine(String line) {
    for (final delim in _delimiters) {
      final idx = line.indexOf(delim);
      // 구분자가 줄 맨 앞/뒤가 아니어야 유효.
      if (idx > 0 && idx < line.length - 1) {
        final en = line.substring(0, idx).trim();
        final ko = line.substring(idx + 1).trim();
        if (en.isNotEmpty && ko.isNotEmpty) {
          return WordPair(english: en, korean: ko);
        }
      }
    }
    return null;
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
