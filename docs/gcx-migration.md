# Migration: generated MCP setup replaced by gcx guidance

The image no longer generates MCP client configuration or bootstraps credentials
for AI tools. Use the [local gcx workflow](gcx-integration.md) instead. gcx and
your agent stay on the host; neither is installed in the image.

This removes the image-specific token/configuration maintenance and gives users
one recommended troubleshooting path. It does not remove MCP from Grafana or
Tempo as products.

## Removed image behavior

- Creation/lookup of the `ai-tools` Grafana service account and creation/rotation
  of its `ai-tools-token` token.
- Writing `/tmp/grafana-sa-token`, `/etc/lgtm/mcp.json`, and
  `/etc/lgtm/claude-mcp-setup.sh`.
- MCP setup commands and status messages in container startup output.

The bootstrap-only overrides `GRAFANA_URL`, `GRAFANA_PUBLIC_URL`, `TEMPO_URL`,
`LGTM_CONFIG_DIR`, and `GRAFANA_SA_TOKEN_FILE` no longer configure any image
behavior. The launch scripts no longer pass `CONTAINER_RUNTIME` into the image
for generated setup commands; Docker/Podman runtime selection still works.
This does not change similarly named environment variables in external tools.

If your automation reads the generated files, update it before upgrading. The
replacement guide explains how to configure gcx directly against Grafana; it
does not depend on those files or on the bootstrap-managed token.

## Existing credentials and client configuration

Upgrading does **not** delete existing Grafana service accounts, revoke tokens,
edit your host MCP client configuration, or remove user-mounted copies of the
old generated files. Their presence is not evidence that the new image manages
or refreshes them.

After moving to gcx, review your old client registrations and credential consumers.
Remove registrations/files or revoke credentials only when you know they are no
longer used. A token used by another workflow must not be revoked merely because
this image stopped creating it. Configure read-only gcx access where practical;
do not copy credentials into chat, release reports, or committed files.

## Preserved functionality

- `TEMPO_EXTRA_ARGS` and other backend argument passthrough remain supported.
  Independently configured Tempo MCP endpoints are not disabled by this change.
- `OTEL_COLLECTOR_DEBUG_EXPORTER=true` remains available. See the gcx guide's
  [Collector receipt evidence](gcx-integration.md#optional-collector-receipt-evidence)
  for logging options, payload sensitivity, and restoration.
- Component ports, readiness, shutdown handling, and ordinary LGTM use remain
  independent of gcx or an agent.

## Release-note summary

Breaking change: the image no longer creates AI-tool service-account tokens or
generates MCP client files. Configure host-side gcx using the
[gcx workflow](gcx-integration.md). Existing credentials and user-mounted files
are not deleted or revoked; review their consumers before removing them.
