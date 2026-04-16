FROM eclipse-temurin:25.0.2_10-jdk@sha256:c7cf8f103714da175842713f705e2a70551daa74f7b5cb47f40059553e6b9cde AS builder

WORKDIR /usr/src/app/

COPY ./mvnw pom.xml ./
COPY ./.mvn ./.mvn
COPY ./src ./src
COPY json-logging-ecs/logback-spring.xml ./src/main/resources/logback-spring.xml
RUN sed -i '/<dependencies>/a <dependency><groupId>co.elastic.logging</groupId><artifactId>logback-ecs-encoder</artifactId><version>1.6.0</version></dependency>' pom.xml
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests

FROM eclipse-temurin:25.0.2_10-jre@sha256:5da0c1d73846ea62dd635a7ee06aa3f1d3c0ebeed1aeca61fd57a5617fefd4eb

WORKDIR /usr/src/app/

COPY --from=builder /usr/src/app/target/rolldice.jar ./app.jar
# we ignore the version (which is from upstream) and use the latest version of the grafana distribution
ADD --chmod=644 https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar /usr/src/app/opentelemetry-javaagent.jar
ENV JAVA_TOOL_OPTIONS=-javaagent:/usr/src/app/opentelemetry-javaagent.jar

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "./app.jar" ]
