#!/usr/bin/env bash

# Fast, network-free contract tests for the upstream package automation.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
PACKAGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly PACKAGE_DIR

test_dir=""

die() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file_line() {
  local expected="$1"
  local path="$2"
  grep -Fxq "$expected" "$path" || die "missing '$expected' in $path"
}

setup() {
  test_dir="$(mktemp -d "${TMPDIR:-/tmp}/ravn-sessionizer-automation-test.XXXXXX")"
  trap 'rm -rf "$test_dir"' EXIT
  mkdir -p "$test_dir/bin"
  # El PKGBUILD vivo ya no fija checksums (contrato del empaquetado al
  # vuelo de package.yml). El updater de releases sigue siendo legacy y
  # necesita el contrato viejo con checksum fijo, así que el fixture lo
  # lleva completo y no depende del PKGBUILD vivo.
  cat > "$test_dir/PKGBUILD" <<'FIXTURE_PKGBUILD'
pkgname=ravn-sessionizer
pkgver=0.2.0
pkgrel=1
pkgdesc='Fixture legacy del contrato de releases para el updater'
arch=('any')
url='https://github.com/robert-flo/ravn-sessionizer'
license=('MIT')
makedepends=('make')
depends=('bash')
source=("ravn-sessionizer-0.2.0.tar.gz")
sha256sums=(
  '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
)

package() {
  :
}
FIXTURE_PKGBUILD

  cat > "$test_dir/bin/gh" <<'MOCK_GH'
#!/usr/bin/env bash
printf '%s\n' '{"tag_name":"v9.8.7"}'
MOCK_GH

  cat > "$test_dir/bin/curl" <<'MOCK_CURL'
#!/usr/bin/env bash
set -Eeuo pipefail
output=""
while (($#)); do
  if [[ $1 == --output ]]; then
    output="$2"
    shift 2
  else
    shift
  fi
done
[[ -n $output ]]
printf '%s\n' 'deterministic upstream archive fixture' > "$output"
MOCK_CURL

  chmod +x "$test_dir/bin/gh" "$test_dir/bin/curl"
}

test_check_detects_release() {
  local output_file="$test_dir/check-output"
  local expected_checksum

  expected_checksum="$(printf '%s\n' 'deterministic upstream archive fixture' | sha256sum | awk '{print $1}')"
  PATH="$test_dir/bin:$PATH" \
    PKGBUILD_PATH="$test_dir/PKGBUILD" \
    GITHUB_OUTPUT="$output_file" \
    "$PACKAGE_DIR/scripts/check_upstream.sh" > /dev/null

  assert_file_line 'changed=true' "$output_file"
  assert_file_line 'upstream_tag=v9.8.7' "$output_file"
  assert_file_line 'upstream_version=9.8.7' "$output_file"
  assert_file_line "archive_sha256=$expected_checksum" "$output_file"
}

test_update_changes_version_and_resets_release() {
  local checksum
  checksum="$(printf '%s\n' 'deterministic upstream archive fixture' | sha256sum | awk '{print $1}')"

  PKGBUILD_PATH="$test_dir/PKGBUILD" \
    UPSTREAM_VERSION=9.8.7 \
    ARCHIVE_SHA256="$checksum" \
    "$PACKAGE_DIR/scripts/update_package.sh" > /dev/null

  assert_file_line 'pkgver=9.8.7' "$test_dir/PKGBUILD"
  assert_file_line 'pkgrel=1' "$test_dir/PKGBUILD"
  assert_file_line "  '$checksum'" "$test_dir/PKGBUILD"
}

test_check_sees_matching_package() {
  local output_file="$test_dir/matching-output"

  PATH="$test_dir/bin:$PATH" \
    PKGBUILD_PATH="$test_dir/PKGBUILD" \
    GITHUB_OUTPUT="$output_file" \
    "$PACKAGE_DIR/scripts/check_upstream.sh" > /dev/null

  assert_file_line 'changed=false' "$output_file"
}

test_same_version_checksum_change_increments_release() {
  local checksum
  checksum="$(printf 'b%.0s' {1..64})"

  PKGBUILD_PATH="$test_dir/PKGBUILD" \
    UPSTREAM_VERSION=9.8.7 \
    ARCHIVE_SHA256="$checksum" \
    "$PACKAGE_DIR/scripts/update_package.sh" > /dev/null

  assert_file_line 'pkgver=9.8.7' "$test_dir/PKGBUILD"
  assert_file_line 'pkgrel=2' "$test_dir/PKGBUILD"
  assert_file_line "  '$checksum'" "$test_dir/PKGBUILD"
}

main() {
  setup
  test_check_detects_release
  test_update_changes_version_and_resets_release
  test_check_sees_matching_package
  test_same_version_checksum_change_increments_release
  printf 'PASS: upstream automation contracts\n'
}

main "$@"
