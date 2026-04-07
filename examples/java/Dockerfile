FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.26.1@sha256:dc0c94818e271f4d24ffe44b6894989c5d9c9d7302289bb8559f17dac7b1b159 AS agent

FROM eclipse-temurin:25.0.2_10-jdk@sha256:9d5abcd4ccaa86374a7eee9b1c1ebb7beff3b817fca6a6db148ad75473e46df7 AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.2_10-jre@sha256:541cd02a3920c1f10b2f34af7b7144414bc48f0b5dbc933a1def87699e5e5727

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
