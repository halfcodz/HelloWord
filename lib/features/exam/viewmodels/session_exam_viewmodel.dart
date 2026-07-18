import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../word_sets/models/word_pair.dart';
import '../models/exam_session.dart';
import '../repositories/exam_repository.dart';

/// 동생(응시자)의 시험 응시 화면 상태.
/// 입력은 디바운스로 실시간 전송하고, 제출 시 채점 후 다음 문제로 넘어간다.
class SessionExamViewModel extends ChangeNotifier {
  SessionExamViewModel({
    required ExamRepository repository,
    required String sessionId,
  })  : _repository = repository,
        _sessionId = sessionId {
    _sessionSub = _repository.watchSession(_sessionId).listen((session) {
      _session = session;
      _loaded = true;
      // 언니가 세션을 닫으면 session이 null이 된다.
      notifyListeners();
    });
  }

  /// 첫 스냅샷 수신 여부. 로딩과 "종료됨(null)"을 구분한다.
  bool _loaded = false;
  bool get loaded => _loaded;

  final ExamRepository _repository;
  final String _sessionId;

  StreamSubscription<ExamSession?>? _sessionSub;
  Timer? _debounce;

  ExamSession? _session;
  ExamSession? get session => _session;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  int _correctCount = 0;
  int get correctCount => _correctCount;

  bool get isFinished => _session?.status == SessionStatus.finished;

  WordPair? get currentWord {
    final session = _session;
    if (session == null || _currentIndex >= session.words.length) return null;
    return session.words[_currentIndex];
  }

  /// 입력 중인 텍스트를 300ms 디바운스로 서버에 전송한다.
  void onTyped(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _repository.updateTyping(
        sessionId: _sessionId,
        index: _currentIndex,
        typed: text,
      );
    });
  }

  /// 답을 제출하고 다음 문제로 넘어간다(마지막이면 종료).
  Future<void> submit(String answer) async {
    final word = currentWord;
    final session = _session;
    if (word == null || session == null) return;

    _debounce?.cancel();
    final correct =
        answer.trim().toLowerCase() == word.english.trim().toLowerCase();
    if (correct) _correctCount++;

    await _repository.submitAnswer(
      sessionId: _sessionId,
      index: _currentIndex,
      submitted: answer.trim(),
      correct: correct,
    );

    final next = _currentIndex + 1;
    if (next >= session.total) {
      await _repository.finish(sessionId: _sessionId, score: _correctCount);
    } else {
      _currentIndex = next;
      await _repository.setCurrentIndex(sessionId: _sessionId, index: next);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sessionSub?.cancel();
    super.dispose();
  }
}
