#!/usr/bin/env bash
set -euo pipefail

ACTION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ACTION_DIR}/install.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

unset REVENANT_GITHUB_TOKEN || true
resolve_cli_repository
[[ "$CLI_REPOSITORY" == "$FREE_CLI_REPOSITORY" ]] || fail "default did not select the free CLI"
[[ "$REVENANT_CLI_SOURCE" == "free" ]] || fail "default source was not marked free"
release_endpoint_for "$CLI_REPOSITORY" latest | grep -Fxq \
  "https://api.github.com/repos/${FREE_CLI_REPOSITORY}/releases/latest" ||
  fail "latest did not resolve against the free repository"
echo "PASS: no token selects only the public free CLI"

REVENANT_GITHUB_TOKEN="test-secret-token"
resolve_cli_repository
[[ "$CLI_REPOSITORY" == "$PRIVATE_CLI_REPOSITORY" ]] || fail "token did not select the private CLI"
[[ "$REVENANT_CLI_SOURCE" == "private" ]] || fail "authenticated source was not marked private"
release_endpoint_for "$CLI_REPOSITORY" latest | grep -Fxq \
  "https://api.github.com/repos/${PRIVATE_CLI_REPOSITORY}/releases/latest" ||
  fail "latest did not resolve against the private repository"
release_endpoint_for "$CLI_REPOSITORY" v0.2.0 | grep -Fxq \
  "https://api.github.com/repos/${PRIVATE_CLI_REPOSITORY}/releases/tags/v0.2.0" ||
  fail "tag version did not resolve against the private repository"
echo "PASS: explicit token selects the private CLI"

CURL_BIN=/bin/false
error_file="$(mktemp)"
if request_github_file \
  "https://api.github.com/repos/${CLI_REPOSITORY}/releases/latest" \
  "${error_file}.json" "application/vnd.github+json" 2>"$error_file"; then
  rm -f "$error_file" "${error_file}.json"
  fail "invalid private request unexpectedly succeeded"
fi
grep -q "Failed to access the private Revenant CLI release" "$error_file" ||
  fail "private request did not return a clear authentication error"
grep -q "test-secret-token" "$error_file" && fail "token was printed in error output"
[[ "$CLI_REPOSITORY" == "$PRIVATE_CLI_REPOSITORY" ]] ||
  fail "failed private request silently fell back to the free CLI"
rm -f "$error_file" "${error_file}.json"
echo "PASS: private failures are clear, redacted, and do not fall back"

for status in 401 403 404; do
  message="$(report_download_error "$status" 2>&1)"
  [[ "$message" == *"HTTP ${status}"* || "$message" == *"${status}"* ]] ||
    fail "HTTP ${status} was not included in private diagnostics"
  [[ "$message" != *"test-secret-token"* ]] || fail "token was printed in status diagnostics"
done
echo "PASS: private HTTP failures are categorized without leaking tokens"