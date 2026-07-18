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
    // 사용자 프로필: 로그인한 사용자끼리 서로 조회(친구 상태) 및
    // 친구 추가(상대 문서의 friends 배열 갱신)를 허용한다.
    // ※ 자매 둘만 쓰는 비공개 앱이라 이 정도 개방을 허용. 공개 서비스라면
    //    friends 필드에 한정하는 등 더 촘촘한 규칙이 필요.
    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
      // 하위(todos=개인 투두)도 로그인 사용자에게 허용
      match /{sub=**} {
        allow read, write: if request.auth != null;
      }
    }

    // 단어 세트: 로그인한 사용자는 읽기 가능(동생이 언니 단어로 공부),
    // 생성·수정·삭제는 만든 본인만.
    match /wordSets/{setId} {
      allow read: if request.auth != null;
      allow update, delete: if request.auth != null
        && request.auth.uid == resource.data.createdBy;
      allow create: if request.auth != null
        && request.auth.uid == request.resource.data.createdBy;
    }

    // 실시간 시험 세션: 로그인한 사용자(언니·동생)가 참여/조회
    // 하위(answers=답안, rtc=영상통화 시그널링)도 로그인 사용자에게 허용
    match /sessions/{sessionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.auth.uid == request.resource.data.hostUid;
      allow update, delete: if request.auth != null;

      match /{sub=**} {
        allow read, write: if request.auth != null;
      }
    }

    // 1:1 채팅: 로그인한 사용자끼리
    match /chats/{roomId} {
      allow read, write: if request.auth != null;
      match /messages/{msgId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

> 지금은 Firestore가 테스트 모드라 규칙 없이도 동작하지만, public 저장소이므로
> 위 규칙을 콘솔에 반영해 두는 것을 권장합니다.

---

## 4. 실행

```bash
flutter run                # 모바일(연결된 기기)
flutter run -d chrome      # 웹(크롬)에서 실행
```

회원가입(이름·이메일·비밀번호·역할) → 자동 로그인 → 홈 화면이 뜨면 Phase 0 완료입니다.

---

## 5. 웹 배포 (Firebase Hosting · 무료)

두 사용자 모두 아이폰이라, 웹으로 배포하면 **사파리에서 링크만 열어** 쓸 수 있습니다.

```bash
# 1. 웹 빌드
flutter build web

# 2. Firebase Hosting 배포 (firebase.json/.firebaserc 이미 설정됨)
firebase deploy --only hosting
```

배포가 끝나면 `https://helloword-6da23.web.app` 주소가 출력됩니다. 이 링크를
카톡 등으로 공유하면 두 사람 모두 설치 없이 바로 사용할 수 있습니다.

> Firebase Auth는 `*.web.app`, `*.firebaseapp.com`, `localhost`를 기본 허용 도메인으로
> 두므로 별도 설정 없이 로그인이 됩니다. 커스텀 도메인을 붙이면 콘솔
> Authentication > Settings > 승인된 도메인에 추가하세요.

---

## 참고
- `firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`는 사람마다
  값이 달라 이 저장소에 커밋되지 않을 수 있습니다. 각자 위 절차로 생성하세요.
- iOS 실행 시 최소 iOS 13이 필요합니다(FlutterFire가 Podfile을 조정).
- Android 최소 SDK는 23으로 설정되어 있습니다(Firebase Auth 요구사항).
