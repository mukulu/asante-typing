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

if [[ ! -d "$WORK/DEBIAN" ]]; then
  echo "Failed to create directory: $WORK/DEBIAN" >&2
  exit 1
fi

# copy built files
cp -a "$BUNDLE_DIR/." "$WORK/opt/$APP_BIN_NAME/"

if [[ ! -f "$WORK/opt/$APP_BIN_NAME/asante_typing" ]]; then
  echo "Main binary not found in $WORK/opt/$APP_BIN_NAME/asante_typing" >&2
  exit 1
fi

# simple launcher wrapper
cat > "$WORK/usr/bin/$APP_BIN_NAME" <<'EOF'
#!/usr/bin/env bash
DIR="/opt/asante-typing"
exec "$DIR/asante_typing" "$@"
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
Maintainer: John Francis Mukulu SJ <johnfmukulu@gmail.com>
Homepage: https://mukulu.org/asante-typing
Vcs-Git: https://github.com/mukulu/asante-typing.git
Description: $APP_NAME - typing tutor
 Asante Typing is an open-source typing tutor designed to help users improve
 their typing speed and accuracy. Featuring interactive lessons and customizable
 settings, it supports multiple keyboard layouts and provides real-time feedback
 to enhance touch-typing skills. Ideal for beginners and advanced users alike.
EOF

# copyright file
cat > "$WORK/DEBIAN/copyright" <<EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: $APP_NAME
Upstream-Contact: John Francis Mukulu SJ <noreply@example.com>
Source: https://github.com/mukulu/asante-typing

Files: *
Copyright: 2025 John Francis Mukulu SJ
License: GPL-3.0
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, version 3.
 .
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 .
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <https://www.gnu.org/licenses/>.

License: GPL-3.0
 On Debian systems, the complete text of the GNU General Public
 License version 3 can be found in "/usr/share/common-licenses/GPL-3".
EOF

mkdir -p "$DEB_OUT"

# --- FIX: normalise DEBIAN/ perms to satisfy dpkg-deb ---
# Some filesystems create dirs with g+s (2775). dpkg-deb requires 0755–0775.
chmod -R ug-s "$WORK/DEBIAN"
find "$WORK/DEBIAN" -type d -exec chmod 0755 {} \;
# control, copyright, conffiles, etc. must be readable (0644)
find "$WORK/DEBIAN" -maxdepth 1 -type f -not -name 'preinst' -not -name 'postinst' -not -name 'prerm' -not -name 'postrm' -exec chmod 0644 {} \;
# Maintainer scripts must be executable (0755) if present
for f in preinst postinst prerm postrm; do
  [ -f "$WORK/DEBIAN/$f" ] && chmod 0755 "$WORK/DEBIAN/$f"
done
# --- END FIX ---

# Debug: List permissions
ls -lR "$WORK/DEBIAN"

# Check for dpkg-deb
if ! command -v dpkg-deb >/dev/null; then
  echo "dpkg-deb is not installed. Please install it (e.g., sudo apt install dpkg)." >&2
  exit 1
fi

dpkg-deb --build "$WORK" "${DEB_OUT}/${APP_BIN_NAME}_${VERSION}_amd64.deb"
echo "Built ${DEB_OUT}/${APP_BIN_NAME}_${VERSION}_amd64.deb"