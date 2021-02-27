# Step 1: Build BRouter and dependencies (Osmosis, PbfParser)

FROM maven:3-jdk-11 as build

RUN git clone https://github.com/abrensch/brouter.git /brouter-build

WORKDIR /brouter-build

RUN mvn package -q -pl brouter-server -am -Dmaven.javadoc.skip=true

RUN apt-get update \
    && apt-get install -y ca-certificates curl \
    && mkdir -p /osmosis-src \
    && curl --location --output /osmosis-src/osmosis-0.48.3.tgz https://github.com/openstreetmap/osmosis/releases/download/0.48.3/osmosis-0.48.3.tgz \
    && tar -xvzf /osmosis-src/osmosis-0.48.3.tgz -C /osmosis-src

WORKDIR /brouter-build/misc/pbfparser

RUN javac -d . -cp "/brouter-build/brouter-server/target/brouter-server-1.6.1-jar-with-dependencies.jar:/osmosis-src/lib/default/protobuf-java-3.12.2.jar:/osmosis-src/lib/default/osmosis-osm-binary-0.48.3.jar" *.java \
    && jar cf pbfparser.jar btools/**/*.class

# Step 2: Collect needed tools + JARs + processing script and run script

FROM openjdk:17-jdk-buster

RUN apt-get update \
    && apt-get install -y osmctools

RUN git clone https://github.com/abrensch/brouter.git /brouter-source

WORKDIR /brouter

RUN cp -Rv /brouter-source/misc/profiles2/* /brouter/
RUN cp -Rv /brouter-source/misc/pbfparser /brouter/pbfparser
COPY --from=build /brouter-build/brouter-server/target/brouter-server-1.6.1-jar-with-dependencies.jar brouter.jar
COPY --from=build /osmosis-src/lib/default/protobuf-java-3.12.2.jar /brouter/pbfparser/protobuf.jar
COPY --from=build /osmosis-src/lib/default/osmosis-osm-binary-0.48.3.jar /brouter/pbfparser/osmosis.jar
COPY --from=build /brouter-build/misc/pbfparser/pbfparser.jar /brouter/pbfparser/pbfparser.jar

COPY create-routing-data.sh /brouter/create-routing-data.sh

VOLUME ["/brouter-tmp"]
VOLUME ["/planet"]
VOLUME ["/srtm"]
VOLUME ["/segments"]

ENTRYPOINT ["/bin/bash", "/brouter/create-routing-data.sh"]
