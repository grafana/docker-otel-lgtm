FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.27.0@sha256:6d263ee46a3faace8950aec57ad4fd03b70a84169908e5f26eb1e42d92a0a441 AS agent

FROM eclipse-temurin:25.0.3_9-jdk@sha256:e23592541431eaeef5c13c84c21db71f97cdca0e70181ea6222ec9bccac24f6c AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.3_9-jre@sha256:671061ae5a8f0d6827816e15bc39d21e224c43ff96998a97cd0d3989c4d17815

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
