import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../social/repositories/friend_repository.dart';
import '../../word_sets/models/word_set.dart';
import '../../word_sets/repositories/word_set_repository.dart';

/// 동생이 혼자 공부할 수 있도록, 친구(언니)가 올린 단어 세트를 모아 구독한다.
class StudyViewModel extends ChangeNotifier {
  StudyViewModel({
    required FriendRepository friendRepository,
    required WordSetRepository wordSetRepository,
    required String myUid,
  }) : _wordSetRepository = wordSetRepository {
    _friendSub =
        friendRepository.watchFriends(myUid).listen((friends) {
      _resubscribe(friends.map((f) => f.uid).toList());
    });
  }

  final WordSetRepository _wordSetRepository;

  StreamSubscription? _friendSub;
  StreamSubscription? _setsSub;

  List<WordSet> _sets = const [];
  List<WordSet> get sets => _sets;

  bool _loading = true;
  bool get loading => _loading;

  bool get isEmpty => !_loading && _sets.isEmpty;

  void _resubscribe(List<String> creatorUids) {
    _setsSub?.cancel();
    if (creatorUids.isEmpty) {
      _sets = const [];
      _loading = false;
      notifyListeners();
      return;
    }
    _setsSub =
        _wordSetRepository.watchByCreators(creatorUids).listen((sets) {
      _sets = sets;
      _loading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _friendSub?.cancel();
    _setsSub?.cancel();
    super.dispose();
  }
}
