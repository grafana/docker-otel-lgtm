FROM eclipse-temurin:25.0.2_10-jdk@sha256:acab08ae09273ee938c1da6111ed60ff51ab0ab18325e4b1b81178039059f86e AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
COPY json-logging-logback/logback-spring.xml ./src/main/resources/logback-spring.xml
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.2_10-jre@sha256:43a7b50abf8679d77d6d41d52072402a18312a47b4390864046b393e2570137b

WORKDIR /usr/src/app/

COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar
# we ignore the version (which is from upstream) and use the latest version of the grafana distribution
ADD --chmod=644 https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar /usr/src/app/opentelemetry-javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/usr/src/app/opentelemetry-javaagent.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
