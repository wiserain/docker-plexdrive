# docker-plexdrive

Docker image for running [plexdrive](https://github.com/dweidenfeld/plexdrive)
- Ubuntu 18.04
- Plexdrive 5.0.0


## Usage

```yaml
version: '3'

services:
  plexdrive:
    container_name: plexdrive
    image: wiserain/plexdrive:5.0.0-mergerfs
    restart: always
    network_mode: "bridge"
    volumes:
      - ${DOCKER_ROOT}/plexdrive/config:/config
      - /your/mounting/point:/data:shared
      - /local/dir/to/be/merged/with:/local
    privileged: true
    devices:
      - /dev/fuse
    cap_add:
      - MKNOD
      - SYS_ADMIN
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=Asia/Seoul
      - RUN_OPTS=<additional arguments for running plexdrive>
      - PLEXDRIVE_SUB_PATH=<plexdrive sub-path starting with slash>
      - MFS_USER_OPTS=<additional fuse options for mergerfs>
```

First, up and run your container as above. It will be waiting for two plexdrive configuration files to be ready. You can create those files using built-in script by

```bash
docker-compose exec <service_name> plexdrive_setup
```

Once you finish typing your API token, shell stops responding. No worries, it is expected. Simply escape by ```Ctrl+C```, and go to ```/config```. You will find two json files generated. Container running in background proceeds to execute mounting command for plexdrive. You can now access google drive contents via volume-mapped ```/your/mounting/point```.

### [Mergerfs](https://github.com/trapexit/mergerfs)
Along with plexdrive folder, you can specify one local directory to be mergerfs with. Internally, it will have following command

```bash
mergerfs -o uid=${PUID:-911},gid=${PGID:-911},umask=022,allow_other -o ${MFS_USER_OPTS} /local=RW:/plexdrive${PLEXDRIVE_SUB_PATH}=NC /data
```

where the default value of ```MFS_USER_OPTS``` is

```bash
MFS_USER_OPTS="rw,async_read=false,use_ino,allow_other,func.getattr=newest,category.action=all,category.create=ff,cache.files=partial,dropcacheonclose=true"
```
