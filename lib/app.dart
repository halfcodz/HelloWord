import 'package:flutter/material.dart';

import 'auth/auth_gate.dart';

class HelloWordApp extends StatelessWidget {
  const HelloWordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelloWord',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6C63FF),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
