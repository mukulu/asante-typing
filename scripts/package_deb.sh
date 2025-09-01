#!/usr/bin/env bash
# package_deb.sh — Build a Linux Release, system-install for testing,
# stage files into pkgroot, and produce a Debian .deb with fpm.
# This script encodes the exact working sequence you confirmed.

set -Eeuo pipefail

# ---- Config you may tweak ----------------------------------------------------
APP_NAME="asante-typing"                   # Debian package name
BINARY_NAME="asante_typing"                # Installed binary name
INSTALL_PREFIX="/usr"                      # FHS system install prefix
BUILD_TYPE="Release"
PKG_BUILD_DIR="build/linux/x64/release/pkg/cmake"
BUNDLE_DIR="build/linux/x64/release/bundle"
PKGROOT="$(pwd)/pkgroot"

# Version: use env APPVER if set, else read pubspec.yaml, else fallback.
APPVER="${APPVER:-$(awk -F': *' '/^version:/{print $2; exit}' pubspec.yaml 2>/dev/null || echo '0.1.0')}"
ARCH="amd64"

VENDOR="John Francis Mukulu <john.f.mukulu@gmail.com>"
HOMEPAGE="https://mukulu.org"
LICENSE="MIT"
DESCRIPTION="Asante Typing – learn touch-typing with interactive lessons."
# -----------------------------------------------------------------------------

echo "==> Cleaning workspace"
git clean -xfd || true
flutter clean
flutter pub get

echo "==> Flutter Release build (bundle)"
flutter build linux --release

echo "==> Configure CMake (packaging/FHS mode)"
rm -rf "${PKG_BUILD_DIR}"
cmake -S linux -B "${PKG_BUILD_DIR}" \
  -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
  -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
  -DASANTE_SYSTEM_INSTALL=ON

echo "==> Build native runner"
cmake --build "${PKG_BUILD_DIR}" --config "${BUILD_TYPE}"

echo "==> System install for local test (needs sudo)"
sudo cmake --install "${PKG_BUILD_DIR}"

echo "==> Refresh desktop/icon caches (needs sudo)"
sudo update-desktop-database || true
sudo gtk-update-icon-cache -f /usr/share/icons/hicolor || true

echo "==> Stage files into pkgroot exactly as they'd be installed"
sudo rm -rf "${PKGROOT}"
sudo mkdir -p "${PKGROOT}"
# NOTE: using sudo here mirrors your working sequence and avoids permission hiccups
sudo DESTDIR="${PKGROOT}" cmake --install "${PKG_BUILD_DIR}"

echo "==> Remove any existing ${APP_NAME}*.deb (per your workflow)"
sudo rm -f ${APP_NAME}*.deb || true

echo "==> Ensure fpm is available (ruby-dev, rubygems, build-essential required)"
if ! command -v fpm >/dev/null 2>&1; then
  echo "!! fpm not found. Installing (needs sudo) ..."
  sudo apt-get update
  sudo apt-get install -y ruby-dev rubygems build-essential
  sudo gem install --no-document fpm
fi

echo "==> Build .deb with fpm (using sudo as you did)"
sudo fpm -s dir -t deb \
  -n "${APP_NAME}" -v "${APPVER}" -a "${ARCH}" \
  --description "${DESCRIPTION}" \
  --license "${LICENSE}" \
  --url "${HOMEPAGE}" \
  --vendor "${VENDOR}" \
  -C "${PKGROOT}" .

echo "==> Install the freshly built package (needs sudo)"
DEB_FILE="${APP_NAME}_${APPVER}_${ARCH}.deb"
sudo apt install ./"${DEB_FILE}"

echo "==> Make the .deb world-writable (per your convenience workflow)"
sudo chmod a+rwx ${APP_NAME}*.deb || true

echo
echo "✅ Done."
echo "Package: ${DEB_FILE}"
echo "Binary  : ${INSTALL_PREFIX}/bin/${BINARY_NAME}"
echo
echo "Tip: Launch via '${BINARY_NAME}' or from your app menu (icon: org.mukulu.asante_typing)."
