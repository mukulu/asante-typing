#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.0.0}"
APP_NAME="Asante Typing"
APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
OUT_DIR="dist/macos"
DMG="${OUT_DIR}/asante-typing-macos-${VERSION}.dmg"

mkdir -p "$OUT_DIR"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found: $APP_PATH" >&2
  exit 1
fi

create-dmg \
  --volname "${APP_NAME}" \
  --window-pos 200 120 \
  --window-size 540 380 \
  --icon-size 96 \
  --app-drop-link 380 205 \
  --icon "${APP_NAME}.app" 140 205 \
  "$DMG" \
  "$(dirname "$APP_PATH")"

echo "Built $DMG"
