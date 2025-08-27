#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.0.0}"
APP_NAME="Asante Typing"
APP_BIN_NAME="asante-typing"  # launcher name
BUNDLE_DIR="build/linux/x64/release/bundle"

if [[ ! -d "$BUNDLE_DIR" ]]; then
  echo "Bundle not found: $BUNDLE_DIR" >&2
  exit 1
fi

WORK="dist/linux/pkg"
DEB_OUT="dist/linux"
mkdir -p "$WORK/DEBIAN" "$WORK/usr/bin" "$WORK/opt/$APP_BIN_NAME" "$WORK/usr/share/applications"

# copy built files
cp -a "$BUNDLE_DIR/." "$WORK/opt/$APP_BIN_NAME/"

# simple launcher wrapper
cat > "$WORK/usr/bin/$APP_BIN_NAME" <<'EOF'
#!/usr/bin/env bash
DIR="/opt/asante-typing"
exec "$DIR/${APPIMAGE:-}/asante_typing" "$@"
EOF
chmod +x "$WORK/usr/bin/$APP_BIN_NAME"

# .desktop entry
cat > "$WORK/usr/share/applications/${APP_BIN_NAME}.desktop" <<EOF
[Desktop Entry]
Name=$APP_NAME
Exec=$APP_BIN_NAME
Icon=
Type=Application
Categories=Utility;Education;
Terminal=false
EOF

# control file
cat > "$WORK/DEBIAN/control" <<EOF
Package: ${APP_BIN_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Asante <noreply@example.com>
Description: $APP_NAME - typing tutor
 A Flutter-based typing tutor.
EOF

mkdir -p "$DEB_OUT"
dpkg-deb --build "$WORK" "${DEB_OUT}/${APP_BIN_NAME}_${VERSION}_amd64.deb"
echo "Built ${DEB_OUT}/${APP_BIN_NAME}_${VERSION}_amd64.deb"
