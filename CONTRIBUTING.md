# Contributing

It's recommended to use the [mise][mise] for development.

## Building locally

`dev1` is an example of a tag to test locally.

- `mise run build-lgtm dev1` will build the docker image locally.
- `mise run lgtm dev1` will run the docker image locally.

## Linting

- Markdown lint: `mise run lint-markdown`
- Markdown link checker: `mise run lint-links`
- Run all checks: `mise run lint-all`

## Acceptance Tests

Acceptance test cases are defined in `oats.yaml` files in the examples directory.
The test cases are run by [oats].

If a test case fails (let's say `examples/nodejs`), follow these steps:

1. Build a new image: `mise run build-lgtm dev1`
2. `oats -timeout 2h -lgtm-version dev1 examples/nodejs` (automatically installed by `mise`)
3. go to <http://127.0.0.1:3000>

You can run all everything together using `mise run test`.

## Architecture diagram

> [!NOTE]
> The architecture diagram is only accessible to Grafana employees.

The source code for the architecture diagram is a [Google slide][architecture].
Take a screenshot of the slide and save it as `img/overview.png`.

## OTel Collector

### Testing the combined configuration

```shell
./otelcol-contrib --config docker/otelcol-config.yaml --config docker/otelcol-export-http.yaml \
print-initial-config --feature-gates otelcol.printInitialConfig > merged.yaml
```

<!-- editorconfig-checker-disable -->
<!-- markdownlint-disable MD013 -->

[architecture]: https://docs.google.com/presentation/d/1txMBBitezscvtJIXRHNSXnCekjMRM29GmHufUSI0NRw/edit?slide=id.g26040f0db78_0_0#slide=id.g26040f0db78_0_0
[mise]: https://github.com/jdx/mise
[oats]: https://github.com/grafana/oats
