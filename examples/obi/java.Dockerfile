# Same Spring Boot app as ../java but WITHOUT the OpenTelemetry Java agent.
# OBI (eBPF Instrumentation) provides observability at the kernel level instead.

FROM eclipse-temurin:25.0.5.1_2-jdk@sha256:ce2ef9d2d67a68de5e196d4de9d743327c44a10b57fe02ec39f572c652cacfd3 AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.5.1_2-jre@sha256:4ed132f6832e9804b123e89a849a7b4502756ae64a4ee08ebab939d9d5d0a9fa

WORKDIR /usr/src/app/

COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
