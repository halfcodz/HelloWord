# HelloWord — Firebase 연결 가이드 (Phase 0)

이 앱은 Firebase(Auth · Firestore)를 사용합니다. 아래 절차를 **한 번만** 진행하면
`lib/firebase_options.dart`가 자동 생성되고 앱이 실행됩니다. 모두 **무료(Spark 플랜)** 범위입니다.

---

## 1. Firebase 프로젝트 생성 (웹 콘솔)

1. https://console.firebase.google.com 접속 → 본인 구글 계정 로그인
2. **프로젝트 추가** → 이름 예: `helloword` → 생성 (Google Analytics는 꺼도 됩니다)

### 1-1. 로그인 방식 켜기
- 좌측 **빌드 > Authentication > 시작하기**
- **Sign-in method** 탭 → **이메일/비밀번호** 사용 설정 → 저장

### 1-2. Firestore 데이터베이스 만들기
- 좌측 **빌드 > Firestore Database > 데이터베이스 만들기**
- 위치: `asia-northeast3 (서울)` 권장
- 우선 **테스트 모드**로 시작(30일 뒤 만료) → 아래 3번에서 보안 규칙으로 교체

---

## 2. CLI 도구 설치 & 프로젝트 연결

터미널에서 (프로젝트 루트 `HelloWord/`에서 실행):

```bash
# 2-1. Firebase CLI 설치 (node가 이미 있음)
npm install -g firebase-tools

# 2-2. 구글 계정으로 로그인 (브라우저 열림)
firebase login

# 2-3. FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# PATH에 pub-cache/bin이 없다면 한 줄 추가 후 터미널 재시작
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc

# 2-4. Firebase 연결 (android, ios 설정 자동 생성)
flutterfire configure --platforms=android,ios
```

`flutterfire configure` 실행 중:
- 위에서 만든 프로젝트 선택
- Android 패키지명은 `com.helloword.helloword` (자동 감지됨)

완료되면 다음 파일들이 생성됩니다:
- `lib/firebase_options.dart` ← 이게 있어야 앱이 컴파일됩니다
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

---

## 3. Firestore 보안 규칙 (테스트 모드 대체)

Firebase 콘솔 **Firestore > 규칙** 탭에 붙여넣고 게시:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 본인 프로필만 읽고 쓸 수 있음
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

> Phase 1부터 `wordSets`, `sessions` 규칙을 여기에 추가합니다.

---

## 4. 실행

```bash
flutter run
```

회원가입(이름·이메일·비밀번호·역할) → 자동 로그인 → 홈 화면이 뜨면 Phase 0 완료입니다.

---

## 참고
- `firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`는 사람마다
  값이 달라 이 저장소에 커밋되지 않을 수 있습니다. 각자 위 절차로 생성하세요.
- iOS 실행 시 최소 iOS 13이 필요합니다(FlutterFire가 Podfile을 조정).
- Android 최소 SDK는 23으로 설정되어 있습니다(Firebase Auth 요구사항).
