FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.25.0@sha256:33eb9f0e8fb785aab25db41ecfac6a7679d8fafdadfeba2db24f15a56a93e898 AS agent

FROM eclipse-temurin:25.0.2_10-jdk@sha256:dd23c917b42d5ba34b726c3b339ba0f71fac76a8bdebb936b511bb98832dc287 AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
COPY json-logging-otlp/logback-spring.xml ./src/main/resources/logback-spring.xml
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.2_10-jre@sha256:0a9c973778b03b88f39ccae4f8cc26022d84a3237a818cb98770369eb6c5daf9

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
