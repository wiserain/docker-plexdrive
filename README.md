# docker-plexdrive

Docker image for running [plexdrive](https://github.com/dweidenfeld/plexdrive)


## Usage

```yaml
version: '3'

services:
  plexdrive:
    container_name: plexdrive
    image: wiserain/plexdrive:unionfs
    restart: always
    network_mode: "bridge"
    volumes:
      - ${DOCKER_ROOT}/plexdrive/config:/config
      - /your/mounting/point:/data:shared
      - /additional/dir/for/unionfs:/ufs
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
      - PLEXDRIVE_SUB_PATH=<plexdrive sub-path starting with slash>
```

First, up and run your container as above. It will be waiting for two plexdrive configuration files to be ready. You can create those files using built-in script by

```bash
docker-compose exec <service_name> plexdrive_setup
```

Once you finish typing your API token, shell stops responding. No worries, it is expected. Simply escape by ```Ctrl+C```, and go to ```/config```. You will find two json files generated. Container running in background proceeds to execute mounting command for plexdrive. You can now access google drive contents via volume-mapped ```/your/mounting/point```.

##### Unionfs
Along with plexdrive folder, you can specify one local directory to be unionfs with. Internally, it will have following command

```bash
unionfs /ufs=RW:/plexdrive${PLEXDRIVE_SUB_PATH}=RO ${ufs_mounts} /data
```
