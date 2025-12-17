FROM eclipse-temurin:25.0.1_8-jdk@sha256:572fe7b5b3ca8beb3b3aca96a7a88f1f7bc98a3bdffd03784a4568962c1a963a AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
COPY json-logging-logback/logback-spring.xml ./src/main/resources/logback-spring.xml
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.1_8-jre@sha256:f6b092537e68d9836e86f676344e94102f2be325bbc652133cd9ef85b27d3ea9

WORKDIR /usr/src/app/

COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar
# we ignore the version (which is from upstream) and use the latest version of the grafana distribution
ADD --chmod=644 https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar /usr/src/app/opentelemetry-javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/usr/src/app/opentelemetry-javaagent.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
