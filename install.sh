#!/usr/bin/env bash
# Downloads a Revenant binary from GitHub Releases into $RUNNER_TEMP/revenant/.
# No Go, no npm — works on any GitHub Actions runner (ubuntu, macos, windows via bash).

set -euo pipefail

VERSION="${REVENANT_VERSION:-v0.1.0}"
REPO="${REVENANT_REPO:-277pawan/revenant-cli}"
INSTALL_DIR="${RUNNER_TEMP}/revenant"
mkdir -p "$INSTALL_DIR"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *)
    echo "Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

if [[ "$VERSION" == "latest" ]]; then
  API="https://api.github.com/repos/${REPO}/releases/latest"
  VERSION="$(curl -fsSL "$API" | grep -m1 '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')"
fi

# Strip leading v for archive name; GoReleaser uses v in tag but archive may include it
TAG="$VERSION"
VER="${VERSION#v}"

ARCHIVE="revenant_${TAG}_${OS}_${ARCH}"
if [[ "$OS" == "windows" ]]; then
  ARCHIVE="${ARCHIVE}.zip"
  EXTRACT="unzip -o"
else
  ARCHIVE="${ARCHIVE}.tar.gz"
  EXTRACT="tar -xzf"
fi

URL="https://github.com/${REPO}/releases/download/${TAG}/${ARCHIVE}"
TMP="${INSTALL_DIR}/download"

echo "Installing Revenant ${TAG} from ${URL}"
curl -fsSL -o "$TMP" "$URL"
mkdir -p "${INSTALL_DIR}/extract"
cd "${INSTALL_DIR}/extract"
$EXTRACT "$TMP"
BIN="$(find "${INSTALL_DIR}/extract" -name revenant -type f | head -1)"
if [[ -z "$BIN" ]]; then
  echo "revenant binary not found in ${ARCHIVE}" >&2
  exit 1
fi
chmod +x "$BIN"
mv "$BIN" "${INSTALL_DIR}/revenant"
echo "${INSTALL_DIR}" >> "$GITHUB_PATH"
echo "Revenant installed to ${INSTALL_DIR}/revenant"
