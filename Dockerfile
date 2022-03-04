FROM ubuntu:20.04 AS base
FROM base AS builder

ARG TARGETARCH
ARG PLEXDRIVE_VERSION="5.2.1"

ARG DEBIAN_FRONTEND="noninteractive"
ARG OVERLAY_VERSION=v2.2.0.3

# build artifacts root
RUN mkdir -p /bar

RUN \
  echo "**** install build packages ****" && \
  apt-get update && \
  apt-get install -yq --no-install-recommends \
    ca-certificates \
    curl

RUN \
  echo "**** add s6 overlay ****" && \
  OVERLAY_ARCH=$(if [ "$TARGETARCH" = "arm64" ]; then echo "aarch64"; elif [ "$TARGETARCH" = "arm" ]; then echo "armhf"; else echo "$TARGETARCH"; fi) && \
  curl -o /tmp/s6-overlay.tar.gz -L "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.gz" && \
  tar xzf /tmp/s6-overlay.tar.gz -C /bar/ --exclude='./bin' && \
  tar xzf /tmp/s6-overlay.tar.gz -C /bar/usr ./bin

RUN \
  echo "**** add plexdrive ****" && \
  mkdir -p /bar/usr/local/bin && \
  PLEXDRIVE_ARCH=$(if [ "$TARGETARCH" = "arm" ]; then echo "arm7"; else echo "$TARGETARCH"; fi) && \
  curl -o /bar/usr/local/bin/plexdrive -LJ https://github.com/plexdrive/plexdrive/releases/download/${PLEXDRIVE_VERSION}/plexdrive-linux-${PLEXDRIVE_ARCH}

# add local files
COPY root/ /bar/

ADD https://raw.githubusercontent.com/by275/docker-scripts/master/root/etc/cont-init.d/20-install-pkg /bar/etc/cont-init.d/20-install-pkg
ADD https://raw.githubusercontent.com/by275/docker-scripts/master/root/etc/cont-init.d/30-wait-for-mnt /bar/etc/cont-init.d/30-wait-for-mnt

# 
# release
# 
FROM base
LABEL maintainer="wiserain"
LABEL org.opencontainers.image.source https://github.com/wiserain/docker-plexdrive

ARG DEBIAN_FRONTEND="noninteractive"
ARG APT_MIRROR="archive.ubuntu.com"

# add build artifacts
COPY --from=builder /bar/ /

# install packages
RUN \
  echo "**** apt source change for local build ****" && \
  sed -i "s/archive.ubuntu.com/$APT_MIRROR/g" /etc/apt/sources.list && \
  echo "**** install runtime packages ****" && \
  apt-get update && \
  apt-get install -yqq --no-install-recommends apt-utils && \
  apt-get install -yqq --no-install-recommends \
    ca-certificates \
    fuse \
    openssl \
    tzdata \
    unionfs-fuse \
    wget && \
  update-ca-certificates && \
  sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf && \
  echo "**** add mergerfs ****" && \
  MFS_VERSION=$(wget --no-check-certificate -O - -o /dev/null "https://api.github.com/repos/trapexit/mergerfs/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') && \
  MFS_DEB="mergerfs_${MFS_VERSION}.ubuntu-focal_$(dpkg --print-architecture).deb" && \
  cd $(mktemp -d) && wget --no-check-certificate "https://github.com/trapexit/mergerfs/releases/download/${MFS_VERSION}/${MFS_DEB}" && \
  dpkg -i ${MFS_DEB} && \
  echo "**** create abc user ****" && \
  useradd -u 911 -U -d /config -s /bin/false abc && \
  usermod -G users abc && \
  echo "**** permissions ****" && \
  chmod a+x /usr/local/bin/* && \
  echo "**** cleanup ****" && \
  apt-get clean autoclean && \
  apt-get autoremove -y && \
  rm -rf /tmp/* /var/lib/{apt,dpkg,cache,log}/

# environment settings
ENV \
  S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
  S6_KILL_FINISH_MAXTIME=7000 \
  S6_SERVICES_GRACETIM=5000 \
  S6_KILL_GRACETIME=5000 \
  LANG=C.UTF-8 \
  PS1="\u@\h:\w\\$ " \
  UFS_USER_OPTS="cow,direct_io,nonempty,auto_cache,sync_read" \
  MFS_USER_OPTS="rw,use_ino,func.getattr=newest,category.action=all,category.create=ff,cache.files=auto-full,dropcacheonclose=true"

VOLUME /config /cache /cloud /data /local
WORKDIR /data

HEALTHCHECK --interval=30s --timeout=30s --start-period=10s --retries=3 \
  CMD /usr/local/bin/healthcheck

ENTRYPOINT ["/init"]
