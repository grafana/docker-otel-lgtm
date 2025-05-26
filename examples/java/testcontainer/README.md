# Using Testcontainers

The provided code demonstrates how to use **Testcontainers** with **Grafana's LGTM stack** to
test OpenTelemetry metrics in a Java application. Here's a step-by-step explanation:

1. **Set Up the Testcontainers Environment**:

- The `@Testcontainers` annotation enables the Testcontainers extension for JUnit 5.
- The `@Container` annotation is used to define a `LgtmStackContainer` that
  runs the Grafana LGTM stack in a Docker container.

2. **Configure OpenTelemetry**:

- In the `@BeforeEach` method, system properties are set to configure the OpenTelemetry
  exporter to send metrics to the LGTM stack running in the container.

3. **Run the Application**:

- The `OtelApp` class initializes OpenTelemetry and generates a custom metric (`sold_items`)
  with attributes (e.g., `tenant`) as well as a span representing the block the code.

4. **Test Exporting Metrics and Traces**:

- The test method `testExportMetricsAndTraces` runs the application and queries the Prometheus and
  Tempo endpoints in the LGTM stack to verify that the metric (`sold_items`) and span have been
  exported successfully.
- The `Awaitility` library is used to poll the endpoints until the telemetry is found or a timeout
  occurs.

5. **Debugging with Grafana**:

- The test outputs the Grafana URL (`lgtm.getGrafanaHttpUrl()`) to the console, allowing you to
  manually inspect the
  telemetry in the Grafana UI if needed.

## Example Usage

1. Start the test using `mvn test`.
2. Check the console output for the Grafana URL.
3. Open the Grafana UI, navigate to the Explore tab, and query the metrics or traces.
4. The test will pass if the metric and span are successfully exported and found in Prometheus and
   Tempo.

This setup is useful for validating OpenTelemetry instrumentation and ensuring metrics are correctly
exported to a monitoring system.

## Alternative Approach

If you prefer declarative tests, you can use [OpenTelemetry Acceptance Tests (OATs)](https://github.com/grafana/oats),
where the test would look like this:

```yaml
docker-compose:
  files:
    - ./docker-compose.yaml
expected:
  metrics:
    - promql: 'uptime_seconds_total{}'
      value: '>= 0'
```

OATs provides support for traces, logs, profiles, and metrics.

