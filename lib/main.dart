import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/services/bgm_service.dart';
import 'core/services/sfx_service.dart';
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

  // 배경음악 설정(켬/끔)을 불러온다. 실제 재생은 로그인 후 시작한다.
  final bgm = await BgmService.load();

  // 버튼 효과음 설정.
  final sfx = await SfxService.load();

  runApp(
    HelloWordApp(themeController: themeController, bgm: bgm, sfx: sfx),
  );
}
