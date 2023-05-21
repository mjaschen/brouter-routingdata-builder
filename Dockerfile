# Step 1: Check out latest BRouter sources

FROM alpine/git as clone

WORKDIR /src

RUN ["git", "clone", "https://github.com/abrensch/brouter.git"]

WORKDIR /src/brouter

# RUN ["git", "checkout", "11a9843f417d231e724058bad41ca6218819b4b1"]

# Step 2: Build BRouter and dependencies (Osmosis, PbfParser)

FROM gradle:7-jdk17 as build

# Same version as in https://github.com/abrensch/brouter/blob/master/build.gradle
# @TODO: parse version from Gradle config and pass as build arg
ARG BROUTER_VERSION=1.7.1-beta-1
ARG OSMOSIS_VERSION=0.48.3

WORKDIR /brouter

COPY --from=clone /src/brouter /brouter-build

WORKDIR /brouter-build

RUN ["gradle", "clean", "build", "fatJar"]

RUN apt-get update \
    && apt-get install -y ca-certificates curl \
    && mkdir -p /osmosis-src \
    && curl --location --output /osmosis-src/osmosis-${OSMOSIS_VERSION}.tgz https://github.com/openstreetmap/osmosis/releases/download/${OSMOSIS_VERSION}/osmosis-${OSMOSIS_VERSION}.tgz \
    && tar -xvzf /osmosis-src/osmosis-${OSMOSIS_VERSION}.tgz -C /osmosis-src

# Step 3: Collect needed tools + JARs + processing script and run script

FROM eclipse-temurin:17-jdk-jammy

# Same version as in https://github.com/abrensch/brouter/blob/master/build.gradle
# @TODO: parse version from Gradle config and pass as build arg
ARG BROUTER_VERSION=1.7.1-beta-1
ARG OSMOSIS_VERSION=0.48.3

RUN apt-get update \
    && apt-get install -y apt-utils osmctools

COPY --from=clone /src/brouter /brouter-source

WORKDIR /brouter

RUN cp -Rv /brouter-source/misc/profiles2/* /brouter/
COPY --from=build /brouter-build/brouter-server/build/libs/brouter-${BROUTER_VERSION}-all.jar brouter.jar

COPY create-routing-data.sh /brouter/create-routing-data.sh

VOLUME ["/brouter-tmp"]
VOLUME ["/planet"]
VOLUME ["/srtm"]
VOLUME ["/segments"]

ENTRYPOINT ["/bin/bash", "/brouter/create-routing-data.sh"]
