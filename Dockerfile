FROM ghcr.io/tosainu/alarm-makepkg:latest AS builder
USER root
RUN <<EOS
  pacman-key --init
  pacman-key --populate archlinux
  pacman-key --populate archlinuxarm
  pacman-key --lsign-key 68B3537F39A313B3E574D06777193F152BDBE6A6 # Arch Linux ARM Build System <builder@archlinuxarm.org>
  sed -i 's/^#\(DisableSandbox.*\)/\1/' /etc/pacman.conf
  sed -i 's/^#\?\(MAKEFLAGS=\).*$/\1"-j6"/' /etc/makepkg.conf
  sed -i '/^PKGEXT=/s/xz/zst/' /etc/makepkg.conf
  sed -i -n '/^### United States/,/^$/ s/#\s*Server/Server/p' /etc/pacman.d/mirrorlist
EOS
RUN pacman -Syyu --noconfirm --noprogressbar
RUN \
  mkdir -p /work/{build,pkg,pkgbuild,src} && \
  chown -R alarm:alarm /work
USER alarm
WORKDIR /work/pkgbuild


FROM builder AS makepkg
ARG PKGBUILD_DIR
ARG GPG_LOCATE_KEYS
RUN --mount=type=bind,source=$PKGBUILD_DIR,target=/work/pkgbuild \
  if [ -n "$GPG_LOCATE_KEYS" ]; then \
    gpg --locate-keys $GPG_LOCATE_KEYS; \
  fi && \
  BUILDDIR=/work/build \
  PKGDEST=/work/pkg \
  SRCDEST=/work/src \
  makepkg -s --noconfirm --noprogressbar


FROM scratch AS pkgs
COPY --from=makepkg /work/pkg /


FROM builder AS repo-add
ARG REPO_NAME
COPY --from=pkgs / .
RUN repo-add "$REPO_NAME.db.tar.gz" *.pkg.tar.*


FROM scratch AS repo
COPY --from=repo-add /work/pkgbuild /
