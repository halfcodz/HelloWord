import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../word_sets/models/word_pair.dart';
import '../models/exam_answer.dart';
import '../models/exam_session.dart';
import '../repositories/exam_repository.dart';

/// 동생(응시자)의 시험 응시 화면 상태.
/// 이전/다음 문제로 이동하며 답을 고칠 수 있고, '완료' 시 채점된다.
class SessionExamViewModel extends ChangeNotifier {
  SessionExamViewModel({
    required ExamRepository repository,
    required String sessionId,
  })  : _repository = repository,
        _sessionId = sessionId {
    _sessionSub = _repository.watchSession(_sessionId).listen((session) {
      _session = session;
      _loaded = true;
      notifyListeners();
    });
    _answersSub = _repository.watchAnswers(_sessionId).listen((answers) {
      _answers = answers;
      notifyListeners();
    });
  }

  bool _loaded = false;
  bool get loaded => _loaded;

  final ExamRepository _repository;
  final String _sessionId;

  StreamSubscription<ExamSession?>? _sessionSub;
  StreamSubscription<List<ExamAnswer>>? _answersSub;
  Timer? _debounce;

  ExamSession? _session;
  ExamSession? get session => _session;

  List<ExamAnswer> _answers = const [];
  List<ExamAnswer> get answers => _answers;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  bool get isFinished => _session?.status == SessionStatus.finished;

  int get total => _session?.total ?? 0;

  WordPair? get currentWord {
    final session = _session;
    if (session == null || _currentIndex >= session.words.length) return null;
    return session.words[_currentIndex];
  }

  ExamAnswer? answerAt(int index) {
    for (final a in _answers) {
      if (a.index == index) return a;
    }
    return null;
  }

  /// 특정 문제에 이미 제출한 답(없으면 빈 문자열).
  String submittedTextAt(int index) => answerAt(index)?.submitted ?? '';

  int get correctCount => _answers.where((a) => a.correct == true).length;
  int get submittedCount => _answers.where((a) => a.isSubmitted).length;
  bool get allAnswered => total > 0 && submittedCount >= total;

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  /// 입력 중인 텍스트를 300ms 디바운스로 서버에 전송한다(언니 실시간 모니터용).
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

  /// 현재 문제의 답을 저장(채점)한다. 빈 답이면 저장하지 않는다.
  Future<void> saveAnswer(String answer) async {
    final word = currentWord;
    if (word == null) return;
    final trimmed = answer.trim();
    if (trimmed.isEmpty) return;
    _debounce?.cancel();
    final correct = _normalize(trimmed) == _normalize(word.english);
    await _repository.submitAnswer(
      sessionId: _sessionId,
      index: _currentIndex,
      submitted: trimmed,
      correct: correct,
    );
  }

  /// 문제 이동. 서버의 currentIndex도 갱신해 언니 화면에 반영한다.
  void goTo(int index) {
    if (index < 0 || index >= total) return;
    _currentIndex = index;
    _repository.setCurrentIndex(sessionId: _sessionId, index: index);
    notifyListeners();
  }

  /// 시험을 완료한다(채점은 서버에서 답안 기준으로 계산).
  Future<void> finishExam() => _repository.finish(sessionId: _sessionId);

  /// 시험을 종료하고 세션을 삭제한다(중도 포기 시).
  Future<void> endSession() => _repository.deleteSession(_sessionId);

  @override
  void dispose() {
    _debounce?.cancel();
    _sessionSub?.cancel();
    _answersSub?.cancel();
    super.dispose();
  }
}
