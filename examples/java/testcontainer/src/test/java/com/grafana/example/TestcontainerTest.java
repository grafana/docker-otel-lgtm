package com.grafana.example;

import static org.awaitility.Awaitility.await;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.testcontainers.grafana.LgtmStackContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@Testcontainers
public class TestcontainerTest {

  @Container private final LgtmStackContainer lgtm = new LgtmStackContainer("grafana/otel-lgtm");

  @BeforeEach
  void setUp() {
    System.setProperty("otel.exporter.otlp.endpoint", lgtm.getOtlpHttpUrl());
    System.setProperty("otel.exporter.otlp.protocol", "http/protobuf");
    System.setProperty("otel.resource.attributes", "service.name=otel-java-test");
    System.setProperty("otel.metric.export.interval", "1s");
    System.setProperty("otel.bsp.schedule.delay", "500ms");
  }

  @Test
  void testExportMetricsAndTraces() throws InterruptedException {
    // How to debug:
    // 1. Run the test with a really long timeout (update the awaitility argument)
    // 2. Go to the Grafana UI
    // 3. Open the Explore tab
    // 4. Select the Prometheus data source
    // 5. Find your metric by name or attribute (e.g. "tenant1")
    // 6. Click on the metric to see the details
    // 7. Copy the query and paste it into the test
    System.out.println("Grafana URL to debug telemetry: " + lgtm.getGrafanaHttpUrl());
    var app = new OtelApp();
    app.run();

    HttpClient client = HttpClient.newHttpClient();
    String query =
        URLEncoder.encode(
            "sold_items_total{job=\"otel-java-test\",service_name=\"otel-java-test\",tenant=\"tenant1\"}",
            StandardCharsets.UTF_8);
    String prometheusHttpUrl = lgtm.getPrometheusHttpUrl() + "/api/v1/query?query=" + query;

    HttpRequest request = HttpRequest.newBuilder().uri(URI.create(prometheusHttpUrl)).build();

    await()
        .atMost(Duration.ofSeconds(10))
        .until(
            () -> {
              HttpResponse<String> response =
                  client.send(request, HttpResponse.BodyHandlers.ofString());
              String body = response.body();
              return response.statusCode() == 200 && body.contains("sold_items");
            });

    HttpRequest traceRequest =
        HttpRequest.newBuilder()
            .uri(URI.create(String.format("%s/api/search", lgtm.getTempoUrl())))
            .build();

    await()
        .atMost(Duration.ofSeconds(10))
        .until(
            () -> {
              HttpResponse<String> response =
                  client.send(traceRequest, HttpResponse.BodyHandlers.ofString());
              String body = response.body();
              return response.statusCode() == 200 && body.contains("otel-java-test");
            });
  }
}
