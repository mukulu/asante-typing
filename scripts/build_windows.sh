#!/usr/bin/env bash
# Build & package Asante Typing on Windows (Git Bash / MSYS).
# - flutter build windows --release
# - Portable ZIP: dist/windows/<NiceName>-<ver>-portable.zip
# - Inno Setup installer (EXE): dist/windows/<NiceName>-<ver>-Setup.exe
#
# Usage:
#   bash scripts/build_windows.sh
#   bash scripts/build_windows.sh -v 1.2.3

set -Eeuo pipefail

# --------------------------- CLI ---------------------------------------------
VERSION=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--version) VERSION="${2:-}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# --------------------------- Helpers -----------------------------------------
repo_root() { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; }
abs_win_path() { (cd "$1" >/dev/null 2>&1 && pwd -W) 2>/dev/null || cygpath -w "$1"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' not found in PATH."; exit 1; }; }

find_iscc() {
  # Prefer PATH if user added it
  if command -v iscc >/dev/null 2>&1; then command -v iscc; return; fi
  # Default install path
  local p="/c/Program Files (x86)/Inno Setup 6/ISCC.exe"
  [[ -f "$p" ]] && { echo "$p"; return; }
  echo ""
}

# --------------------------- Meta from pubspec --------------------------------
ROOT="$(repo_root)"
cd "$ROOT"

APP_NAME="$(awk -F': *' '/^name:/{print $2; exit}' pubspec.yaml 2>/dev/null || echo 'asante_typing')"
APP_DESC="$(awk -F': *' '/^description:/{sub(/^[^:]+: */,""); print; exit}' pubspec.yaml 2>/dev/null || echo 'Asante Typing')"

if [[ -z "$VERSION" ]]; then
  VERSION="$(awk -F': *' '/^version:/{print $2; exit}' pubspec.yaml 2>/dev/null || echo '0.1.0')"
  VERSION="${VERSION%%+*}"
fi

# Runner EXE base (fallback to dart package name)
EXE_BASE="$(awk -F'\"' '/set\(BINARY_NAME/{print $2; exit}' windows/CMakeLists.txt 2>/dev/null || true)"
[[ -z "$EXE_BASE" ]] && EXE_BASE="${APP_NAME//-/_}"

# A nice, title-cased name for file names
PASCAL_TITLE="$(echo "$APP_NAME" | sed -E 's/[_-]+/ /g;s/.*/\L&/;s/\<./\U&/g;s/ //g')"
[[ -z "$PASCAL_TITLE" ]] && PASCAL_TITLE="AsanteTyping"

echo "==> App name   : $APP_NAME"
echo "==> Version    : $VERSION"
echo "==> EXE base   : $EXE_BASE"
echo "==> Nice title : $PASCAL_TITLE"

# --------------------------- Tooling -----------------------------------------
need flutter
ISCC_BIN="$(find_iscc)"
if [[ -z "$ISCC_BIN" ]]; then
  echo "ERROR: Inno Setup ISCC.exe not found. Install from https://www.innosetup.com and/or add to PATH." >&2
  exit 1
fi

# --------------------------- Build -------------------------------------------
echo "==> flutter clean / pub get / build windows --release"
flutter clean
flutter pub get
flutter build windows --release

RELEASE_DIR="build/windows/x64/runner/Release"
EXE_PATH="$RELEASE_DIR/$EXE_BASE.exe"
if [[ ! -f "$EXE_PATH" ]]; then
  echo "!! exe not found at $EXE_PATH"
  EXE_PATH_FALLBACK="$(ls -1 "$RELEASE_DIR"/*.exe 2>/dev/null | grep -vi 'console_runner\|test' | head -n1 || true)"
  if [[ -n "$EXE_PATH_FALLBACK" ]]; then
    echo "   using fallback: $(basename "$EXE_PATH_FALLBACK")"
    EXE_PATH="$EXE_PATH_FALLBACK"; EXE_BASE="$(basename "$EXE_PATH" .exe)"
  else
    echo "ERROR: No release exe found. Aborting." >&2; exit 1
  fi
fi

# --------------------------- Portable ZIP -------------------------------------
DIST_DIR="dist/windows"
mkdir -p "$DIST_DIR"
ZIP_PATH="$DIST_DIR/${PASCAL_TITLE}-${VERSION}-portable.zip"

echo "==> Creating portable ZIP: $ZIP_PATH"
REL_WIN="$(abs_win_path "$RELEASE_DIR")"
ZIP_WIN_DIR="$(abs_win_path "$(dirname "$ZIP_PATH")")"
ZIP_WIN="${ZIP_WIN_DIR}\\$(basename "$ZIP_PATH")"

portable_ok=false
if command -v 7z >/dev/null 2>&1; then
  7z a -tzip -mx=9 "$ZIP_WIN" "${REL_WIN}\\*" >/dev/null
  portable_ok=true
elif command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -NoProfile -Command \
    "Compress-Archive -Path '${REL_WIN}\\*' -DestinationPath '${ZIP_WIN}' -Force" >/dev/null
  portable_ok=true
else
  echo "WARNING: Neither 7z nor PowerShell found; skipping portable zip." >&2
fi
$portable_ok && echo "==> Portable ZIP created."

# --------------------------- Inno Setup ---------------------------------------
echo "==> Compiling installer with Inno Setup"
ISS_SRC="asante-typing.iss"
[[ -f "$ISS_SRC" ]] || { echo "ERROR: Missing $ISS_SRC" >&2; exit 1; }

# Use ISCC’s /O to direct output to dist\windows and /D to feed the version.
OUT_WIN="$(abs_win_path "$DIST_DIR")"

# IMPORTANT: prevent MSYS from converting /D and /O paths
MSYS2_ARG_CONV_EXCL='*' \
"$ISCC_BIN" \
  /Qp \
  "/DMyAppVersion=$VERSION" \
  "/O$OUT_WIN" \
  "$ISS_SRC"

# --------------------------- Collect output -----------------------------------
echo "==> Locating installer output"
SETUP_FOUND="$(ls -1t \
  "$DIST_DIR"/*Setup*.exe \
  "$(dirname "$ISS_SRC")"/*Setup*.exe \
  "$ROOT"/*Setup*.exe \
  2>/dev/null | head -n1 || true)"

if [[ -z "$SETUP_FOUND" ]]; then
  echo "ERROR: Could not find the generated installer. Check OutputBaseFilename in your .iss." >&2
  exit 1
fi

TARGET_SETUP="$DIST_DIR/${PASCAL_TITLE}-${VERSION}-Setup.exe"
cp -f "$SETUP_FOUND" "$TARGET_SETUP"

echo
echo "✅ Done."
$portable_ok && echo "Portable ZIP : $ZIP_PATH" || echo "Portable ZIP : (skipped)"
echo "Installer    : $TARGET_SETUP"
echo
echo "Tip: run with explicit version:"
echo "     bash scripts/build_windows.sh -v 1.2.3"
