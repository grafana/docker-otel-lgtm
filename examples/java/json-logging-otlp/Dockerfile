FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.26.1@sha256:625fd29c88ab6e2fa21a071527ba303b8fcddc5db99b2d2d97bbde6909fcd753 AS agent

FROM eclipse-temurin:25.0.2_10-jdk@sha256:b4a48ff72ab09c8ecfc3ae35b3f9b96750437eb436bb1d9dc5cd6e1a885f7511 AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
COPY json-logging-otlp/logback-spring.xml ./src/main/resources/logback-spring.xml
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.2_10-jre@sha256:0d294ec3a725eacae55227affb61509cd3aef6316ce390e5d49b00eab4068e5d

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
