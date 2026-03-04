# Releasing

> [!IMPORTANT]
> Releases are [immutable][immutable-releases] and cannot be changed or their associated tag
> deleted once published.
>
> However, the description can still be edited to fix any mistakes or omissions after publishing.

## Scheduled Releases

Releases are automatically published on a weekly basis via a
[scheduled GitHub Actions workflow][scheduled-release]. The workflow runs every Friday at 09:00 UTC
and will publish a new release if any changes have been made in the [`docker/` directory][docker]
since the [latest release][latest-release].

The version will be auto-incremented to the next minor or patch version based on the changes to
the installed components in the container image, if any.

## Manual Releases

1. Open the [Publish Release workflow][publish-release]
2. Click on the **Run workflow** button
3. If required, enter a specific version number (e.g. `x.y.z`) in the version field. If left
   blank, the version will be auto-incremented to the next minor or patch version based on the
   changes to the installed components in the container image since the [latest release][latest-release].
4. Wait for the workflow to complete successfully.
5. Click the link in the workflow run summary to the untagged release created by the workflow.
6. Click the edit button (pencil icon) at the top right of the release notes.
7. Verify that the release notes are correct. Make any manual adjustments if necessary.
8. Click on **Publish release**.

<!-- editorconfig-checker-disable -->
<!-- markdownlint-disable MD013 -->

[docker]: ./docker
[immutable-releases]: https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/immutable-releases
[latest-release]: https://github.com/grafana/docker-otel-lgtm/releases/latest
[publish-release]: https://github.com/grafana/docker-otel-lgtm/actions/workflows/publish-release.yml
[scheduled-release]: https://github.com/grafana/docker-otel-lgtm/blob/main/.github/workflows/scheduled-release.yml
