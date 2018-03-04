# docker-plexdrive

Docker image for running [plexdrive](https://github.com/dweidenfeld/plexdrive)


## Usage

```yaml
version: '2'

services:
  plexdrive:
    container_name: plexdrive
    image: wiserain/plexdrive
    restart: always
    network_mode: "bridge"
    volumes:
      - ${DOCKER_ROOT}/plexdrive/config:/config
      - /your/mounting/point:/data:shared
    privileged: true
    devices:
      - /dev/fuse
    cap_add:
      - MKNOD
      - SYS_ADMIN
    environment:
      - PUID=<user id>
      - PGID=<group id>
      - RUN_OPTS=<additional running arguments for plexdrive>
```
