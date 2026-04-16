FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.26.1@sha256:b45c2b04e690e1146740863bacd6fb2197f820f5147d0ed27a69d718543994c1 AS agent

FROM eclipse-temurin:25.0.2_10-jdk@sha256:c7cf8f103714da175842713f705e2a70551daa74f7b5cb47f40059553e6b9cde AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
COPY json-logging-otlp/logback-spring.xml ./src/main/resources/logback-spring.xml
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.2_10-jre@sha256:400bd31bd17a97d3cfba314d77f7b2035936a18d454bcfec7d5d21850e00b8e3

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
