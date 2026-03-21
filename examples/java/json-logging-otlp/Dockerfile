FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.25.0@sha256:33eb9f0e8fb785aab25db41ecfac6a7679d8fafdadfeba2db24f15a56a93e898 AS agent

FROM eclipse-temurin:25.0.2_10-jdk@sha256:bee2e23ab444ed60daf8123e36478bc4a286ba7835bec6f9daf9eba1d50a86a2 AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
COPY json-logging-otlp/logback-spring.xml ./src/main/resources/logback-spring.xml
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.2_10-jre@sha256:ff82c74a630c08b417502c4c18189e62074edbb28eb1f2d31b799ac138c01058

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
