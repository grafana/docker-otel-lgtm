FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.25.0@sha256:33eb9f0e8fb785aab25db41ecfac6a7679d8fafdadfeba2db24f15a56a93e898 AS agent

FROM eclipse-temurin:25.0.2_10-jdk@sha256:bee2e23ab444ed60daf8123e36478bc4a286ba7835bec6f9daf9eba1d50a86a2 AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
COPY json-logging-otlp/logback-spring.xml ./src/main/resources/logback-spring.xml
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.2_10-jre@sha256:a9980cb3777d2b7b0d513800c3debc034c101530b96db4aadccb845f867fca9e

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
