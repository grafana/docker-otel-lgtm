FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.22.0@sha256:df7cae821770cadb6dbe7e36681008c8e9dff71bc5f5c8deb0d8422b541592c5 AS agent

FROM eclipse-temurin:25.0.1_8-jdk@sha256:73e5bce2b6ff85ea4539923d017d56e5239a10f3cbb29a6fe8125595f2a01f79 AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.1_8-jre@sha256:f6b092537e68d9836e86f676344e94102f2be325bbc652133cd9ef85b27d3ea9

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
