FROM alpine:latest
MAINTAINER bass_rock <bass_rock@icloud.com>

# global environment settings
ENV PLEXDRIVE_VERSION="5.0.0"
ENV PLATFORM_ARCH="amd64"

# s6 environment settings
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_KEEP_ENV=1

# install packages
RUN \
 apk update && \
 apk add --no-cache \
 ca-certificates \
 fuse && \
 sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf

# install build packages
RUN \
 apk add --no-cache --virtual=build-dependencies \
 wget \
 curl \
 unzip && \

# add s6 overlay
 OVERLAY_VERSION=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]') && \
 curl -o \
 /tmp/s6-overlay.tar.gz -L \
	"https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${PLATFORM_ARCH}.tar.gz" && \
 tar xfz \
	/tmp/s6-overlay.tar.gz -C / && \

 cd tmp && \
 wget https://github.com/dweidenfeld/plexdrive/releases/download/${PLEXDRIVE_VERSION}/plexdrive-linux-${PLATFORM_ARCH} && \
 mv plexdrive-linux-${PLATFORM_ARCH} /usr/bin/plexdrive && \

 apk add --no-cache --repository http://nl.alpinelinux.org/alpine/edge/community \
	shadow && \

# cleanup
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/tmp/* \
	/var/tmp/* \
	/var/cache/apk/*

# create abc user
RUN \
	groupmod -g 1000 users && \
	useradd -u 911 -U -d /config -s /bin/false abc && \
	usermod -G users abc && \

# create some files / folders
	mkdir -p /config /data

# add local files
COPY root/ /

VOLUME ["/config"]

ENTRYPOINT ["/init"]