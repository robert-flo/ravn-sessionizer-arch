# ravn-sessionizer para Arch Linux

Empaquetado Arch (PKGBUILD + validaciones en contenedor) de
[ravn-sessionizer](https://github.com/robert-flo/ravn-sessionizer): el
sessionizer de herdr que junta workspaces, repos, `pj-*` (con sus miembros) y
agentes en un solo fzf, y lanza tríos PM/WK/RV desde issues `ready-for-agent`.

Dúo `ravn-sessionizer` / `ravn-sessionizer-arch`, hecho desde la plantilla
`pj-domina-rf-git-setup-arch` (ver ADR 0001 en el repo de código).

## Qué instala

| Ruta | Qué es |
|------|--------|
| `/usr/share/ravn/sessionizer/` | Plugin de herdr (`herdr-plugin.toml`) + runtime |
| `/usr/bin/ravn-sessionizer` | Symlink al launcher |
| `/etc/ravn/sessionizer.conf` | Config del sistema (`backup`, pacman no la pisa) |
| `/usr/share/bash-completion/completions/ravn-sessionizer` | Completado de bash |

Dependencias: `bash fzf jq github-cli git`. Opcionales: `herdr` y `ravn-trio`.

> **Por qué herdr es opcional:** no está en los repos oficiales; en AUR existen
> `herdr`, `herdr-bin` y `herdr-git`, y ninguno declara `provides=herdr`
> común, además de que podés tenerlo con el instalador oficial. Como `depends`
> rompería `makepkg -si` en esas máquinas. En la práctica lo necesitás.

## Instalar

```bash
git clone https://github.com/robert-flo/ravn-sessionizer-arch.git
cd ravn-sessionizer-arch
makepkg -si            # o: make install
herdr plugin link /usr/share/ravn/sessionizer
```

Agregá los atajos a `~/.config/herdr/config.toml` (están en el README del
repo de código) y recargá con `herdr server reload-config`.

## Validar

```bash
make lint                                          # .SRCINFO, bash -n, shellcheck
make test-release                                  # checksum del tarball publicado (Docker)
make test-local SOURCE_DIR=/ruta/a/ravn-sessionizer  # build + install + help/list en Arch (Docker)
make test SOURCE_DIR=/ruta/a/ravn-sessionizer        # todo lo anterior
```

`test-local` empaqueta el `HEAD` commiteado del código; lo no commiteado no entra.

## Actualizaciones automáticas

`.github/workflows/update-upstream.yml` revisa a diario el último *release*
estable de `robert-flo/ravn-sessionizer` (tags `vN.N.N`), actualiza `pkgver`,
`pkgrel`, el sha256 y `.SRCINFO`, construye el paquete y commitea. Para sacar
una versión nueva: tag + `gh release create` en el repo de código.

## Licencia

MIT, igual que el [proyecto de código](https://github.com/robert-flo/ravn-sessionizer/blob/main/LICENSE).
