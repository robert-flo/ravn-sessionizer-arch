pkgname=ravn-sessionizer
pkgver=0.2.0
pkgrel=1
pkgdesc='Sessionizer para herdr: workspaces, repos, pj-* y agentes en un fzf; tríos desde los issues de todos los proyectos'
arch=('any')
url='https://github.com/robert-flo/ravn-sessionizer'
license=('MIT')
options=('!debug')
depends=('bash' 'fzf' 'jq' 'github-cli' 'git' 'herdr>=0.9.5' 'ravn-trio')
# herdr y ravn-trio los sirve omarchy-personal-repo (robert-flo/omarchy-pkgs).
optdepends=('try: clonar con try exec … clone los repos que falten (SES_CLONE_CMD)')
makedepends=('make')
backup=('etc/ravn/sessionizer.conf')
# Fuente privada: tarball vendoreado (git archive --prefix=${pkgname}-${pkgver}/
# v${pkgver} | gzip -n), así makepkg no necesita credenciales de GitHub.
source=("${pkgname}-${pkgver}.tar.gz")
sha256sums=(
  'dbe7fe73b4b23f5d16f921f8e409d5173acb75d6052977ae3bf36c4b38c341e0'
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
