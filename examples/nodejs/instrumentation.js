const { NodeSDK } = require("@opentelemetry/sdk-node");
const {
  getNodeAutoInstrumentations,
} = require("@opentelemetry/auto-instrumentations-node");
const { PeriodicExportingMetricReader } = require("@opentelemetry/sdk-metrics");
const {
  OTLPTraceExporter,
} = require("@opentelemetry/exporter-trace-otlp-proto");
const {
  OTLPMetricExporter,
} = require("@opentelemetry/exporter-metrics-otlp-proto");

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: "http://lgtm:4318/v1/traces",
  }),
  metricReaders: [
    new PeriodicExportingMetricReader({
      exporter: new OTLPMetricExporter({
        url: "http://lgtm:4318/v1/metrics",
      }),
      exportIntervalMillis: 5000,
    }),
  ],
  instrumentations: [
    getNodeAutoInstrumentations({
      "@opentelemetry/instrumentation-http": {
        ignoreIncomingRequestHook: (request) => {
          if (request.url === "/favicon.ico") {
            return true;
          }
          return false;
        },
      },
    }),
  ],
});

module.exports = { sdk };
