import 'package:flutter/material.dart';

/// 짧게 떴다 사라지는 알림(토스트). 하단바를 오래 가리지 않도록
/// 기존 스낵바를 지우고 1.4초만 띄운다.
void showToast(BuildContext context, String message, {bool isError = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message, textAlign: TextAlign.center),
      duration: const Duration(milliseconds: 1400),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      backgroundColor: isError ? const Color(0xFFD64562) : null,
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 24),
    ),
  );
}
