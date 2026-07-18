import 'package:flutter/foundation.dart';

import '../../../models/app_user.dart';
import '../repositories/exam_repository.dart';

/// 동생이 코드로 시험에 참여하는 화면의 상태.
class SessionJoinViewModel extends ChangeNotifier {
  SessionJoinViewModel({
    required ExamRepository repository,
    required AppUser user,
  })  : _repository = repository,
        _user = user;

  final ExamRepository _repository;
  final AppUser _user;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  /// 참여 성공 시 세션 id를 반환하고, 실패 시 null.
  Future<String?> join(String code) async {
    final trimmed = code.trim();
    if (trimmed.length != 6) {
      _error = '6자리 코드를 입력해 주세요.';
      notifyListeners();
      return null;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final session = await _repository.findByJoinCode(trimmed);
      if (session == null) {
        _error = '해당 코드의 대기 중인 시험을 찾지 못했어요.';
        return null;
      }
      await _repository.joinSession(
        sessionId: session.id,
        guestUid: _user.uid,
        guestName: _user.name,
      );
      return session.id;
    } catch (_) {
      _error = '참여 중 오류가 발생했어요. 잠시 후 다시 시도해 주세요.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
