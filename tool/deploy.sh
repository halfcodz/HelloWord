#!/usr/bin/env bash
# 특정 버전을 웹에 배포한다. 되돌릴 때도 같은 스크립트를 쓴다.
#
#   ./tool/deploy.sh            현재 체크아웃된 코드를 배포
#   ./tool/deploy.sh v1.0.0     예전 버전으로 되돌리기
#   ./tool/deploy.sh v2.0.0     새 버전으로 다시 올리기
#
# 태그를 지정하면 그 태그를 잠시 꺼내 빌드·배포한 뒤, 원래 있던
# 브랜치로 돌아온다. 작업 중인 내용은 건드리지 않는다.
set -euo pipefail

TARGET="${1:-}"
ORIGINAL="$(git rev-parse --abbrev-ref HEAD)"

if [ -n "$(git status --porcelain)" ]; then
  echo "커밋하지 않은 변경이 있습니다. 먼저 정리해 주세요."
  git status --short
  exit 1
fi

restore() {
  if [ -n "$TARGET" ]; then
    echo "→ 원래 위치($ORIGINAL)로 돌아갑니다."
    git checkout -q "$ORIGINAL"
  fi
}
trap restore EXIT

if [ -n "$TARGET" ]; then
  echo "→ $TARGET 으로 전환합니다."
  git checkout -q "$TARGET"
fi

echo "→ 의존성 확인"
flutter pub get >/dev/null

# 영상통화 중계 서버(TURN) 값을 .env에서 읽어 빌드에 심는다.
#
# .env 파일 자체는 배포하지 않는다(firebase.json이 숨김파일을 올리지 않는다).
# 통째로 올리면 나중에 .env에 다른 비밀값을 넣었을 때 그것까지 사이트에
# 공개되기 때문이다. 그래서 중계 서버 값만 골라서 심는다.
#
# 참고: 브라우저에서 도는 영상통화라 이 값은 어차피 접속자가 볼 수 있다.
# 무료 계정으로만 쓰고, 이상하면 대시보드에서 새로 발급받아 .env만 고치면 된다.
DEFINES=()
if [ -f .env ]; then
  for KEY in TURN_URL TURN_USERNAME TURN_CREDENTIAL \
             TURN_URL_2 TURN_USERNAME_2 TURN_CREDENTIAL_2; do
    VALUE="$(grep -E "^${KEY}=" .env | head -1 | cut -d= -f2- | tr -d '\r')"
    if [ -n "$VALUE" ]; then
      DEFINES+=(--dart-define="${KEY}=${VALUE}")
    fi
  done
fi

if [ ${#DEFINES[@]} -eq 0 ]; then
  echo "  ⚠ .env에 중계 서버(TURN) 값이 없습니다."
  echo "    서로 다른 망(한 명은 와이파이, 한 명은 LTE)에서는 영상통화가"
  echo "    연결되지 않습니다. 설정 방법은 .env.example을 보세요."
else
  echo "  중계 서버 설정 ${#DEFINES[@]}개를 빌드에 심습니다."
fi

echo "→ 웹 빌드"
# --no-tree-shake-icons: 아이콘 글리프가 빌드에서 빠져
# 화면에 빈 네모로 보이는 것을 막는다.
#
# --no-web-resources-cdn: 그리기 엔진(CanvasKit)을 구글 CDN에서 받아오지 않고
# 우리 서버에 같이 올린다. 홈 화면에 추가해 쓰면 서비스워커가 함께 캐시해
# 두 번째부터는 네트워크 없이 바로 뜬다.
# ${DEFINES[@]+...}: 값이 하나도 없을 때 set -u가 오류를 내지 않게 한다
# (맥에 기본으로 깔린 bash 3.2에서 빈 배열을 그냥 펼치면 죽는다).
flutter build web --release --no-tree-shake-icons --no-web-resources-cdn \
  ${DEFINES[@]+"${DEFINES[@]}"}

echo "→ 배포"
firebase deploy --only hosting

echo ""
echo "완료: https://helloword-6da23.web.app"
echo "지금 올린 버전: ${TARGET:-$ORIGINAL}"
echo ""
echo "되돌리려면:  ./tool/deploy.sh v1.0.0"
