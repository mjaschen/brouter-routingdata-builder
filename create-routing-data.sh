#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

export PATH=/osmctools:$PATH

# Set to 0 to skip updating the planet file
PLANET_UPDATE=${PLANET_UPDATE:-1}
JAVA_OPTS="${JAVA_OPTS:--Xmx6144M -Xms6144M -Xmn256M}"

if [[ "" == "${PLANET:-}" ]]; then
    echo "'PLANET' environment variable must be set."
    exit 1
fi

PLANET_SOURCE="/planet/$PLANET"

if [[ ! -f "$PLANET_SOURCE" ]]; then
    echo "Planet file not found: $PLANET_SOURCE"
    exit 2
fi

# add an additional sub-directory to prevent accidentally deleting stuff
# for the case that a non-empty directory was mounted into the container
TEMP_BASE="/brouter-tmp/tmp"

if [[ "$PLANET_UPDATE" = "1" ]]; then
    echo "$(date) Updating Planet file ..."
    rm -vf "/planet/$PLANET.old.osm.pbf"
    rm -vf "/planet/$PLANET.new.osm.pbf"
    touch /planet/mapsnapshottime.txt
    mkdir -p /brouter-tmp/osmupdate
    /usr/bin/osmupdate \
        --verbose \
        --drop-author \
        --compression-level=1 \
        --tempfiles="/brouter-tmp/osmupdate/" \
        "/planet/$PLANET" \
        "/planet/$PLANET.new.osm.pbf" \
        || { echo "Updating Planet failed" ; exit 2 ; }
    PLANET_SOURCE="/planet/$PLANET.new.osm.pbf"
else
    echo "$(date) Using Planet file without updating: $PLANET_SOURCE"
    touch -r "$PLANET_SOURCE" /planet/mapsnapshottime.txt
fi

[[ -d "$TEMP_BASE" ]] && rm -rf "$TEMP_BASE"

mkdir -v "$TEMP_BASE"
cd "$TEMP_BASE"
mkdir -v nodetiles
mkdir -v waytiles
mkdir -v waytiles55
mkdir -v nodes55

echo "$(date) Running OsmFastCutter ..."

java $JAVA_OPTS \
    -cp /brouter/brouter.jar \
    -DavoidMapPolling=true \
    -Ddeletetmpfiles=false \
    -DuseDenseMaps=true \
    btools.mapcreator.OsmFastCutter \
    /brouter/lookups.dat \
    nodetiles \
    waytiles \
    nodes55 \
    waytiles55 \
    bordernids.dat \
    relations.dat \
    restrictions.dat \
    /brouter/all.brf \
    /brouter/trekking.brf \
    /brouter/softaccess.brf \
    "$PLANET_SOURCE"

if [[ "$PLANET_UPDATE" = "1" ]]; then
    mv "/planet/$PLANET" "/planet/$PLANET.old.osm.pbf"
    mv "/planet/$PLANET.new.osm.pbf" "/planet/$PLANET"
fi

echo "$(date) Running PosUnifier ..."

mkdir unodes55
java $JAVA_OPTS \
    -cp /brouter/brouter.jar \
    -Ddeletetmpfiles=true \
    -DuseDenseMaps=true \
    btools.mapcreator.PosUnifier \
    nodes55 \
    unodes55 \
    bordernids.dat \
    bordernodes.dat \
    /srtm1 \
    /srtm3

echo "$(date) Running WayLinker ..."

java $JAVA_OPTS \
    -cp /brouter/brouter.jar \
    -DuseDenseMaps=true \
    -DskipEncodingCheck=true \
    btools.mapcreator.WayLinker \
    unodes55 \
    waytiles55 \
    bordernodes.dat \
    restrictions.dat \
    /brouter/lookups.dat \
    /brouter/all.brf \
    /segments \
    rd5

if [[ -f /planet/mapsnapshottime.txt ]]; then
    touch -r /planet/mapsnapshottime.txt /segments/*.rd5
fi

echo "$(date) Finished."
