import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'auth/auth_gate.dart';
import 'features/word_sets/repositories/word_set_repository.dart';

class HelloWordApp extends StatelessWidget {
  const HelloWordApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 앱 전역에서 공유하는 데이터 계층(Repository)을 Provider로 주입한다.
    return MultiProvider(
      providers: [
        Provider<WordSetRepository>(create: (_) => WordSetRepository()),
      ],
      // iPhone 13/14(390 x 844) 기준으로 반응형 크기를 계산한다.
      child: ScreenUtilInit(
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
      ),
    );
  }
}
