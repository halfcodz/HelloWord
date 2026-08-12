#!/usr/bin/env bash
# assets/fonts/ 안의 폰트 파일을 다시 만든다.
#
# 왜 직접 만드나?
#   구글 폰트 원본은 통째로 쓰기엔 너무 크다(한글 Noto Sans KR는 9.9MB).
#   앱에서 실제로 쓰는 굵기와 글자만 남기면 훨씬 작아진다.
#
# 언제 돌리나?
#   평소에는 돌릴 일이 없다. 만든 결과(.ttf)를 저장소에 넣어 두었기 때문이다.
#   폰트를 바꾸거나 굵기를 더 쓰고 싶을 때만 이 스크립트를 고쳐서 돌린다.
#
# 준비물:  pip install fonttools
#
#   ./tool/build_fonts.sh
set -euo pipefail

cd "$(dirname "$0")/.."
OUT="assets/fonts"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if ! command -v pyftsubset >/dev/null; then
  echo "pyftsubset이 없습니다.  pip install fonttools  후 다시 실행해 주세요."
  exit 1
fi

BASE="https://github.com/google/fonts/raw/main/ofl"
# 라틴 문자에 필요한 범위(영문·숫자·문장부호·화살표 등).
LATIN="U+0020-007E,U+00A0-00FF,U+0100-017F,U+2000-206F,U+20A0-20BF,U+2190-21BB"
# 한글에 필요한 범위. 현대 한글 음절 11,172자를 모두 넣는다.
# 자주 쓰는 글자만 골라 넣으면 파일은 작아지지만, 동생이 적은 뜻에 드문 글자가
# 하나라도 있으면 그 자리가 네모로 보인다. 그것 때문에 고친 것이라 다 넣는다.
KO="U+0020-007E,U+00A0-00FF,U+2000-206F,U+20A0-20BF,U+3000-303F,U+1100-11FF,U+3130-318F,U+A960-A97F,U+AC00-D7A3,U+D7B0-D7FF,U+FF01-FF60"

mkdir -p "$OUT"

echo "→ 원본 내려받기"
curl -sL -o "$WORK/nunito.ttf"  "$BASE/nunito/Nunito%5Bwght%5D.ttf"
curl -sL -o "$WORK/fredoka.ttf" "$BASE/fredoka/Fredoka%5Bwdth,wght%5D.ttf"
curl -sL -o "$WORK/noto.ttf"    "$BASE/notosanskr/NotoSansKR%5Bwght%5D.ttf"
curl -sL -o "$OUT/OFL-Nunito.txt"     "$BASE/nunito/OFL.txt"
curl -sL -o "$OUT/OFL-Fredoka.txt"    "$BASE/fredoka/OFL.txt"
curl -sL -o "$OUT/OFL-NotoSansKR.txt" "$BASE/notosanskr/OFL.txt"

# 굵기 하나를 뽑아내고(instancer) 필요한 글자만 남긴다(subset).
cut_font() {
  local SRC="$1" NAME="$2" AXES="$3" RANGE="$4"
  python3 -m fontTools.varLib.instancer "$SRC" $AXES -o "$WORK/t.ttf" >/dev/null
  pyftsubset "$WORK/t.ttf" --output-file="$OUT/$NAME" \
    --unicodes="$RANGE" --layout-features='*' --no-hinting >/dev/null
  echo "   $NAME  $(du -h "$OUT/$NAME" | cut -f1)"
}

echo "→ Nunito (본문)"
cut_font "$WORK/nunito.ttf" Nunito-Regular.ttf    "wght=400" "$LATIN"
cut_font "$WORK/nunito.ttf" Nunito-SemiBold.ttf   "wght=600" "$LATIN"
cut_font "$WORK/nunito.ttf" Nunito-Bold.ttf       "wght=700" "$LATIN"
cut_font "$WORK/nunito.ttf" Nunito-ExtraBold.ttf  "wght=800" "$LATIN"

echo "→ Fredoka (제목·영어 단어)"
cut_font "$WORK/fredoka.ttf" Fredoka-Medium.ttf   "wght=500 wdth=100" "$LATIN"
cut_font "$WORK/fredoka.ttf" Fredoka-SemiBold.ttf "wght=600 wdth=100" "$LATIN"
cut_font "$WORK/fredoka.ttf" Fredoka-Bold.ttf     "wght=700 wdth=100" "$LATIN"

# 한글은 한 벌만 넣는다. 굵은 글씨는 그리기 엔진이 알아서 굵게 만들어 준다.
# 굵기마다 넣으면 2.5MB씩 더 늘어난다.
echo "→ Noto Sans KR (한글)"
cut_font "$WORK/noto.ttf" NotoSansKR-Regular.ttf  "wght=400" "$KO"

# 이모지 원본은 10MB나 되므로, lib/ 안에서 실제로 쓰는 이모지만 골라 넣는다.
# lib/를 직접 훑기 때문에 화면에 이모지를 새로 쓴 뒤 이 스크립트를 다시 돌리면
# 자동으로 따라온다.
echo "→ Noto Color Emoji (쓰는 것만)"
python3 - "$WORK/emoji.txt" <<'PY'
import re, sys, pathlib
pat = re.compile('[\U0001F300-\U0001FAFF←-⇿☀-➿⬀-⯿]')
found = set()
for p in pathlib.Path('lib').rglob('*.dart'):
    found.update(pat.findall(p.read_text(encoding='utf-8')))
found = {c for c in found if ord(c) > 0x2100}
pathlib.Path(sys.argv[1]).write_text(''.join(sorted(found)), encoding='utf-8')
print(f'   lib/에서 이모지 {len(found)}종류를 찾았습니다.')
PY
curl -sL -o "$WORK/emoji.ttf" \
  "https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji.ttf"
curl -sL -o "$OUT/LICENSE-NotoColorEmoji.txt" \
  "https://github.com/googlefonts/noto-emoji/raw/main/fonts/LICENSE"
pyftsubset "$WORK/emoji.ttf" --output-file="$OUT/NotoColorEmoji-Subset.ttf" \
  --text-file="$WORK/emoji.txt" --layout-features='*' --no-hinting >/dev/null
echo "   NotoColorEmoji-Subset.ttf  $(du -h "$OUT/NotoColorEmoji-Subset.ttf" | cut -f1)"

echo ""
echo "완료. 전체 크기: $(du -sh "$OUT" | cut -f1)"
echo "pubspec.yaml의 fonts: 목록과 파일 이름이 맞는지 확인해 주세요."
