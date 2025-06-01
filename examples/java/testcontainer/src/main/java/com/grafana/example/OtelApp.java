package com.grafana.example;

import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.incubator.trace.ExtendedTracer;
import io.opentelemetry.api.logs.Logger;
import io.opentelemetry.api.metrics.LongCounter;
import io.opentelemetry.sdk.autoconfigure.AutoConfiguredOpenTelemetrySdk;

public class OtelApp {

  private final ExtendedTracer tracer;
  private final LongCounter counter;
  private final Logger logger;

  public static void main(String[] args) {
    new OtelApp().run();
  }

  public OtelApp() {
    var openTelemetry = AutoConfiguredOpenTelemetrySdk.initialize().getOpenTelemetrySdk();
    var meter = openTelemetry.getMeter("my-app");
    tracer = (ExtendedTracer) openTelemetry.tracerBuilder("my-app").build();
    counter = meter.counterBuilder("sold_items").build();
    logger = openTelemetry.getSdkLoggerProvider().loggerBuilder("my-app").build();
  }

  public void run() {
    Attributes attributes = Attributes.of(AttributeKey.stringKey("tenant"), "tenant1");
    tracer
        .spanBuilder("sell_item")
        .setAllAttributes(attributes)
        .startAndRun(() -> counter.add(42, attributes));

    logger
        .logRecordBuilder()
        .setBody("Test log!")
        .setAttribute(AttributeKey.stringKey("job"), "test-job")
        .emit();
  }
}
