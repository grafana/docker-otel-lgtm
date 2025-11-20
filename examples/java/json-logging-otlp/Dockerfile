FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.21.0@sha256:40f0672ae0ba29bf95fd8572343423980b653cfb3595911b5fb1494e4a285986 AS agent

FROM eclipse-temurin:25.0.1_8-jdk@sha256:adc4533ea69967c783ac2327dac7ff548fcf6401a7e595e723b414c0a7920eb2 AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
COPY json-logging-otlp/logback-spring.xml ./src/main/resources/logback-spring.xml
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.1_8-jre@sha256:73fe03b88c2a48ec41f9a86428c65ea5913229488ca218cd6a4f55f8cb0ece1f

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
