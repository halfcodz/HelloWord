import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../word_sets/models/word_set.dart';
import '../../word_sets/repositories/word_set_repository.dart';

/// 동생이 공부할 수 있도록, 나에게 공유된(언니가 보낸) 단어 세트를 구독한다.
class StudyViewModel extends ChangeNotifier {
  StudyViewModel({
    required WordSetRepository wordSetRepository,
    required String myUid,
  }) {
    _sub = wordSetRepository.watchSharedWith(myUid).listen((sets) {
      _sets = sets;
      _loading = false;
      notifyListeners();
    });
  }

  StreamSubscription? _sub;

  List<WordSet> _sets = const [];
  List<WordSet> get sets => _sets;

  bool _loading = true;
  bool get loading => _loading;

  bool get isEmpty => !_loading && _sets.isEmpty;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
