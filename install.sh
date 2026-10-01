#!/usr/bin/env bash
# Downloads a Revenant binary from GitHub Releases into $RUNNER_TEMP/revenant/.
# No Go or npm required on the runner.

set -euo pipefail
set +x

FREE_CLI_REPOSITORY="277pawan/freerev-cli"
PRIVATE_CLI_REPOSITORY="277pawan/revenant-cli"
CURL_BIN="${CURL_BIN:-curl}"

resolve_cli_repository() {
  if [[ -n "${REVENANT_GITHUB_TOKEN:-}" ]]; then
    CLI_REPOSITORY="$PRIVATE_CLI_REPOSITORY"
    REVENANT_CLI_SOURCE="private"
  else
    CLI_REPOSITORY="$FREE_CLI_REPOSITORY"
    REVENANT_CLI_SOURCE="free"
  fi
}

release_endpoint_for() {
  local repository="$1"
  local version="$2"

  if [[ "$version" == "latest" ]]; then
    printf 'https://api.github.com/repos/%s/releases/latest\n' "$repository"
    return
  fi
  if [[ ! "$version" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    echo "Invalid Revenant CLI version tag." >&2
    return 1
  fi
  printf 'https://api.github.com/repos/%s/releases/tags/%s\n' "$repository" "$version"
}

report_download_error() {
  if [[ "$REVENANT_CLI_SOURCE" == "private" ]]; then
    printf '%s\n' \
      "Failed to access the private Revenant CLI release." \
      "Verify github-token is configured and has Contents: read access to 277pawan/revenant-cli." >&2
  else
    printf '%s\n' "Failed to download a release from the public Revenant Free CLI." >&2
  fi
}

request_github_file() {
  local url="$1"
  local output_path="$2"
  local accept="$3"
  local auth_config=""

  if [[ -n "${REVENANT_GITHUB_TOKEN:-}" ]]; then
    auth_config="$(mktemp)"
    chmod 600 "$auth_config"
    printf 'header = "Authorization: Bearer %s"\n' "$REVENANT_GITHUB_TOKEN" > "$auth_config"
  fi

  local -a curl_args=(--fail --silent --show-error --location --header "Accept: ${accept}")
  if [[ -n "$auth_config" ]]; then
    curl_args+=(--config "$auth_config")
  fi

  if ! "$CURL_BIN" "${curl_args[@]}" "$url" --output "$output_path" 2>/dev/null; then
    [[ -z "$auth_config" ]] || rm -f "$auth_config"
    report_download_error
    return 1
  fi
  [[ -z "$auth_config" ]] || rm -f "$auth_config"
}

main() {
  local version="${REVENANT_VERSION:-latest}"
  local install_dir="${RUNNER_TEMP:?RUNNER_TEMP is required}/revenant"
  local os arch archive extension release_endpoint release_file asset_id download_file

  resolve_cli_repository
  mkdir -p "$install_dir"

  case "$(uname -s)" in
    Linux) os=linux ;;
    Darwin) os=darwin ;;
    MINGW*|MSYS*|CYGWIN*) os=windows ;;
    *) echo "Unsupported operating system for Revenant CLI." >&2; return 1 ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "Unsupported CPU architecture for Revenant CLI." >&2; return 1 ;;
  esac

  release_endpoint="$(release_endpoint_for "$CLI_REPOSITORY" "$version")"

  release_file="${install_dir}/release.json"
  request_github_file "$release_endpoint" "$release_file" "application/vnd.github+json"

  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to read the GitHub release metadata." >&2
    return 1
  fi

  local tag version_number
  if ! tag="$(jq -er '.tag_name | select(type == "string" and length > 0)' "$release_file" 2>/dev/null)"; then
    report_download_error
    return 1
  fi
  version_number="${tag#v}"

  if [[ "$os" == "windows" ]]; then
    extension=zip
  else
    extension=tar.gz
  fi
  archive="revenant_${version_number}_${os}_${arch}.${extension}"

  if ! asset_id="$(jq -er --arg name "$archive" '.assets[] | select(.name == $name) | .id' "$release_file" 2>/dev/null)"; then
    report_download_error
    return 1
  fi

  download_file="${install_dir}/${archive}"
  request_github_file \
    "https://api.github.com/repos/${CLI_REPOSITORY}/releases/assets/${asset_id}" \
    "$download_file" \
    "application/octet-stream"

  mkdir -p "${install_dir}/extract"
  if [[ "$extension" == "zip" ]]; then
    unzip -q -o "$download_file" -d "${install_dir}/extract"
  else
    tar -xzf "$download_file" -C "${install_dir}/extract"
  fi

  local binary
  binary="$(find "${install_dir}/extract" -type f -name revenant -print -quit)"
  if [[ -z "$binary" ]]; then
    echo "The selected Revenant CLI release archive did not contain the binary." >&2
    return 1
  fi

  chmod +x "$binary"
  mv "$binary" "${install_dir}/revenant"
  printf '%s\n' "$install_dir" >> "$GITHUB_PATH"
  printf 'REVENANT_CLI_SOURCE=%s\n' "$REVENANT_CLI_SOURCE" >> "$GITHUB_ENV"
  echo "Revenant CLI installed from the ${REVENANT_CLI_SOURCE} distribution (${tag})."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
