#!/usr/bin/env bash

set -euo pipefail

VERSION="${REVENANT_VERSION:-v0.1.1}"
REPO="${REVENANT_REPO:-277pawan/revenant-cli}"
INSTALL_DIR="${RUNNER_TEMP}/revenant"

mkdir -p "$INSTALL_DIR"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$OS" in
  linux)
    OS="linux"
    ;;
  darwin)
    OS="darwin"
    ;;
  msys*|mingw*|cygwin*|windows*)
    OS="windows"
    ;;
  *)
    echo "Unsupported OS: $OS" >&2
    exit 1
    ;;
esac

case "$ARCH" in
  x86_64|amd64)
    ARCH="amd64"
    ;;
  aarch64|arm64)
    ARCH="arm64"
    ;;
  *)
    echo "Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

if [[ "$VERSION" == "latest" ]]; then
  echo "Resolving latest Revenant release..."

  VERSION="$(
    curl -fsSL \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/${REPO}/releases/latest" |
    grep -m1 '"tag_name"' |
    sed -E 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/'
  )"

  if [[ -z "$VERSION" ]]; then
    echo "Could not determine latest Revenant release." >&2
    exit 1
  fi
fi

TAG="$VERSION"
VER="${VERSION#v}"

if [[ "$OS" == "windows" ]]; then
  ARCHIVE="revenant_${VER}_${OS}_${ARCH}.zip"
else
  ARCHIVE="revenant_${VER}_${OS}_${ARCH}.tar.gz"
fi

URL="https://github.com/${REPO}/releases/download/${TAG}/${ARCHIVE}"

echo "----------------------------------------"
echo "Installing Revenant"
echo "Repository : ${REPO}"
echo "Version    : ${TAG}"
echo "OS         : ${OS}"
echo "Architecture: ${ARCH}"
echo "Asset      : ${ARCHIVE}"
echo "URL        : ${URL}"
echo "----------------------------------------"

TMP="${INSTALL_DIR}/download"

if ! curl -fL \
  -H "Accept: application/octet-stream" \
  -o "$TMP" \
  "$URL"; then

  echo ""
  echo "ERROR: Revenant release asset was not found."
  echo ""
  echo "Expected asset:"
  echo "  ${ARCHIVE}"
  echo ""
  echo "Release:"
  echo "  https://github.com/${REPO}/releases/tag/${TAG}"
  echo ""

  exit 1
fi

mkdir -p "${INSTALL_DIR}/extract"

if [[ "$OS" == "windows" ]]; then
  unzip -o "$TMP" -d "${INSTALL_DIR}/extract"
else
  tar -xzf "$TMP" -C "${INSTALL_DIR}/extract"
fi

BIN="$(find "${INSTALL_DIR}/extract" -type f -name "revenant" | head -1)"

if [[ -z "$BIN" ]]; then
  echo "ERROR: Revenant binary not found in ${ARCHIVE}" >&2
  exit 1
fi

chmod +x "$BIN"

mv "$BIN" "${INSTALL_DIR}/revenant"

echo "${INSTALL_DIR}" >> "$GITHUB_PATH"

echo ""
echo "Revenant installed successfully:"
echo "${INSTALL_DIR}/revenant"
