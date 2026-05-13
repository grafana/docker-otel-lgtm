# Same Spring Boot app as ../java but WITHOUT the OpenTelemetry Java agent.
# OBI (eBPF Instrumentation) provides observability at the kernel level instead.

FROM eclipse-temurin:25.0.3_9-jdk@sha256:c2b7ea21649875fb9052237ac4e3cd4ef63968a2a389a0a1b1a72a5e53e5c93f AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.3_9-jre@sha256:9c9e7c4f5f3840e5254be62ea9a7de56b2d0af23864032a8a3654bf63c31cd5b

WORKDIR /usr/src/app/

COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
