# Using Testcontainers

The provided code demonstrates how to use **Testcontainers** with **Grafana's LGTM stack** to test OpenTelemetry metrics in a Java application. Here's a step-by-step explanation:

1. **Set Up the Testcontainers Environment**:

   - The `@Testcontainers` annotation enables the Testcontainers extension for JUnit 5.
   - The `@Container` annotation is used to define a `LgtmStackContainer` that runs the Grafana LGTM stack in a Docker container.

2. **Configure OpenTelemetry**:

   - In the `@BeforeEach` method, system properties are set to configure the OpenTelemetry exporter to send metrics to the LGTM stack running in the container.

3. **Run the Application**:

   - The `OtelApp` class initializes OpenTelemetry and generates a custom metric (`sold_items`) with attributes (e.g., `tenant`).

4. **Test the Metrics Export**:

   - The test method `testExportMetric` runs the application and queries the Prometheus endpoint in the LGTM stack to verify that the metric (`sold_items`) has been exported successfully.
   - The `Awaitility` library is used to poll the Prometheus endpoint until the metric is found or a timeout occurs.

5. **Debugging with Grafana**:
   - The test outputs the Grafana URL (`lgtm.getGrafanaHttpUrl()`) to the console, allowing you to manually inspect the metrics in the Grafana UI.

### Example Usage

1. Start the test using `mvn test`.
2. Check the console output for the Grafana URL.
3. Open the Grafana UI, navigate to the Explore tab, and query the metrics.
4. The test will pass if the metric is successfully exported and found in Prometheus.

This setup is useful for validating OpenTelemetry instrumentation and ensuring metrics are correctly exported to a monitoring system.
