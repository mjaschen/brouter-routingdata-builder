# BRouter Routing Data Builder

[![ci](https://github.com/mjaschen/brouter-routingdata-builder/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mjaschen/brouter-routingdata-builder/actions/workflows/ci.yml)

This Docker image allows to build the routing data files (`.rd5`) for BRouter.

## Building Routing Data

Building the routing data for the first time consists of four steps:

1. Pull the Docker image
2. Download a planet file
3. Download SRTM data
4. Build the routing data

For all subsequent builds running the last step is sufficient, as the planet data is updated automatically to the latest version in the build process and SRTM data doesn't change at all.

## Pull the Docker image:

```shell
docker pull mjaschen/brouter-routingdata-builder
```

or

```shell
docker pull ghcr.io/mjaschen/brouter-routingdata-builder
```

## Downloading a Planet File

[Planet OSM](https://planet.openstreetmap.org/) is the canonical source of planet files for the whole world. For building global routing data, download the *Latest Weekly Planet File* **in PBF format**. Warning: the planet file has a size of roughly 61 GiB (November 2021).

For smaller regions and/or testing purposes, a smaller extract of the planet can be used, e.g. for Europe, a single country or an even smaller region. Geofabrik offers [extracts for all regions and countries](https://download.geofabrik.de/index.html). Download a file in **.osm.pbf** format.

Another option for getting custom planet files, especially for very small extracts (town and city level, smaller regions) is the [BBBike Extract Service](https://extract.bbbike.org/). Choose *Protocolbuffer (PBF)* as format here.

Store the downloaded planet file into a directory on the host system.

## Downloading SRTM Elevation Data

SRTM data can be downloaded here: <http://srtm.csi.cgiar.org/srtmdata/>

Just select the wanted tiles and put them into a directory. Needed format:

- Tile size: 5 deg x 5 deg
- Format: “Esri ASCII”

It's also possible to download the whole set at <https://drive.google.com/folderview?id=0B_J08t5spvd8RWRmYmtFa2puZEE&usp=drive_web#list>. Unpack the archive and mount the directory `SRTMv4.1/5_5x5_ascii` into the container.

## Building the Routing Data

``` shell
docker run --rm \
    --user "$(id -u):$(id -g)"
    --env PLANET=slovenia-latest.osm.pbf \
    --env JAVA_OPTS="-Xmx2048M -Xms2048M -Xmn256M" \
    --volume /tank/brouter/tmp:/brouter-tmp \
    --volume /tank/brouter/planet:/planet \
    --volume /tank/brouter/srtm:/srtm:ro \
    --volume /tank/brouter/segments:/segments \
    mjaschen/brouter-routingdata-builder
```

Let's take a closer look on what happens here:

- `--rm` delete the container after the processing is done
- `--user "$(id -u):$(id -g)"`: the processing script can and should be run as a non-privileged user, the user ID and group ID for that user can be provided with the `--user` option; in the example the current user ID and its primary group ID is used. Ensure that the mounted directories (`tmp`, `planet`, `segments`) are writable by the given user.
- `--env PLANET=slovenia-latest.osm.pbf`: the downloaded planet file is located in `/tank/brouter/planet/` (see the step further down where that directory is mounted into the container) and its name is `slovenia-latest.osm.pbf` (**important:** the planet file *must* be located in the directory which is mounted at `/planet` in the container; that means for this example that `/tank/brouter/planet/slovenia-latest.osm.pbf` must exist)
- `--env JAVA_OPTS="-Xmx2048M -Xms2048M -Xmn256M"`: the memory related options for the Java VM should be set according to the specs of the docker container; the example shows values for smaller planet files – when processing larger regions (europe, world, …) the memory requirements are higher (the default value is `-Xmx6144M -Xms6144M -Xmn256M`)
- `--volume /tank/brouter/tmp:/brouter-tmp`: the process of creating the routing data uses a lot of temporary files which are written in this mounted directory
- `--volume /tank/brouter/planet:/planet`: the directory where the planet file is located; write access is needed because the planet file will be updated by the processing script before the routing data is created
- `--volume /tank/brouter/srtm:/srtm:ro`: the directory where the SRTM data is located, either in zipped ASCII format (`*.zip`) or in BEF (`*.bef`) format; it's mounted read-only as there are no changes applied to the SRTM data
- `--volume /tank/brouter/segments:/segments`: that's the target directory where the created routing data files (.rd5) will be stored

If updating the planet file isn't desired, just provide `--env PLANET_UPDATE=0` as option. In this case the directory which contains the planet file can be mounted read-only.


## Benchmarks

Updating the planet file and building routing data for the whole world takes several hours depending on the available system ressources:

|Build Time|CPU|RAM|Disk|OS|Remarks|
|---------:|---|--:|--|-------|
| 3:45 h   | Xeon E3-1270 v3 @ 3.50GHz (8 cores) | 32 GiB | 4x HGST HUH721010ALE600 10 TB, ZFS RAID-Z | Linux | `JAVA_OPTS=-Xmx15360M -Xms15360M -Xmn512M` |
| 2:49 h   | AMD Ryzen 9 5950X (16 cores) | 128 GiB | 2x SAMSUNG MZQLB3T8HALS-00007 4 TB NVME, RAID 1 | Linux | `JAVA_OPTS="-Xmx30720M -Xms30720M -Xmn1024M"` |

## Development

### Building the Docker Image

```shell
docker build --pull -t brouter-routingdata-builder .
```

The image is built automatically with Github Actions when either a tag or the *main* branch is pushed. After a successful build the image is deployed to [Github Container Registry](https://github.com/users/mjaschen/packages/container/package/brouter-routingdata-builder) and [Docker Hub](https://hub.docker.com/r/mjaschen/brouter-routingdata-builder).
