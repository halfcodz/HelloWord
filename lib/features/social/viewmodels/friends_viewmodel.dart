import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/app_user.dart';
import '../repositories/friend_repository.dart';

/// 상단 프로필 바에 쓰이는 친구 목록/상태 관리.
class FriendsViewModel extends ChangeNotifier {
  FriendsViewModel({
    required FriendRepository repository,
    required this.myUid,
  }) : _repository = repository {
    _sub = _repository.watchFriends(myUid).listen((friends) {
      _friends = friends;
      notifyListeners();
    });
  }

  final FriendRepository _repository;
  final String myUid;

  StreamSubscription<List<AppUser>>? _sub;

  List<AppUser> _friends = const [];
  List<AppUser> get friends => _friends;

  Future<FriendAddResult> addFriend(String email) =>
      _repository.addByEmail(myUid: myUid, email: email);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
