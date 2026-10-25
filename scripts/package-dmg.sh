#!/bin/bash
# 把 unsigned .app 打包成带背景/图标布局的 DMG。
# 优先使用 create-dmg（需要 `brew install create-dmg`）；没有或失败时退回 hdiutil。
#
# 用法：bash scripts/package-dmg.sh <PlayerX.app> <output.dmg>
set -euo pipefail

APP_PATH="${1:?usage: package-dmg.sh <app> <output.dmg>}"
OUTPUT="${2:?usage: package-dmg.sh <app> <output.dmg>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="$(basename "$APP_PATH" .app)"
BACKGROUND="$ROOT/Design/dmg-background.png"

test -d "$APP_PATH" || { echo "App not found: $APP_PATH" >&2; exit 1; }
# 资源拷贝漏掉时，至少让 DMG 仍然有品牌图标。
if [[ ! -f "$APP_PATH/Contents/Resources/AppIcon.icns" && -f "$ROOT/PlayerX/Resources/AppIcon.icns" ]]; then
  cp "$ROOT/PlayerX/Resources/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"
fi
rm -f "$OUTPUT"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP_PATH" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

if command -v create-dmg >/dev/null 2>&1; then
  echo "==> create-dmg: $OUTPUT"
  set +e
  create-dmg \
    --volname "$APP_NAME" \
    --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" \
    --background "$BACKGROUND" \
    --window-pos 200 120 \
    --window-size 660 420 \
    --icon-size 120 \
    --icon "$APP_NAME.app" 180 210 \
    --hide-extension "$APP_NAME.app" \
    --app-drop-link 480 210 \
    "$OUTPUT" "$STAGE"
  status=$?
  set -e
  if [[ $status -eq 0 && -f "$OUTPUT" ]]; then
    echo "✓ create-dmg: $OUTPUT"
    exit 0
  fi
  echo "create-dmg failed (status=$status); falling back to hdiutil" >&2
  rm -f "$OUTPUT"
fi

echo "==> hdiutil fallback: $OUTPUT"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE" \
  -ov -format UDZO \
  "$OUTPUT"
echo "✓ hdiutil: $OUTPUT"
