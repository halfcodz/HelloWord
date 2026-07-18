import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/word_set.dart';
import '../repositories/word_set_repository.dart';

/// 언니의 단어 세트 목록 화면 상태를 관리한다.
class WordSetListViewModel extends ChangeNotifier {
  WordSetListViewModel({
    required WordSetRepository repository,
    required String uid,
  })  : _repository = repository,
        _uid = uid {
    _subscribe();
  }

  final WordSetRepository _repository;
  final String _uid;

  StreamSubscription<List<WordSet>>? _subscription;

  List<WordSet> _sets = const [];
  List<WordSet> get sets => _sets;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  bool get isEmpty => !_loading && _error == null && _sets.isEmpty;

  void _subscribe() {
    _subscription = _repository.watchByCreator(_uid).listen(
      (data) {
        _sets = data;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        _loading = false;
        _error = '목록을 불러오지 못했습니다.';
        notifyListeners();
      },
    );
  }

  Future<void> delete(String id) => _repository.delete(id);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
