# Contributing

It's recommended to use the [mise][mise] for development.

## Building locally

`dev1` is an example of a tag to test locally.

- `mise run build-lgtm dev1` will build the Docker image locally.
- `mise run lgtm dev1` will run the Docker image locally.

## Linting

This repository uses [flint][flint] for linting.
See the flint readme for detailed documentation on each linter.

```bash
mise run lint:fix   # Auto-fix all issues (recommended before committing)
mise run lint  # Check only (same command used in CI)
```

Always run `mise run lint:fix` before committing — review the changed files as auto-fixes may produce unexpected results.

## Acceptance Tests

Acceptance test cases are defined in `oats-case.yaml` files in the examples
directory and listed by the root `oats-config.yaml`. The test cases are run by
[oats].

If a test case fails (let's say `examples/nodejs`), follow these steps:

1. Build a new image: `mise run build-lgtm dev1`
2. Run `LGTM_IMAGE=grafana/otel-lgtm:dev1 oats --config oats-config.yaml --container-runtime docker examples/nodejs`
   (`oats` is automatically installed by `mise`)
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

## Submit a pull request

Effective 2026-06-22, all Grafana Labs repositories [require signed commits][signed-commits].
To learn more about Git commit verification, refer to [About commit signature verification][signing-commits]
and [Checking your commit signature verification status][verifying-commits].

> [!NOTE]
> Pull requests containing any unsigned commits cannot be merged until all commits are signed.

[architecture]: https://docs.google.com/presentation/d/1txMBBitezscvtJIXRHNSXnCekjMRM29GmHufUSI0NRw/edit?slide=id.g26040f0db78_0_0#slide=id.g26040f0db78_0_0
[flint]: https://github.com/grafana/flint
[mise]: https://github.com/jdx/mise
[oats]: https://github.com/grafana/oats
[signed-commits]: https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches#require-signed-commits
[signing-commits]: https://docs.github.com/authentication/managing-commit-signature-verification/about-commit-signature-verification
[verifying-commits]: https://docs.github.com/authentication/troubleshooting-commit-signature-verification/checking-your-commit-and-tag-signature-verification-status
