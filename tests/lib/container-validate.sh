#!/usr/bin/env bash

# Runs INSIDE the disposable archlinux:latest container started by
# validate-local-install.sh. Never run this on the host.
#
# Expects, mounted read-only by the caller:
#   /package               the ravn-sessionizer package sources (PKGBUILD, etc.)
#   /archive/ravn-sessionizer-${PKG_VERSION}.tar.gz   the local source snapshot
#
# Expects, from the environment:
#   PKG_VERSION             package version, matches the archive filename

set -Eeuo pipefail

readonly TEST_HOME=/tmp/ravn-sessionizer-package-test

phase_install_prereqs() {
  printf '\n==> [container 1/5] Refreshing Arch and installing exact prerequisites\n'
  printf '    These packages exist only inside this disposable container.\n\n'
  pacman -Syu --noconfirm --needed fakeroot sudo make bash fzf jq git github-cli
}

phase_create_builder_user() {
  printf '\n==> [container 2/5] Creating the unprivileged makepkg user\n'
  useradd --create-home builder
  printf 'builder ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/builder
  chmod 0440 /etc/sudoers.d/builder
}

phase_prepare_workspace() {
  printf '==> [container 3/5] Preparing the writable package workspace\n'
  install -d -m 0755 /work/package
  cp -a /package/. /work/package/

  # The checkout may contain ignored makepkg artifacts.  They must not let this
  # validation install an older package instead of building the current
  # PKGBUILD.
  find /work/package -maxdepth 1 -type f -name '*.pkg.tar.*' -delete

  # A local git archive has different bytes from the published GitHub archive.
  # Redirect PKGBUILD to it here; validate-release-archive.sh independently
  # checks the published checksums.
  sed -i \
    "s|\${url}/archive/refs/tags/v\${pkgver}.tar.gz|file:///archive/ravn-sessionizer-${PKG_VERSION}.tar.gz|" \
    /work/package/PKGBUILD

  chown -R builder:builder /work/package
}

phase_build_and_install() {
  printf '==> [container 4/5] Building and installing the local package\n'
  su --shell /bin/bash builder --command \
      'cd /work/package && makepkg -Cf --nodeps --noconfirm --skipchecksums'
  # herdr y ravn-trio vienen de omarchy-personal-repo, no de los repos de Arch:
  # el contenedor instala sin chequear dependencias (el payload no las usa).
  pacman -U --noconfirm --nodeps --nodeps /work/package/*.pkg.tar.*
}

phase_verify_payload() {
  local share=/usr/share/ravn/sessionizer
  test -L /usr/bin/ravn-sessionizer
  test "$(readlink /usr/bin/ravn-sessionizer)" = "$share/ravn-sessionizer"
  test -x "$share/ravn-sessionizer"
  test -x "$share/runtime/scripts/pick"
  test -f "$share/herdr-plugin.toml"
  grep -Fxq 'id = "ravn.sessionizer"' "$share/herdr-plugin.toml"
  test -f /etc/ravn/sessionizer.conf
  test -f /usr/share/licenses/ravn-sessionizer/LICENSE
  test -e /usr/share/bash-completion/completions/ravn-sessionizer
  pacman -Qkk ravn-sessionizer > /dev/null
}

phase_verify_help_command() {
  NO_COLOR=1 HOME="$TEST_HOME" TERM=dumb /usr/bin/ravn-sessionizer help \
    > /tmp/ravn-sessionizer-help-output
  grep -Fq 'COMMANDS' /tmp/ravn-sessionizer-help-output
  grep -Fq 'trio' /tmp/ravn-sessionizer-help-output
}

phase_verify_list_command() {
  # Una raíz temporal con un repo y un pj-* con miembro; herdr falso sin workspaces.
  local root="$TEST_HOME/tries" herdr="$TEST_HOME/herdr"
  mkdir -p "$TEST_HOME"
  git init -q "$root/alpha"
  git init -q "$root/pj-demo"
  git init -q "$root/pj-demo/miembro"
  printf 'SES_ROOTS=(%q)\nSES_EXTRA=()\n' "$root" > "$TEST_HOME/sessionizer.conf"
  printf '#!/bin/sh\necho %s\n' \
    "'{\"result\":{\"snapshot\":{\"workspaces\":[],\"tabs\":[],\"panes\":[]}}}'" > "$herdr"
  chmod +x "$herdr"
  NO_COLOR=1 HOME="$TEST_HOME" HERDR_BIN_PATH="$herdr" \
    RAVN_SESSIONIZER_CONFIG="$TEST_HOME/sessionizer.conf" \
    /usr/bin/ravn-sessionizer list workspaces > /tmp/ravn-sessionizer-list-output
  grep -q "^dir	$root/alpha	" /tmp/ravn-sessionizer-list-output
  grep -q "^pj	$root/pj-demo	" /tmp/ravn-sessionizer-list-output
  grep -q "^dir	$root/pj-demo/miembro	" /tmp/ravn-sessionizer-list-output
}

phase_exercise_public_commands() {
  printf '\n==> [container 5/5] Confirming the installed public commands behave as expected\n'
  phase_verify_payload
  phase_verify_help_command
  phase_verify_list_command
  printf '==> [container 5/5] PASS: payload, help, and list (repos + pj-* + members) behaved as expected\n'
}

main() {
  phase_install_prereqs
  phase_create_builder_user
  phase_prepare_workspace
  phase_build_and_install
  phase_exercise_public_commands
}

main "$@"
