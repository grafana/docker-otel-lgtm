# Same Spring Boot app as ../java but WITHOUT the OpenTelemetry Java agent.
# OBI (eBPF Instrumentation) provides observability at the kernel level instead.

FROM eclipse-temurin:25.0.2_10-jdk@sha256:b4a48ff72ab09c8ecfc3ae35b3f9b96750437eb436bb1d9dc5cd6e1a885f7511 AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.2_10-jre@sha256:8f94f991adb7341cb5bcb39e5d7ee4ac944af94e54f5c67e9c8567ed064f0325

WORKDIR /usr/src/app/

COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
