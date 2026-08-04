FROM ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.30.0@sha256:11f0a2dd9d5b55642b8191795a2414c87d63e3308fc203031d969e320830fa5f AS agent

FROM eclipse-temurin:25.0.3_9-jdk@sha256:201fbb8886b2d273218aa3a192f0afbf7b5ff65ee8cc6ef47f5dce2171f013ea AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.3_9-jre@sha256:c600ecc57ca2d774ac872f9e9f9293b307b3df5fb5bf425e36635d5ace91d95b

WORKDIR /usr/src/app/

COPY --from=agent --chown=cnb /javaagent.jar /app/javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/app/javaagent.jar
COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
