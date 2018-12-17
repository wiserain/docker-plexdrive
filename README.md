# docker-plexdrive

Docker image for running [plexdrive](https://github.com/dweidenfeld/plexdrive)
- Ubuntu 18.04
- Plexdrive 4.0.0
- MongoDB 4.0


## Usage

```yaml
version: '3'

services:
  plexdrive:
    container_name: plexdrive
    image: wiserain/plexdrive:4.0.0
    restart: always
    network_mode: "bridge"
    volumes:
      - ${DOCKER_ROOT}/plexdrive/config:/config
      - ${DOCKER_ROOT}/plexdrive/mongo:/mongo
      - /mnt/plexdrive/chunks:/chunks
      - /mnt/plexdrive/data:/data:shared
    privileged: true
    devices:
      - /dev/fuse
    cap_add:
      - MKNOD
      - SYS_ADMIN
    environment:
      - PUID=<user id>
      - PGID=<group id>
      - RUN_OPTS=<additional arguments for running plexdrive>
```

First, up and run your container as above. It will be waiting for two plexdrive configuration files to be ready. You can create those files using built-in script by

```bash
docker-compose exec <service_name> plexdrive_setup
```

Once you finish typing your API token, shell stops responding. No worries, it is expected. Simply escape by ```Ctrl+C```, and go to ```/config```. You will find two json files generated. Container running in background proceeds to execute mounting command for plexdrive. You can now access google drive contents via volume-mapped ```/mnt/plexdrive/data```.
