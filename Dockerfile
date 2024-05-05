# Step 1: Check out latest BRouter sources

FROM alpine/git as clone

ARG BROUTER_VERSION=master

WORKDIR /src

RUN ["git", "clone", "--depth", "1", "https://github.com/abrensch/brouter.git"]

WORKDIR /src/brouter

RUN git checkout "$BROUTER_VERSION"

RUN ["echo", "BRouter commit:"]
RUN ["git", "log", "-n", "1", "--pretty=format:%H"]

RUN ["echo", "lookups.dat version:"]
RUN ["head", "-n2", "/src/brouter/misc/profiles2/lookups.dat"]

# Step 2: Build BRouter and dependencies

FROM gradle:7-jdk17 as build

WORKDIR /brouter

COPY --from=clone /src/brouter /brouter-build

WORKDIR /brouter-build

RUN ["gradle", "clean", "build", "fatJar"]

# Step 3: Collect needed tools + JARs + processing script and run script

FROM eclipse-temurin:17-jdk-jammy

RUN apt-get update \
    && apt-get install -y apt-utils osmctools

WORKDIR /brouter

COPY --from=clone /src/brouter/misc/profiles2/* /brouter/
COPY --from=build /brouter-build/brouter-server/build/libs/brouter-*-all.jar brouter.jar

COPY create-routing-data.sh /brouter/create-routing-data.sh

VOLUME ["/brouter-tmp", "/planet", "/srtm", "/segments"]

ENTRYPOINT ["/bin/bash", "/brouter/create-routing-data.sh"]
