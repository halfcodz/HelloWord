# HelloWord 작업 규칙

자매가 함께 쓰는 영어 단어 시험 앱(Flutter). 언니가 단어 세트로 시험을 내고,
동생이 영상통화로 연결된 상태에서 응시하면 언니가 실시간으로 지켜보는 구조.

## 커밋 · 브랜치

- **커밋 메시지는 모두 한글**로 쓴다.
- **`Co-Authored-By` 등 공동작업자 라인은 절대 넣지 않는다.**
- 메시지 형식: 제목 한 줄 → 빈 줄 → 무엇이 문제였는지 → 바뀐 내용을 `-` 목록으로.
- **GitHub Flow**: main에서 직접 작업하지 않는다. 기능 단위로 main에서 브랜치를
  분기(너무 세분화하지 말 것) → 커밋 → 푸시 → 작업이 끝나면 main에 머지.
  최종 배포 코드는 main이며, 다음 작업은 다시 main에서 분기한다.
  예: `feature/phase1-word-sets`, `fix/friend-invite-error`.
- 커밋 전 민감 파일·빌드 산출물이 스테이징되지 않았는지 확인한다.

## 아키텍처

- **MVVM + Provider**. `lib/features/<name>/{models,repositories,viewmodels,views}` 구조로
  View(화면)와 ViewModel(상태)을 분리하고 Provider로 연결한다.
- 데이터 접근은 Repository에 모은다(Firebase Firestore).
- 공용 요소는 `lib/core/{theme,widgets,services,utils}`.

## UI

- **flutter_screenutil 전면 적용** (designSize 402x874, `lib/app.dart`).
  크기는 반드시 `.w / .h / .sp / .r` 로 쓴다.
- 색·그림자는 `AppColors`(`lib/core/theme/app_theme.dart`)를 쓰고 새 색을 직접 박지 않는다.
- 화면 문구는 자매가 쓰는 앱답게 한글 구어체로 짧게.

## 보안

- public 저장소다. 민감 정보는 `.env`(gitignore) + flutter_dotenv로 관리하고
  `.env.example`만 커밋한다.
- Firebase 네이티브 설정 파일(`google-services.json`, `GoogleService-Info.plist`,
  `firebase_options.dart`)은 gitignore 처리돼 있다.

## 확인 · 배포

- 코드를 고친 뒤에는 `flutter analyze`(경고 0)와 `flutter test`를 돌린다.
- 웹 배포: `flutter build web && firebase deploy --only hosting`
  → https://helloword-6da23.web.app
