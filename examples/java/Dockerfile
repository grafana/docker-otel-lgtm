FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.22.0@sha256:df7cae821770cadb6dbe7e36681008c8e9dff71bc5f5c8deb0d8422b541592c5 AS agent

FROM eclipse-temurin:25.0.2_10-jdk@sha256:acab08ae09273ee938c1da6111ed60ff51ab0ab18325e4b1b81178039059f86e AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.2_10-jre@sha256:0a9c973778b03b88f39ccae4f8cc26022d84a3237a818cb98770369eb6c5daf9

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
