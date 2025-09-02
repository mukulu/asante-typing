# from repo root
flutter clean && flutter pub get && flutter build windows --release

# version tag (edit as you like)
export VERSION="0.2.0"

# dirs
export RELEASE_DIR="build/windows/x64/runner/Release"
export DIST="dist/windows"
mkdir -p "$DIST"

# create portable zip (prefer 7z; fallback to PowerShell)
if command -v 7z >/dev/null 2>&1; then
  (cd "$RELEASE_DIR" && 7z a -tzip -mx=9 "$(pwd -W)\\..\\..\\..\\..\\$DIST\\AsanteTyping-$VERSION-portable.zip" .)
else
  powershell.exe -NoProfile -Command \
    "Compress-Archive -Path \"$(cd "$RELEASE_DIR" && pwd -W)\\*\" -DestinationPath \"$(pwd -W)\\$DIST\\AsanteTyping-$VERSION-portable.zip\" -Force"
fi

echo "Portable ZIP => $DIST/AsanteTyping-$VERSION-portable.zip"
