FROM ubuntu:18.04
LABEL maintainer "wiserain" 

# global environment settings
ENV PLEXDRIVE_VERSION="5.0.0"
ENV PLATFORM_ARCH="amd64"

# s6 environment settings
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_KEEP_ENV=1

ENV LANG=C.UTF-8
ENV MFS_USER_OPTS "rw,async_read=false,use_ino,allow_other,func.getattr=newest,category.action=all,category.create=ff,cache.files=partial,dropcacheonclose=true"

# install packages
RUN \
 echo "**** install runtime packages ****" && \
 apt-get update && \
 apt-get install -y \
 	ca-certificates \
 	fuse \
 	tzdata && \
 update-ca-certificates && \
 apt-get install -y openssl && \
 sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf && \
 echo "**** install build packages ****" && \
 apt-get install -y \
 	curl \
 	unzip \
 	wget && \
 echo "**** add s6 overlay ****" && \
 OVERLAY_VERSION=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') && \
 curl -o /tmp/s6-overlay.tar.gz -L "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-amd64.tar.gz" && \
 tar xfz  /tmp/s6-overlay.tar.gz -C / && \
 echo "**** add plexdrive ****" && \
 cd /tmp && \
 wget https://github.com/dweidenfeld/plexdrive/releases/download/${PLEXDRIVE_VERSION}/plexdrive-linux-${PLATFORM_ARCH} && \
 mv plexdrive-linux-${PLATFORM_ARCH} /usr/bin/plexdrive && \
 chmod 777 /usr/bin/plexdrive && \
 echo "**** add mergerfs ****" && \
 MFS_VERSION=$(curl -sX GET "https://api.github.com/repos/trapexit/mergerfs/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') && \
 cd $(mktemp -d) && wget "https://github.com/trapexit/mergerfs/releases/download/${MFS_VERSION}/mergerfs_${MFS_VERSION}.ubuntu-bionic_amd64.deb" && \
 dpkg -i mergerfs_${MFS_VERSION}.ubuntu-bionic_amd64.deb && \
 echo "**** create abc user ****" && \
 groupmod -g 1000 users && \
 useradd -u 911 -U -d /config -s /bin/false abc && \
 usermod -G users abc && \
 echo "**** cleanup ****" && \
 apt-get purge -y \
 	curl \
 	unzip \
 	wget && \
 apt-get clean autoclean && \
 apt-get autoremove -y && \
 rm -rf /tmp/* /var/lib/{apt,dpkg,cache,log}/

# add local files
COPY root/ /

VOLUME /config /data /plexdrive /local
WORKDIR /data

ENTRYPOINT ["/init"]
