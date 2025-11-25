# Releasing

1. Open the [publish-release workflow][publish-release]
2. Click on the **Run workflow** button
3. If required, enter a specific version number (e.g. `1.2.3`) in the version field. If left
   blank, the version will be auto-incremented to the next patch version based on the
   [latest release][latest-release].
4. Wait for the workflow to complete successfully.
5. Click the link in the workflow run summary to the untagged release created by the workflow.
6. Click the edit button (pencil icon) at the top right of the release notes.
7. Verify that the release notes are correct. Make any manual adjustments if necessary.
8. Click on **Publish release**.

<!-- editorconfig-checker-disable -->
<!-- markdownlint-disable MD013 -->

[latest-release]: https://github.com/grafana/docker-otel-lgtm/releases/latest
[publish-release]: https://github.com/grafana/docker-otel-lgtm/actions/workflows/publish-release.yml
