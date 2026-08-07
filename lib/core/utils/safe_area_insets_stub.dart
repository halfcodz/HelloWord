import 'package:flutter/widgets.dart';

/// 웹이 아닌 곳에서는 Flutter가 이미 정확한 값을 주므로 더 얹지 않는다.
EdgeInsets readSafeAreaInsets() => EdgeInsets.zero;
