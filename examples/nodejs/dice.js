const { trace, metrics } = require('@opentelemetry/api')
const { Logger } = require('./logger')

const tracer = trace.getTracer('dice-lib')
const meter = metrics.getMeter('dice-lib')

const counter = meter.createCounter('dice-lib.rolls.counter')

const logger = new Logger('dice-lib')

function rollOnce(i, min, max) {
  return tracer.startActiveSpan(`rollOnce:${i}`, (span) => {
    counter.add(1)
    logger.log(`Rolling a single die between ${min} and ${max}`)
    const result = Math.floor(Math.random() * (max - min + 1) + min)

    // Add an attribute to the span
    span.setAttribute('dicelib.rolled', result.toString())

    span.end()
    return result
  })
}

function rollTheDice(rolls, min, max) {
  // Create a span. A span must be closed.
  return tracer.startActiveSpan(
    'rollTheDice',
    { attributes: { 'dicelib.rolls': rolls.toString() } },
    (parentSpan) => {
      logger.log(`Rolling ${rolls} dice(s) between ${min} and ${max}`)
      const result = []
      for (let i = 0; i < rolls; i++) {
        result.push(rollOnce(i, min, max))
      }
      // Be sure to end the span!
      parentSpan.end()
      return result
    }
  )
}

module.exports = { rollTheDice }
