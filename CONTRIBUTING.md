# Contributing

It's recommended to use the [mise](https://mise.jdx.dev/) for development.

## Building locally

`dev1` is an example of a tag to test locally.

- `mise run build-lgtm dev1` will build the docker image locally.
- `mise run lgtm dev1` will run the docker image locally.

## Linting

- Markdown lint: `mise run lint-markdown`
- Markdown link checker: `mise run lint-links`
- Run all checks: `mise run lint-all`

## Acceptance Tests

Acceptance test cases are defined in `oats.yaml` files in the examples directory. The test cases are run by [oats].

If a test case fails (lets say "examples/jdbc/spring-boot-reactive-2"), follows these steps:

1. Check out the [oats] repository
2. Go to the oats folder
3. `cd yaml`
4. Install ginkgo: `go install github.com/onsi/ginkgo/v2/ginkgo`
5. `TESTCASE_TIMEOUT=2h TESTCASE_BASE_PATH=/path/to/this/repo/examples ginkgo -v -r` (or the sub-directory you're debugging)
6. go to <http://localhost:3000>

[oats]: https://github.com/grafana/oats
