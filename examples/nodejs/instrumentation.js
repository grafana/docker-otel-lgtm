const { NodeSDK } = require('@opentelemetry/sdk-node')
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node')
const { PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics')
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-proto')
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-proto')

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter(),
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter(),
    // HACK Workaround for https://github.com/open-telemetry/opentelemetry-js/issues/5550
    exportIntervalMillis: 60000,
    exportTimeoutMillis: 30000,
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-http': {
        ignoreIncomingRequestHook: (request) => {
          if (request.url === '/favicon.ico') {
            return true
          }
          return false
        }
      }
    })
  ]
})

sdk.start()
