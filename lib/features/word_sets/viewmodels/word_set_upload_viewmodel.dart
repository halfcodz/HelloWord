import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../models/app_user.dart';
import '../../social/repositories/friend_repository.dart';
import '../models/word_pair.dart';
import '../repositories/word_set_repository.dart';
import '../utils/word_file_parser.dart';

enum UploadStatus { idle, parsing, ready, saving, saved, error }

/// 단어 파일 업로드 → 파싱 → 메타 입력 → 저장까지의 상태를 관리한다.
class WordSetUploadViewModel extends ChangeNotifier {
  WordSetUploadViewModel({
    required WordSetRepository repository,
    required FriendRepository friendRepository,
    required String uid,
  })  : _repository = repository,
        _uid = uid {
    _friendSub = friendRepository.watchFriends(uid).listen((friends) {
      _friends = friends;
      // 기본값: 모든 친구에게 전송(대개 동생 1명).
      _selectedFriendUids = friends.map((f) => f.uid).toSet();
      notifyListeners();
    });
  }

  final WordSetRepository _repository;
  final String _uid;

  StreamSubscription<List<AppUser>>? _friendSub;

  List<AppUser> _friends = const [];
  List<AppUser> get friends => _friends;

  Set<String> _selectedFriendUids = {};
  Set<String> get selectedFriendUids => _selectedFriendUids;

  void toggleFriend(String uid) {
    _selectedFriendUids = {..._selectedFriendUids};
    if (_selectedFriendUids.contains(uid)) {
      _selectedFriendUids.remove(uid);
    } else {
      _selectedFriendUids.add(uid);
    }
    notifyListeners();
  }

  UploadStatus _status = UploadStatus.idle;
  UploadStatus get status => _status;

  String? _fileName;
  String? get fileName => _fileName;

  List<WordPair> _words = const [];
  List<WordPair> get words => _words;

  int _skippedLines = 0;
  int get skippedLines => _skippedLines;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── 저장 폼 상태 ───────────────────────────────
  String _title = '';
  String get title => _title;

  DateTime _date = DateTime.now();
  DateTime get date => _date;

  String _message = '';
  String get message => _message;

  bool get hasWords => _words.isNotEmpty;

  bool get canSave =>
      hasWords &&
      _title.trim().isNotEmpty &&
      _status != UploadStatus.saving;

  /// 파일 선택 후 파싱한다.
  Future<void> pickAndParse() async {
    _status = UploadStatus.parsing;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        // 사용자가 선택을 취소함.
        _status = hasWords ? UploadStatus.ready : UploadStatus.idle;
        notifyListeners();
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        throw WordFileParseException('파일 내용을 읽을 수 없습니다.');
      }

      final parsed = WordFileParser.parse(fileName: file.name, bytes: bytes);
      if (parsed.pairs.isEmpty) {
        _status = UploadStatus.error;
        _errorMessage = '유효한 단어를 찾지 못했습니다. "영단어-해석" 형식인지 확인해 주세요.';
        notifyListeners();
        return;
      }

      _fileName = file.name;
      _words = parsed.pairs;
      _skippedLines = parsed.skippedLines;

      // 제목이 비어 있으면 파일명(확장자 제외)을 기본값으로 제안한다.
      if (_title.trim().isEmpty) {
        final dot = file.name.lastIndexOf('.');
        _title = dot > 0 ? file.name.substring(0, dot) : file.name;
      }

      _status = UploadStatus.ready;
      notifyListeners();
    } on WordFileParseException catch (e) {
      _status = UploadStatus.error;
      _errorMessage = e.message;
      notifyListeners();
    } catch (_) {
      _status = UploadStatus.error;
      _errorMessage = '파일 처리 중 오류가 발생했습니다.';
      notifyListeners();
    }
  }

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setDate(DateTime value) {
    _date = value;
    notifyListeners();
  }

  void setMessage(String value) {
    _message = value;
    notifyListeners();
  }

  void removeWordAt(int index) {
    if (index < 0 || index >= _words.length) return;
    _words = List.of(_words)..removeAt(index);
    notifyListeners();
  }

  /// 저장 성공 시 true.
  Future<bool> save() async {
    if (!canSave) return false;
    _status = UploadStatus.saving;
    notifyListeners();
    try {
      await _repository.create(
        title: _title.trim(),
        date: _date,
        message: _message.trim(),
        words: _words,
        createdBy: _uid,
        sharedWith: _selectedFriendUids.toList(),
      );
      _status = UploadStatus.saved;
      notifyListeners();
      return true;
    } catch (_) {
      _status = UploadStatus.error;
      _errorMessage = '저장에 실패했습니다. 네트워크 연결을 확인해 주세요.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _friendSub?.cancel();
    super.dispose();
  }
}
