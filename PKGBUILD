pkgname=ravn-sessionizer
# La versión rastreable la calcula el job de CI (package.yml) y la entrega
# por PKGVER: base.r<N>.<shortsha>, con N de `git describe --long` sobre el
# sha empaquetado (el tarball lo genera ese job con git archive del sha).
# Sin PKGVER, makepkg local usa la base del último release empaquetado.
pkgver="${PKGVER:-0.2.0}"
pkgrel=2
pkgdesc='Sessionizer para herdr: workspaces, repos, pj-* y agentes en un fzf; tríos desde los issues de todos los proyectos'
arch=('any')
url='https://github.com/robert-flo/ravn-sessionizer'
license=('MIT')
options=('!debug')
depends=('bash' 'fzf' 'jq' 'github-cli' 'git' 'herdr>=0.9.5' 'ravn-trio' 'ravn-omarchy-overlay>=0.1.1')
# herdr y ravn-trio los sirve omarchy-personal-repo (robert-flo/omarchy-pkgs).
optdepends=('tobi-try: clonar con try exec … clone los repos que falten (SES_CLONE_CMD)')
makedepends=('make')
backup=('etc/ravn/sessionizer.conf')
# Tarball al vuelo: lo genera el job de package.yml con `git archive` del
# sha despachado y lo deja en el directorio de build, así que makepkg no
# necesita credenciales de GitHub ni checksum congelado.
source=("${pkgname}-${pkgver}.tar.gz")
sha256sums=('SKIP')

package() {
  local source_dir="${srcdir}/${pkgname}-${pkgver}"

  make -C "${source_dir}" DESTDIR="${pkgdir}" install
  install -Dm644 "${source_dir}/sessionizer.conf.example" "${pkgdir}/etc/ravn/sessionizer.conf"
  install -Dm644 "${source_dir}/LICENSE" "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
  install -d "${pkgdir}/usr/share/bash-completion/completions"
  ln -s /usr/share/ravn/sessionizer/runtime/completion/ravn-sessionizer.bash \
    "${pkgdir}/usr/share/bash-completion/completions/ravn-sessionizer"
  # Alias rs/ri: drop-in que el rc de ravn-omarchy-overlay (>= 0.1.1) carga
  # en cada bash interactiva desde /usr/share/ravn/bash/rc.d/*.bash.
  install -d "${pkgdir}/usr/share/ravn/bash/rc.d"
  printf '%s\n' \
    '# ravn-sessionizer: alias de bash (instalado por ravn-sessionizer-arch).' \
    "alias rs='ravn-sessionizer repos'" \
    "alias ri='ravn-sessionizer issues'" \
    > "${pkgdir}/usr/share/ravn/bash/rc.d/ravn-sessionizer.bash"
}
