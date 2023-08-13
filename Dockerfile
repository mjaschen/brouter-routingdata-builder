# Step 1: Check out latest BRouter sources

FROM alpine/git as clone

WORKDIR /src

RUN ["git", "clone", "https://github.com/abrensch/brouter.git"]

WORKDIR /src/brouter

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

COPY --from=clone /src/brouter /brouter-source

WORKDIR /brouter

RUN cp -Rv /brouter-source/misc/profiles2/* /brouter/
COPY --from=build /brouter-build/brouter-server/build/libs/brouter-*-all.jar brouter.jar

COPY create-routing-data.sh /brouter/create-routing-data.sh

VOLUME ["/brouter-tmp"]
VOLUME ["/planet"]
VOLUME ["/srtm"]
VOLUME ["/segments"]

ENTRYPOINT ["/bin/bash", "/brouter/create-routing-data.sh"]
