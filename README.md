# docker-plexdrive

Docker image for [plexdrive](https://github.com/plexdrive/plexdrive) mount

- Ubuntu 20.04
- pooling filesystem (a choice of mergerfs or unionfs)

## Usage

```yaml
version: '3'

services:
  plexdrive:
    container_name: plexdrive
    image: wiserain/plexdrive:latest
    restart: always
    network_mode: "bridge"
    volumes:
      - ${DOCKER_ROOT}/plexdrive/config:/config
      - ${DOCKER_ROOT}/plexdrive/cache:/cache   # Optional: prepared for --chunk-file
      - /your/mounting/point:/data:shared
      - /local/dir/to/be/merged/with:/local     # Optional: if you have a folder to be mergerfs/unionfs with
    devices:
      - /dev/fuse
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
```

equivalently,

```bash
docker run -d \
    --name=plexdrive \
    --cap-add SYS_ADMIN \
    --device /dev/fuse \
    --security-opt apparmor=unconfined \
    -v ${DOCKER_ROOT}/plexdrive/config:/config \
    -v ${DOCKER_ROOT}/plexdrive/cache:/cache \
    -v /your/mounting/point:/data:shared \
    -v /local/dir/to/be/merged/with:/local \
    -e PUID=${PUID} \
    -e PGID=${PGID} \
    -e TZ=${TZ} \
    wiserain/plexdrive:latest
```

First, up and run your container as above. It will be waiting for two plexdrive configuration files to be ready. You can create those files using built-in script by

```bash
docker-compose exec <service_name> plexdrive_setup
```

Once you finish typing your API token, shell stops responding. No worries, it is expected. Simply escape by ```Ctrl+C```, and go to ```/config```. You will find two json files generated. Container running in background will proceed to execute mounting command for plexdrive. You can now access google drive contents via volume-mapped ```/your/mounting/point```.

### plexdrive mount

Here is the internal command for plexdrive mount.

```bash
plexdrive mount ${plexdrive_mountpoint:-/data} \
    --config /config/ \
    --uid=${PUID:-911} \
    --gid=${PGID:-911} \
    --umask=0100775 \
    -o allow_other \
    ${PLEXDRIVE_OPTS}
```

Please not that variables with capital letters are only configurable by the container environment variable.

| ENV  | Description  | Default  |
|---|---|---|
| ```PUID``` / ```PGID```  | uid and gid for running an app  | ```911``` / ```911```  |
| ```TZ```  | timezone, required for correct timestamp in log  |   |
| ```PLEXDRIVE_OPTS```  | additioanl arguments which will be appended to the basic options  |   |

By default, ```plexdrive_mountpoint``` is ```/data``` but fallbacks to ```/cloud``` if your container has bind-mount at ```/local``` and so that can be pooled in the following process.

## [mergerfs](https://github.com/trapexit/mergerfs) or unionfs (optional)

Along with the plexdrive folder, you can specify one local directory to be mergerfs with by ```POOLING_FS=mergerfs```. Internally, it will execute a following command

```bash
mergerfs \
    -o uid=${PUID:-911},gid=${PGID:-911},umask=022,allow_other \
    -o ${MFS_USER_OPTS} \
    /local=RW:/cloud${PLEXDRIVE_PATH}=NC /data
```

where a default value of ```MFS_USER_OPTS``` is

```bash
MFS_USER_OPTS="rw,use_ino,func.getattr=newest,category.action=all,category.create=ff,cache.files=auto-full,dropcacheonclose=true"
```

If you want unionfs instead of mergerfs, set ```POOLING_FS=unionfs```, which will apply

```bash
unionfs \
    -o uid=${PUID:-911},gid=${PGID:-911},umask=022,allow_other \
    -o ${UFS_USER_OPTS} \
    /local=RW:/cloud${PLEXDRIVE_PATH}=RO /data
```

where a default value of ```UFS_USER_OPTS``` is

```bash
UFS_USER_OPTS="cow,direct_io,nonempty,auto_cache,sync_read"
```

You can pool a sub-dir of plexdrive by ```PLEXDRIVE_PATH```. Make sure to start the path with ```/```.
