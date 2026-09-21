FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.30.0@sha256:413b947eeeab911d982d12939485e34bc974eaea25c35c903017908ea73ce52b AS agent

FROM eclipse-temurin:25.0.4_7-jdk@sha256:97014c4b396021f9ddb7d592a7dbedb0c4e4215c29e03dc01c393558aefb71c2 AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
COPY json-logging-otlp/logback-spring.xml ./src/main/resources/logback-spring.xml
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.4_7-jre@sha256:15090d159279e5c158473eccb48cd87f57b3e3a47511a797eb5a7a7ea6f86b0f

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
