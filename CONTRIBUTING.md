# Contributing

## Building locally

`./build-lgtm.sh` will build the docker image locally.

## Linting

- Markdown lint: `markdownlint -f -i container -i examples/python/venv .` (`-f` fixes simple violations, requires [markdownlint](https://github.com/DavidAnson/markdownlint#markdownlint))
- Markdown link checker: `lychee .` (requires [lychee](https://github.com/lycheeverse/lychee))
- Run all checks: `./scripts/lint.sh`

## Acceptance Tests

Acceptance test cases are defined in `oats.yaml` files in the examples directory. The test cases are run by [oats].
The declarative YAML tests are described in <https://github.com/grafana/oats/blob/main/yaml>.

If a test case fails (lets say "examples/jdbc/spring-boot-reactive-2"), follows these steps:

1. Check out the [oats] repository
2. Go to the oats folder
3. `cd yaml`
4. Install ginkgo: `go install github.com/onsi/ginkgo/v2/ginkgo`
5. `TESTCASE_TIMEOUT=2h TESTCASE_BASE_PATH=/path/to/this/repo/examples ginkgo -v -r -focus 'jdbc-spring-boot-reactive-2'`
6. go to <http://localhost:3000> and login with admin/admin

Use `-focus 'yaml'` to run all acceptance tests.

[oats]: https://github.com/grafana/oats
