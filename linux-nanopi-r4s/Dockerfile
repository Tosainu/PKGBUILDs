FROM ghcr.io/tosainu/alarm-makepkg:latest AS prep
ARG LINUX_VERSION
WORKDIR /build
ADD --chown=alarm:alarm https://cdn.kernel.org/pub/linux/kernel/v${LINUX_VERSION%%.*}.x/linux-${LINUX_VERSION%.0}.tar.xz /
RUN tar xf /linux-${LINUX_VERSION%.0}.tar.xz --strip-components=1 -C .


FROM prep AS do-oldconfig
ARG LINUX_VERSION
COPY core/linux-aarch64/config .config
RUN make oldconfig


FROM scratch AS oldconfig
ARG LINUX_VERSION
COPY --from=do-oldconfig /linux-${LINUX_VERSION%.0}.tar.xz /
COPY --from=do-oldconfig /build/.config /config
