FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.20.1@sha256:1dca1ec184073a26408b023dc10fdbd60e14ab2f648748b55edc175c297a5d4d AS agent

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
