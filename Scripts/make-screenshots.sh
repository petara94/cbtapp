#!/usr/bin/env bash
#
# Прогоняет UI-тест основного флоу (CBTDiaryUITests) на симуляторе и копирует
# полученные скриншоты в ./Screenshots — те самые, что вставлены в README.
#
# Использование:
#   ./Scripts/make-screenshots.sh            # симулятор по умолчанию (iPhone 17)
#   DEVICE="iPhone 16" ./Scripts/make-screenshots.sh
#
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
DEVICE="${DEVICE:-iPhone 17}"
APP_ID="com.petara94.cbtapp"
RUNNER_ID="com.petara94.cbtapp.uitests.xctrunner"

cd "$(dirname "$0")/.."

UDID=$(xcrun simctl list devices available | grep "$DEVICE (" | grep -oE '[0-9A-F-]{36}' | head -1)
if [ -z "${UDID:-}" ]; then
  echo "Не найден доступный симулятор «$DEVICE»." >&2
  exit 1
fi
echo "Симулятор: $DEVICE ($UDID)"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl uninstall "$UDID" "$APP_ID" 2>/dev/null || true   # чистое состояние

RESULT="$(mktemp -d)/Results.xcresult"
xcodebuild test \
  -project CBTDiary.xcodeproj \
  -scheme CBTDiary \
  -destination "platform=iOS Simulator,id=$UDID" \
  -resultBundlePath "$RESULT" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""

DATA=$(xcrun simctl get_app_container "$UDID" "$RUNNER_ID" data)
SRC="$DATA/Library/Caches/Screenshots"

mkdir -p Screenshots
# 4 экрана для баннера README: Сегодня → создание (дата/время) → чувства → Узоры
SHOTS=(07-today-with-entry 02-step-event 05-step-intensity 09-patterns)
for s in "${SHOTS[@]}"; do cp "$SRC/$s.png" Screenshots/; done

# Склеиваем их по горизонтали в одно фото для README.
xcrun swift Scripts/stitch.swift Screenshots/overview.png \
  Screenshots/07-today-with-entry.png \
  Screenshots/02-step-event.png \
  Screenshots/05-step-intensity.png \
  Screenshots/09-patterns.png

echo "Готово. Обновлены ./Screenshots/*.png и overview.png"
ls Screenshots/
