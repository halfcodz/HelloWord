import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/exam_answer.dart';
import '../models/exam_session.dart';
import '../repositories/exam_repository.dart';

/// 언니(출제자)의 실시간 감독 화면 상태.
/// 세션과 답안을 실시간 구독해 동생의 진행 상황을 보여준다.
class SessionHostViewModel extends ChangeNotifier {
  SessionHostViewModel({
    required ExamRepository repository,
    required String sessionId,
  })  : _repository = repository,
        _sessionId = sessionId {
    _sessionSub = _repository.watchSession(_sessionId).listen((session) {
      _session = session;
      notifyListeners();
    });
    _answersSub = _repository.watchAnswers(_sessionId).listen((answers) {
      _answers = answers;
      notifyListeners();
    });
  }

  final ExamRepository _repository;
  final String _sessionId;

  StreamSubscription<ExamSession?>? _sessionSub;
  StreamSubscription<List<ExamAnswer>>? _answersSub;

  ExamSession? _session;
  ExamSession? get session => _session;

  List<ExamAnswer> _answers = const [];
  List<ExamAnswer> get answers => _answers;

  ExamAnswer? answerAt(int index) {
    for (final a in _answers) {
      if (a.index == index) return a;
    }
    return null;
  }

  int get submittedCount => _answers.where((a) => a.isSubmitted).length;
  int get correctCount => _answers.where((a) => a.correct == true).length;

  /// 세션을 삭제한다(대기 중 취소 또는 종료 후 닫기).
  Future<void> closeSession() => _repository.deleteSession(_sessionId);

  @override
  void dispose() {
    _sessionSub?.cancel();
    _answersSub?.cancel();
    super.dispose();
  }
}
