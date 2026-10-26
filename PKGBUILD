pkgname=ravn-sessionizer
pkgver=0.1.0
pkgrel=1
pkgdesc='Sessionizer para herdr: workspaces, repos, pj-* y agentes en un fzf; tríos desde issues ready-for-agent'
arch=('any')
url='https://github.com/robert-flo/ravn-sessionizer'
license=('MIT')
options=('!debug')
depends=('bash' 'fzf' 'jq' 'github-cli' 'git')
# herdr no está en los repos oficiales (AUR: herdr / herdr-bin, o el instalador
# oficial) y ninguno declara provides=herdr: como depends rompería makepkg -si
# en máquinas con herdr instalado fuera de pacman.
optdepends=(
  'herdr: multiplexor donde corre el plugin (AUR herdr/herdr-bin o instalador oficial)'
  'ravn-trio: lanzar tríos PM/WK/RV desde issues (pj-trio)'
)
makedepends=('make')
backup=('etc/ravn/sessionizer.conf')
source=("${pkgname}-${pkgver}.tar.gz::${url}/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=(
  '2b35521633c5cd88d1e3d61de3c0c6476444fca8fe98a0f9f9ca876ddc72c6a4'
)

package() {
  local source_dir="${srcdir}/${pkgname}-${pkgver}"

  make -C "${source_dir}" DESTDIR="${pkgdir}" install
  install -Dm644 "${source_dir}/sessionizer.conf.example" "${pkgdir}/etc/ravn/sessionizer.conf"
  install -Dm644 "${source_dir}/LICENSE" "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
  install -d "${pkgdir}/usr/share/bash-completion/completions"
  ln -s /usr/share/ravn/sessionizer/runtime/completion/ravn-sessionizer.bash \
    "${pkgdir}/usr/share/bash-completion/completions/ravn-sessionizer"
}
