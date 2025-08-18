FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.19.0@sha256:a8258c0539cb825000a83b216052fe272604a7aae0a9fb13b5e70cbe6abbded7 AS agent

FROM eclipse-temurin:21.0.8_9-jdk AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:21.0.8_9-jre

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
