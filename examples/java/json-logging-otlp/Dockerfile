FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.22.0@sha256:df7cae821770cadb6dbe7e36681008c8e9dff71bc5f5c8deb0d8422b541592c5 AS agent

FROM eclipse-temurin:25.0.1_8-jdk@sha256:10331564d9ae41b6a534ddea472f37270a3c286e89857261631a0d772a4d8617 AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
COPY json-logging-otlp/logback-spring.xml ./src/main/resources/logback-spring.xml
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.1_8-jre@sha256:9d1d3068b16f2c4127be238ca06439012ff14a8fdf38f8f62472160f9058464a

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
