FROM ghcr.io/tosainu/archlinux:latest AS prep
RUN \
  pacman-key --init && \
  pacman-key --populate && \
  sed -i 's/^#\(DisableSandbox.*\)/\1/' /etc/pacman.conf && \
  sed -i 's/^DownloadUser/#&/' /etc/pacman.conf && \
  sed -i '/^## Worldwide/,/^$/{ s/^#\(Server\)/\1/ }' /etc/pacman.d/mirrorlist
RUN pacman -Syyu --noconfirm --noprogressbar \
  bison \
  flex \
  gcc \
  make
WORKDIR /build
ARG LINUX_VERSION
ADD https://cdn.kernel.org/pub/linux/kernel/v${LINUX_VERSION%%.*}.x/linux-${LINUX_VERSION%.0}.tar.xz /
RUN tar xf /linux-${LINUX_VERSION%.0}.tar.xz --strip-components=1 -C .


FROM prep AS do-oldconfig
ARG LINUX_VERSION
COPY config .config
RUN make oldconfig


FROM scratch AS oldconfig
ARG LINUX_VERSION
COPY --from=do-oldconfig /linux-${LINUX_VERSION%.0}.tar.xz /
COPY --from=do-oldconfig /build/.config /config
