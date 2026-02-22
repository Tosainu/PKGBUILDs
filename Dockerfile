FROM ghcr.io/tosainu/archlinux:latest AS builder
RUN \
  pacman-key --init && \
  pacman-key --populate && \
  sed -i 's/^#\(DisableSandbox.*\)/\1/' /etc/pacman.conf && \
  sed -i 's/^DownloadUser/#&/' /etc/pacman.conf && \
  sed -i 's/^#\?\(MAKEFLAGS=\).*$/\1"-j6"/' /etc/makepkg.conf && \
  sed -i '/^PKGEXT=/s/xz/zst/' /etc/makepkg.conf && \
  sed -i '/^## Worldwide/,/^$/{ s/^#\(Server\)/\1/ }' /etc/pacman.d/mirrorlist && \
  pacman -Syyu --noconfirm --noprogressbar base-devel && \
  useradd -m -U builder && \
  echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
  mkdir -p /work/{build,pkg,pkgbuild,src} && \
  chown -R builder:builder /work
USER builder
WORKDIR /work/pkgbuild


FROM builder AS makepkg
ARG PACKAGER
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
RUN \
  --mount=type=secret,id=GPG_KEY_FILE,required=false,target=/key,mode=0444 \
  --mount=type=secret,id=GPG_KEY_ID,required=false,env=GPG_KEY_ID,mode=0444 \
  --mount=type=tmpfs,target=/gpg-home \
  --network=none <<EOS
set -e
if [ -f /key ] && [ -n "$GPG_KEY_ID" ]; then
  export GNUPGHOME=/gpg-home
  gpg --import /key
  echo -e '5\ny\n' | gpg --command-fd 0 --no-tty --no-greeting --edit-key "$GPG_KEY_ID" trust
  find -type f -exec gpg --output {}.sig --detach-sig {} \; -exec repo-add --include-sigs --sign "$REPO_NAME.db.tar.zst" {} +
else
  find -type f -exec repo-add "$REPO_NAME.db.tar.zst" {} +
fi
EOS


FROM scratch AS repo
COPY --from=repo-add /work/pkgbuild /
