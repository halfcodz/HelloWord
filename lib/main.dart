import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/theme/theme_controller.dart';
import 'features/study/services/memorized_store.dart';
import 'features/word_sets/services/seen_materials_store.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 민감 정보용 .env 로드. 파일이 없어도 앱은 정상 동작한다.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env가 없으면 무시 (민감 값이 필요한 기능에서만 사용).
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 외운 단어 기록을 미리 불러온다(공부 진행).
  await MemorizedStore.load();

  // 새 자료 알림 확인 시각을 불러온다(동생 알림 배지).
  await SeenMaterialsStore.load();

  // 저장된 테마 팔레트를 적용한 컨트롤러를 준비한다.
  final themeController = await ThemeController.load();

  runApp(HelloWordApp(themeController: themeController));
}
