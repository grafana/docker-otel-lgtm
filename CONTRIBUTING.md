# Contributing

## Building locally

`dev1` is an example of a tag to test locally.

- `./build-lgtm.sh dev1` will build the docker image locally.
- `./run-lgtm.sh dev1` will run the docker image locally.

## Linting

- Markdown lint: `markdownlint -f -i container -i examples/python/venv .` (`-f` fixes simple violations, requires [markdownlint](https://github.com/DavidAnson/markdownlint#markdownlint))
- Markdown link checker: `lychee .` (requires [lychee](https://github.com/lycheeverse/lychee))
- Run all checks: `./scripts/lint.sh`

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
