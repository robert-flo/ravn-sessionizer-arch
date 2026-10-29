#!/usr/bin/env bash

# Fast, network-free contract tests for the guarded package updater.
#
# The release-tag automation is retired (update-upstream.yml, check_upstream.sh,
# sync_upstream.sh, validate-release-archive.sh, make test-release): package.yml
# builds the package from the dispatched source sha and PKGBUILD keeps
# sha256sums=('SKIP'). update_package.sh survives only as a guarded tool: it
# must die instead of overwriting the SKIP entry, under any input.

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

FIXED_CHECKSUM='0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'

write_pkgbuild_fixture() { # write_pkgbuild_fixture <path> <first-checksum>
  cat > "$1" <<FIXTURE_PKGBUILD
pkgname=ravn-sessionizer
pkgver=0.2.0
pkgrel=1
pkgdesc='Fixture del updater guardado'
arch=('any')
url='https://github.com/robert-flo/ravn-sessionizer'
license=('MIT')
makedepends=('make')
depends=('bash')
source=("ravn-sessionizer-0.2.0.tar.gz")
sha256sums=(
  '$2'
)

package() {
  :
}
FIXTURE_PKGBUILD
}

test_retired_automation_is_gone() {
  local gone
  for gone in \
    .github/workflows/update-upstream.yml \
    scripts/check_upstream.sh \
    scripts/sync_upstream.sh \
    tests/validate-release-archive.sh \
    tests/lib/container-verify-source.sh; do
    [[ ! -e "$PACKAGE_DIR/$gone" ]] || die "the retired release automation is back: $gone"
  done
  if grep -qF 'test-release' "$PACKAGE_DIR/make/package.mk"; then
    die 'make/package.mk still wires the retired test-release target'
  fi
  if grep -qF 'sync_upstream.sh' "$PACKAGE_DIR/make/package.mk"; then
    die 'make/package.mk still wires the retired update-upstream target'
  fi
}

test_update_refuses_to_overwrite_skip() {
  local fixture="$test_dir/skip-PKGBUILD"
  write_pkgbuild_fixture "$fixture" 'SKIP'
  local before
  before="$(cat "$fixture")"

  if PKGBUILD_PATH="$fixture" UPSTREAM_VERSION=9.8.7 \
       ARCHIVE_SHA256="$FIXED_CHECKSUM" \
       "$PACKAGE_DIR/scripts/update_package.sh" > "$test_dir/skip.out" 2>&1; then
    die 'update_package.sh overwrote the SKIP entry instead of dying'
  fi
  grep -qF 'SKIP' "$test_dir/skip.out" || die 'the SKIP refusal does not name SKIP'
  [[ "$(cat "$fixture")" == "$before" ]] || die 'the SKIP refusal mutated the PKGBUILD'
}

test_update_still_serves_a_fixed_checksum() {
  local fixture="$test_dir/fixed-PKGBUILD"
  write_pkgbuild_fixture "$fixture" "$FIXED_CHECKSUM"

  PKGBUILD_PATH="$fixture" UPSTREAM_VERSION=9.8.7 \
    ARCHIVE_SHA256="$FIXED_CHECKSUM" \
    "$PACKAGE_DIR/scripts/update_package.sh" > "$test_dir/fixed.out" 2>&1

  assert_file_line 'pkgver=9.8.7' "$fixture"
  assert_file_line 'pkgrel=1' "$fixture"
  assert_file_line "  '$FIXED_CHECKSUM'" "$fixture"
}

test_same_version_checksum_change_increments_release() {
  local fixture="$test_dir/bump-PKGBUILD"
  write_pkgbuild_fixture "$fixture" "$FIXED_CHECKSUM"

  PKGBUILD_PATH="$fixture" UPSTREAM_VERSION=0.2.0 \
    ARCHIVE_SHA256="$FIXED_CHECKSUM" \
    "$PACKAGE_DIR/scripts/update_package.sh" > "$test_dir/bump.out" 2>&1

  assert_file_line 'pkgver=0.2.0' "$fixture"
  assert_file_line 'pkgrel=2' "$fixture"
}

main() {
  test_dir="$(mktemp -d "${TMPDIR:-/tmp}/ravn-sessionizer-automation-test.XXXXXX")"
  trap 'rm -rf "$test_dir"' EXIT

  test_retired_automation_is_gone
  test_update_refuses_to_overwrite_skip
  test_update_still_serves_a_fixed_checksum
  test_same_version_checksum_change_increments_release
  printf 'PASS: guarded updater contracts\n'
}

main "$@"
