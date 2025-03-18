const { SeverityNumber } = require('@opentelemetry/api-logs')
const {
  LoggerProvider,
  BatchLogRecordProcessor
} = require('@opentelemetry/sdk-logs')
const { OTLPLogExporter } = require('@opentelemetry/exporter-logs-otlp-proto')
const { resourceFromAttributes } = require('@opentelemetry/resources')
const {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION
} = require('@opentelemetry/semantic-conventions')

class Logger {
  context

  constructor(context) {
    this.context = context

    // To start a logger, you first need to initialize the Logger provider.
    const loggerProvider = new LoggerProvider({
      resource: resourceFromAttributes({
        [ATTR_SERVICE_NAME]: process.env.OTEL_SERVICE_NAME,
        [ATTR_SERVICE_VERSION]: process.env.OTEL_SERVICE_VERSION
      })
    })
    // Add a processor to export log record
    loggerProvider.addLogRecordProcessor(
      new BatchLogRecordProcessor(new OTLPLogExporter())
    )

    this.logger = loggerProvider.getLogger('default')
  }

  log(message) {
    this.logger.emit({
      severityNumber: SeverityNumber.INFO,
      severityText: 'INFO',
      body: message,
      attributes: {
        context: this.context
      }
    })

    console.log(`[${this.context}] - ${message}`)
  }

  warn(message) {
    this.logger.emit({
      severityNumber: SeverityNumber.WARN,
      severityText: 'WARN',
      body: message,
      attributes: {
        context: this.context
      }
    })

    console.warn(`[${this.context}] - ${message}`)
  }

  error(message) {
    this.logger.emit({
      severityNumber: SeverityNumber.ERROR,
      severityText: 'ERROR',
      body: message,
      attributes: {
        context: this.context
      }
    })

    console.error(`[${this.context}] - ${message}`)
  }
}

module.exports = { Logger }
