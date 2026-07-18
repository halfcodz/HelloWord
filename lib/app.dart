import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'auth/auth_gate.dart';

class HelloWordApp extends StatelessWidget {
  const HelloWordApp({super.key});

  @override
  Widget build(BuildContext context) {
    // iPhone 13/14(390 x 844) 기준으로 반응형 크기를 계산한다.
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'HelloWord',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF6C63FF),
            useMaterial3: true,
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}
