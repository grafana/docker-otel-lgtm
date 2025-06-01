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

    var requestConfigs = new RequestConfig[] {
      new RequestConfig(
        lgtm.getPrometheusHttpUrl() + "/api/v1/query",
          "sold_items_total{job=\"otel-java-test\",service_name=\"otel-java-test\",tenant=\"tenant1\"}",
        "sold_items"),
      new RequestConfig(
        lgtm.getTempoUrl() + "/api/search",
        null,
        "otel-java-test"),
      new RequestConfig(
        lgtm.getLokiUrl() + "/loki/api/v1/query_range",
        "{service_name=\"otel-java-test\"}",
        "Test log!")
    };

    await()
      .atMost(Duration.ofSeconds(1000))
      .untilAsserted(() -> {
        for (RequestConfig config : requestConfigs) {
          HttpResponse<String> response = executeRequest(client, config);
          assert response.statusCode() == 200 && response.body().contains(config.expectedContent);
        }
      });

    client.close();
  }

  private HttpResponse<String> executeRequest(HttpClient client, RequestConfig config) throws Exception {
    URI uri;
    if (config.queryValue != null) {
      uri = URI.create(String.format("%s?query=%s", config.baseUrl, URLEncoder.encode(config.queryValue, StandardCharsets.UTF_8)));
    } else {
      uri = URI.create(config.baseUrl);
    }

    HttpRequest request = HttpRequest.newBuilder().uri(uri).build();
    return client.send(request, HttpResponse.BodyHandlers.ofString());
  }

  private record RequestConfig(String baseUrl, String queryValue, String expectedContent) {}
}
