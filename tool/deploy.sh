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

echo "→ 웹 빌드"
# --no-tree-shake-icons: 아이콘 글리프가 빌드에서 빠져
# 화면에 빈 네모로 보이는 것을 막는다.
flutter build web --release --no-tree-shake-icons

echo "→ 배포"
firebase deploy --only hosting

echo ""
echo "완료: https://helloword-6da23.web.app"
echo "지금 올린 버전: ${TARGET:-$ORIGINAL}"
echo ""
echo "되돌리려면:  ./tool/deploy.sh v1.0.0"
