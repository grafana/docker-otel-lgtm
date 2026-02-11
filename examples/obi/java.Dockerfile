# Same Spring Boot app as ../java but WITHOUT the OpenTelemetry Java agent.
# OBI (eBPF Instrumentation) provides observability at the kernel level instead.

FROM eclipse-temurin:25.0.1_8-jdk AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.1_8-jre

WORKDIR /usr/src/app/

COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
