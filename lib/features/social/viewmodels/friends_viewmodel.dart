import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/app_user.dart';
import '../repositories/friend_repository.dart';

/// 상단 프로필 바/채팅 목록에 쓰이는 친구 목록 및 초대 보내기.
class FriendsViewModel extends ChangeNotifier {
  FriendsViewModel({
    required FriendRepository repository,
    required this.me,
  }) : _repository = repository {
    _sub = _repository.watchFriends(me.uid).listen((friends) {
      _friends = friends;
      notifyListeners();
    });
  }

  final FriendRepository _repository;
  final AppUser me;

  StreamSubscription<List<AppUser>>? _sub;

  List<AppUser> _friends = const [];
  List<AppUser> get friends => _friends;

  Future<FriendAddResult> invite(String email) => _repository.sendInvite(
        myUid: me.uid,
        myName: me.name,
        email: email,
      );

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
