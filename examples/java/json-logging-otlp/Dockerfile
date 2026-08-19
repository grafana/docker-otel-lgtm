FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.30.0@sha256:2f72eab291fef045b0e3dc225d9de57d46617af5412b7214802e5dcea833ff59 AS agent

FROM eclipse-temurin:25.0.3_9-jdk@sha256:85765cc23cda09cdfc9af5cbd8dfeb8d4df3e4634a6a89936013962051aa2df8 AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
COPY json-logging-otlp/logback-spring.xml ./src/main/resources/logback-spring.xml
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.3_9-jre@sha256:a214efa3200af4b657e41935799aa12d7aee3336fdb42eb505a0948f6ecdd983

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
